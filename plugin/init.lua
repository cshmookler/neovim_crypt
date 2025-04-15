local crypt = require("crypt")

vim.api.nvim_create_user_command("Encrypt", function()
    local file = crypt.get_buffer_path(0)
    if file == nil then
        return
    end

    if crypt.buffer_is_modified(0) then
        --- @type integer
        local result = vim.fn.confirm("Are you sure you want to encrypt this file?  Unsaved changes will be lost.",
            "&Yes\n&No", 1,
            "Info")
        if result ~= 1 then
            -- Cancel encryption if anything except "Yes" was selected
            return
        end
    end

    local password = crypt.get_password()
    if password == nil then
        return
    end

    crypt.encrypt(file, password)
end, {})

vim.api.nvim_create_user_command("Decrypt", function()
    local file = crypt.get_buffer_path(0)
    if file == nil then
        return
    end

    local password = crypt.get_password()
    if password == nil then
        return
    end

    crypt.decrypt(file, password)
end, {})
