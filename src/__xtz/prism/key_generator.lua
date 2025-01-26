--- Generate a new key for a prism
---@param path string
---@param name string
---@param CN string
---@return boolean, string?
local function generate(path, name, CN)
    local has_ca_certs = os.execute("bin/prism  validate-ca-key -path prism/keys/ca")
    if not has_ca_certs then
        log_info "valid CA keys not found, generating new ones"
        -- generate ca keys
        if not os.execute("bin/prism  generate-ca -path prism/keys/ca") then
            return false, "Failed to generate CA keys"
        end
    end

    local has_valid_key = os.execute("bin/prism  validate-prism-key -path prism/keys/" .. name)
    if not has_valid_key then
        log_info "generating prism key"
        if not os.execute("bin/prism  generate-prism-key -path prism/keys/" .. name .. " -CN " .. CN) then
            return false, "Failed to generate " .. name .. " key"
        end
    else
        log_info("valid key already exists at " .. path)
    end

    return true
end

return {
    generate = generate
}