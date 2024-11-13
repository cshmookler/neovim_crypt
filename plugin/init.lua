local crypt = require("crypt")

vim.api.nvim_create_user_command("Encrypt", function()
    local file = crypt.get_file()
    if file == nil then
        return
    end

    local password = crypt.get_password()
    if password == nil then
        return
    end

    crypt.encrypt(file, password)
end, {})

vim.api.nvim_create_user_command("Decrypt", function()
    local file = crypt.get_file()
    if file == nil then
        return
    end

    local password = crypt.get_password()
    if password == nil then
        return
    end

    crypt.decrypt(file, password)
end, {})
