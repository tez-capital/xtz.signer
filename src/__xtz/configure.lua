-- protect generated binaries as they may contain sensitive data
local binaries = fs.read_dir("__bin_generated", { return_full_paths = true }) --[=[@as string[]]=]
if #binaries > 0 then
    require "__xtz.base_utils".setup_file_ownership() -- ensure correct ownership first

    for _, bin_path in ipairs(binaries) do
        fs.chmod(bin_path, "r-x------", { recurse = true }) -- set to readonly + execute
    end
end

-- create data directory
local ok, err = fs.mkdirp("data")
ami_assert(ok, "failed to create data directory - " .. tostring(err))

-- configure services
local service_manager = require "__xtz.service-manager"
local services = require "__xtz.services"
service_manager.remove_services(services.cleanup_names) -- cleanup past install
service_manager.install_services(services.active)
log_success(am.app.get("id") .. " services configured")

-- prism
local PRISM = am.app.get_configuration("PRISM")
if PRISM then require "__xtz.prism.setup" end

-- adjust data directory permissions
require "__xtz.base_utils".setup_file_ownership()
