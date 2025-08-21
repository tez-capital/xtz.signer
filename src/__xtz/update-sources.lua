-- SOURCE: https://gitlab.com/tezos/tezos/-/releases
-- eli src/__xtz/update-sources.lua https://gitlab.com/tezos/tezos/-/packages/29781101 https://github.com/tez-capital/tezos-macos-pipeline/releases/tag/octez-v22.1-2025-06-11_20-14

local hjson = require "hjson"
local args = table.pack(...)
if #args < 1 then
	print("Usage: update-sources <source-url>")
	return
end

local source = args[1]
local macos_source = args[2]

--- extract package id from url source - https://gitlab.com/tezos/tezos/-/packages/25835249
local package_id = source:match("packages/(%d+)")
if not package_id then
	print("Invalid source url")
	return
end

local response = net.download_string("https://gitlab.com/api/v4/projects/3836952/packages/" ..
	package_id .. "/package_files?per_page=1000")
local files = hjson.parse(response)

local current_sources = hjson.parse(fs.read_file("src/__xtz/sources.hjson"))
for platform, sources in pairs(current_sources) do
	local new_sources = {}
	-- extract arch from linux-x86_64
	local arch = platform:match("linux%-(.*)")
	if arch then -- linux
		for source_id, source_url in pairs(sources) do
			if source_id == "prism" or source_id == "check-ledger" then
				new_sources[source_id] = source_url
				goto CONTINUE
			end

			-- build asset id => <arch>-octez-<source_id>
			local asset_ids = { [source_id] = arch .. "-octez-" .. source_id }
			for asset_id, asset_name in pairs(asset_ids) do
				-- lookup file id
				for _, file in ipairs(files) do
					if file.file_name == asset_name then
						-- update source url
						-- https://gitlab.com/tezos/tezos/-/package_files/<id>/download
						new_sources[asset_id] = "https://gitlab.com/tezos/tezos/-/package_files/" ..
						file.id .. "/download"
						break
					end
				end
			end
			::CONTINUE::
		end
	end
	local arch = platform:match("darwin%-(.*)")
	if arch then -- macos
		for source_id, source_url in pairs(sources) do
			if source_id == "prism" or source_id == "check-ledger" then
				new_sources[source_id] = source_url
				goto CONTINUE
			end

			-- extract tag from macos_source url
			-- e.g. https://github.com/tez-capital/tezos-macos-pipeline/releases/tag/octez-v22.1-2025-06-11_20-14
			local tag = macos_source:match("/tag/([^/]+)")
			assert(tag, "Invalid macos source url")

			-- build asset id => <arch>-octez-<source_id>
			local asset_ids = { [source_id] = "octez-" .. source_id }
			for asset_id, asset_name in pairs(asset_ids) do
				-- lookup file id
				for _, file in ipairs(files) do
					-- update source url
					-- https://github.com/tez-capital/tezos-macos-pipeline/releases/download/octez-v22.0-2025-06-04_15-52/octez-dal-node
					new_sources[asset_id] = "https://github.com/tez-capital/tezos-macos-pipeline/releases/download/" ..
						tag .. "/" ..
						asset_name
				end
			end
			::CONTINUE::
		end
	end
	current_sources[platform] = new_sources
end

local new_content = "// SOURCE: " .. source .. " \n" ..
	"// macOS SOURCE: " .. macos_source .. "\n"
new_content = new_content  .. hjson.stringify(current_sources, { separator = true, sort_keys = true })

fs.write_file("src/__xtz/sources.hjson", new_content)
