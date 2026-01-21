-- SOURCE: https://octez.tezos.com/releases
-- usage:
-- eli src/__xtz/update-sources.lua
-- eli src/__xtz/update-sources.lua latest
-- eli src/__xtz/update-sources.lua octez-v24.0

local hjson = require "hjson"
-- net is global in eli
local args = table.pack(...)

local target_version = args[1]

-- Use defaults for http options as they seem to work better
local http_options = nil

if not target_version or target_version == "latest" then
	print("Fetching latest version from RSS feed...")
	local response = net.download_string("https://octez.tezos.com/releases/feed.xml", http_options)
	if #response == 0 then
		print("Empty response for feed.xml")
		return
	end

	-- Parse <guid> ... </guid>
	for guid in response:gmatch("<guid>%s*(octez%-v[%d%.%-rc]+)%s*</guid>") do
		target_version = guid
	end

	if not target_version or target_version == "latest" then
		print("No version found in feed.xml")
		return
	end
end

print("Target version: " .. target_version)

--------------------------------------------------------------------------------
-- GitHub Fetching Helper
--------------------------------------------------------------------------------

local function fetch_github_release(repo, filter_fn)
	print("Fetching releases from " .. repo .. "...")
	local url = "https://api.github.com/repos/" .. repo .. "/releases"
	-- GitHub API might require User-Agent, eli usually handles it but be aware.
	local response = net.download_string(url, http_options)

	if #response == 0 then
		print("Empty response from " .. repo)
		return nil
	end

	local releases = hjson.parse(response)
	if not releases or #releases == 0 then
		return nil
	end

	if not filter_fn then
		return releases[1]
	end

	for _, release in ipairs(releases) do
		if filter_fn(release) then
			return release
		end
	end
	return nil
end

local function extract_asset(release, name_pattern, version_override)
	if not release or not release.assets then return nil end
	for _, asset in ipairs(release.assets) do
		if asset.name:match(name_pattern) then
			local hash = nil
			if asset.digest then
				hash = asset.digest:match("sha256:(%x+)")
			end
			return {
				url = asset.browser_download_url,
				sha256 = hash,
				version = version_override or release.tag_name
			}
		end
	end
	return nil
end

--------------------------------------------------------------------------------
-- Fetch External Releases
--------------------------------------------------------------------------------

-- 1. Prism (Latest)
local prism_release = fetch_github_release("alis-is/prism-releases")
if prism_release then
	print("Found Prism release: " .. prism_release.tag_name)
else
	print("Warning: Failed to fetch Prism release")
end

-- 2. Check-Ledger (Latest)
local check_ledger_release = fetch_github_release("tez-capital/tezos-ledger-check")
if check_ledger_release then
	print("Found Check-Ledger release: " .. check_ledger_release.tag_name)
else
	print("Warning: Failed to fetch Check-Ledger release")
end

-- 3. Tezsign (Latest)
local tezsign_release = fetch_github_release("tez-capital/tezsign")
if tezsign_release then
	print("Found Tezsign release: " .. tezsign_release.tag_name)
else
	print("Warning: Failed to fetch Tezsign release")
end

