--- Display a given error message to the user.
--- @param message string The error message.
local error = function(message)
    vim.notify(message, vim.log.levels.ERROR)
end

--- Execute an external program and return its output and success status.
--- @param command string[] The command to execute.
--- @param stdin string|nil Data passed to stdin during program execution.
--- @return string stdout The data written to stdout during execution.
--- @return boolean success True if execution succeeded and false otherwise.
local call = function(command, stdin)
    --@type vim.SystemObj
    local process = vim.system(command, { stdin = stdin })

    --@type vim.SystemCompleted
    local result = process:wait()

    --@type boolean
    local success = (result.code == 0)

    if not success then
        error(result.stderr)
    end

    return result.stdout, success
end

--- Get the path to the current buffer if it exists on the filesystem.
--- @return string|nil file The path to the current buffer on the filesystem or nil if it does not exist.
local get_file = function()
    -- Get the name of the current buffer using the Neovim API.
    local name = vim.api.nvim_buf_get_name(0);

    -- Verify that the buffer name is a file path and not "term://" or "".
    if vim.fn.filereadable(name) == 0 then
        error("This file must be written to the filesystem to be encrypted.")
        return nil
    end

    return name
end

--- Get a password from the user.
--- @return string|nil password The password provided by the user or nil if nothing was given.
local get_password = function()
    -- Prompt the user to enter their password.
    local password = vim.fn.inputsecret({ prompt = "Password: " })

    if password == "" then
        error("Passwords must contain at least one character.")
        return nil
    end

    return password
end

--- Encrypt a given file with a given password.
--- @param file string The path to the file to encrypt.
--- @param password string The password to encrypt the file with.
local encrypt = function(file, password)
    -- Extract the data from the given file, encrypt it with AES-256, and overwrite the original file with the encrypted data.
    -- The password is given through stdin so other programs cannot see it.

    --@type string
    local temp_file, success = call({ "mktemp", "--quiet" })
    if not success then
        return nil
    end

    _, success = call(
        { "gpg", "--batch", "--symmetric", "--cipher-algo", "AES256", "--no-symkey-cache", "--output", temp_file,
            "--passphrase-fd", "0", file },
        password)
    if not success then
        return nil
    end

    _, success = call({ "mv", "--force", temp_file, file })
    if not success then
        return nil
    end

    _, success = call({ "rm", "--force", temp_file })
    if not success then
        return nil
    end

    vim.cmd("edit!")
end

--- Decrypt a given file with a given password.
--- @param file string The path to the file to decrypt.
--- @param password string The password to decrypt the file with.
local decrypt = function(file, password)
    -- Extract the data from the given file, decrypt it with AES-256, and overwrite the original file with the decrypted data.
    -- The password is given through stdin so other programs cannot see it.

    local temp_file, success = call({ "mktemp", "--quiet" })
    if not success then
        return nil
    end

    _, success = call(
        { "gpg", "--batch", "--decrypt", "--output", temp_file, "--passphrase-fd", "0", file },
        password)
    if not success then
        return nil
    end

    _, success = call({ "mv", "--force", temp_file, file })
    if not success then
        return nil
    end

    _, success = call({ "rm", "--force", temp_file })
    if not success then
        return nil
    end

    vim.cmd("edit!")
end

vim.api.nvim_create_user_command("Encrypt", function()
    local file = get_file()
    if file == nil then
        return
    end

    local password = get_password()
    if password == nil then
        return
    end

    encrypt(file, password)
end, {})

vim.api.nvim_create_user_command("Decrypt", function()
    local file = get_file()
    if file == nil then
        return
    end

    local password = get_password()
    if password == nil then
        return
    end

    decrypt(file, password)
end, {})