-- 4. macOS Octez
local macos_octez_release = fetch_github_release("tez-capital/tezos-macos-pipeline", function(release)
	-- Look for 'octez-vXX.Y-2' pattern typically
	-- This handles suffix like -timestamp
	if release.tag_name:sub(1, #target_version + 2) == target_version .. "-2" then
		return true
	end
	if release.tag_name == target_version then
		return true
	end
	return false
end)

if not macos_octez_release then
	print("Warning: No matching macOS release found for " .. target_version)
end
if macos_octez_release then
	print("Found macOS Octez release: " .. macos_octez_release.tag_name)
end


--------------------------------------------------------------------------------
-- Update Sources
--------------------------------------------------------------------------------

local current_sources = hjson.parse(fs.read_file("src/__xtz/sources.hjson"))
local new_sources_map = {}

local platforms = {
	["linux-x86_64"] = {
		octez_linux_arch = "x86_64",
		prism_pattern = "prism%-linux%-amd64",
		check_ledger_pattern = "tezos%-check%-ledger%-linux%-amd64",
		tezsign_pattern = "tezsign%-host%-linux%-amd64"
	},
	["linux-arm64"] = {
		octez_linux_arch = "arm64",
		prism_pattern = "prism%-linux%-arm64",
		check_ledger_pattern = "tezos%-check%-ledger%-linux%-arm64",
		tezsign_pattern = "tezsign%-host%-linux%-arm64"
	},
	["darwin-arm64"] = {
		is_mac = true,
		prism_pattern = "prism%-macos%-arm64",
		check_ledger_pattern = "tezos%-check%-ledger%-macos%-arm64",
		tezsign_pattern = "tezsign%-host%-macos%-arm64"
	}
}

for platform, config in pairs(platforms) do
	print("Updating " .. platform .. "...")
	local new_platform_sources = {}

	-- 1. Octez (client, signer)
	if config.is_mac then
		if macos_octez_release then
			local asset_ids = {
				client = "octez%-client",
				signer = "octez%-signer"
			}
			local octez_version = target_version:match("^octez%-v(.+)$") or target_version
			for key, asset_name in pairs(asset_ids) do
				local asset_data = extract_asset(macos_octez_release, "^" .. asset_name .. "$", octez_version)
				if asset_data then
					new_platform_sources[key] = asset_data
				else
					print("  Warning: Asset " .. asset_name .. " not found in release")
					if current_sources[platform] and current_sources[platform][key] then
						new_platform_sources[key] = current_sources[platform][key]
					end
				end
			end
		else
			-- Copy existing octez sources
			if current_sources[platform] then
				for k, v in pairs(current_sources[platform]) do
					if k == "client" or k == "signer" then
						new_platform_sources[k] = v
					end
				end
			end
		end
	else
		-- Linux
		local bin_arch = config.octez_linux_arch
		local sha_url = "https://octez.tezos.com/releases/" ..
			target_version .. "/binaries/" .. bin_arch .. "/sha256sums.txt"
		print("  Downloading " .. sha_url .. "...")
		local sums_content = net.download_string(sha_url, http_options)

		if #sums_content > 0 then
			print("  Found sha256sums for " .. platform)

			for line in sums_content:gmatch("[^\r\n]+") do
				local hash, filename = line:match("(%x+)%s+(.+)")
				if hash and filename then
					local key = nil
					if filename == "octez-client" then
						key = "client"
					elseif filename == "octez-signer" then
						key = "signer"
					end

					if key then
						local url = "https://octez.tezos.com/releases/" ..
							target_version .. "/binaries/" .. bin_arch .. "/" .. filename
						local octez_version = target_version:match("^octez%-v(.+)$") or target_version
						new_platform_sources[key] = {
							url = url,
							sha256 = hash,
							version = octez_version
						}
					end
				end
			end
		else
			print("  Failed to download sha256sums for " .. platform)
			if current_sources[platform] then
				for k, v in pairs(current_sources[platform]) do
					if k == "client" or k == "signer" then
						new_platform_sources[k] = v
					end
				end
			end
		end
	end

	-- 2. Prism
	if prism_release then
		local prism_data = extract_asset(prism_release, config.prism_pattern)
		if prism_data then
			new_platform_sources.prism = prism_data
		else
			print("  Warning: Prism asset matching " .. config.prism_pattern .. " not found")
			if current_sources[platform] and current_sources[platform].prism then
				new_platform_sources.prism = current_sources[platform].prism
			end
		end
	else
		if current_sources[platform] and current_sources[platform].prism then
			new_platform_sources.prism = current_sources[platform].prism
		end
	end

	-- 3. Check-Ledger
	if check_ledger_release then
		local check_ledger_data = extract_asset(check_ledger_release, config.check_ledger_pattern)
		if check_ledger_data then
			new_platform_sources["check-ledger"] = check_ledger_data
		else
			print("  Warning: Check-Ledger asset matching " .. config.check_ledger_pattern .. " not found")
			if current_sources[platform] and current_sources[platform]["check-ledger"] then
				new_platform_sources["check-ledger"] = current_sources[platform]["check-ledger"]
			end
		end
	else
		if current_sources[platform] and current_sources[platform]["check-ledger"] then
			new_platform_sources["check-ledger"] = current_sources[platform]["check-ledger"]
		end
	end

	-- 4. Tezsign
	if tezsign_release then
		local tezsign_data = extract_asset(tezsign_release, config.tezsign_pattern)
		if tezsign_data then
			new_platform_sources.tezsign = tezsign_data
		else
			print("  Warning: Tezsign asset matching " .. config.tezsign_pattern .. " not found")
			if current_sources[platform] and current_sources[platform].tezsign then
				new_platform_sources.tezsign = current_sources[platform].tezsign
			end
		end
	else
		if current_sources[platform] and current_sources[platform].tezsign then
			new_platform_sources.tezsign = current_sources[platform].tezsign
		end
	end

	new_sources_map[platform] = new_platform_sources
end

for k, v in pairs(current_sources) do
	if not new_sources_map[k] then
		new_sources_map[k] = v
	end
end

local new_content = "// SOURCE: https://octez.tezos.com/releases \n" ..
	"// macOS SOURCE: https://github.com/tez-capital/tezos-macos-pipeline/releases \n" ..
	"// PRISM SOURCE: https://github.com/alis-is/prism-releases/releases \n" ..
	"// check-ledger SOURCE: https://github.com/tez-capital/tezos-ledger-check/releases \n" ..
	"// TezSign SOURCE: https://github.com/tez-capital/tezsign/releases \n"
new_content = new_content .. hjson.stringify(new_sources_map, { separator = true, sort_keys = true })

fs.write_file("src/__xtz/sources.hjson", new_content)
