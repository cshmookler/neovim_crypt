M = {}

--- Display a given error message to the user.
--- @param message string The error message.
local error = function(message)
    vim.notify(message, vim.log.levels.ERROR)
end

--- Execute an external program and return its output and success status.
--- @param command string[] The command to execute.
--- @param stdin string|nil Data passed to stdin during program execution.
--- @return string output The data written to stdout and stderr during execution.
--- @return boolean success True if execution succeeded and false otherwise.
local call = function(command, stdin)
    --- @type string
    local output = vim.fn.system(command, stdin);

    -- Remove a trailing '\n' character (if present).
    output = output:gsub("\n$", "");

    --- @type boolean
    local success = (vim.v.shell_error == 0)

    if not success then
        error(output)
    end

    return output, success
end

TempDir = {
    path = nil,
    exists = false,
    create = function(self)
        self.path, self.exists = call({ "mktemp", "--directory" })
        return self
    end,
    destroy = function(self)
        if self.path ~= nil then
            call({ "rm", "-r", self.path })
        end
    end,
}

--- Get the path to the current buffer if it exists on the filesystem.
--- @param bufnr integer The buffer number to get the path to (0 = current buffer).
--- @return string|nil file The path to the current buffer on the filesystem or nil if it does not exist.
M.get_buffer_path = function(bufnr)
    -- Get the name of the current buffer using the Neovim API.
    --- @type string
    local name = vim.api.nvim_buf_get_name(bufnr);

    -- Verify that the buffer name is a file path and not "term://" or "".
    if vim.fn.filereadable(name) == 0 then
        error("This file must be written to the filesystem to be encrypted.")
        return nil
    end

    return name
end

--- Get a password from the user.
--- @return string|nil password The password provided by the user or nil if nothing was given.
M.get_password = function()
    -- Prompt the user to enter their password.
    --- @type string
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
M.encrypt = function(file, password)
    -- Extract the data from the given file, encrypt it with AES-256, and overwrite the original file with the encrypted data.
    -- The password is given through stdin so other programs cannot see it.

    -- GPG cannot overwrite the input file, so a temporary output file must be created.
    -- This output file cannot already exist and must be created by GPG.
    -- To ensure that the temporary file does not exist and does not conflict with any other temporary files, create a temporary directory and allow GPG to write output to that directory.
    local temp_dir = TempDir:create()
    if not temp_dir.exists then
        return nil
    end

    --- @type string
    local temp_file = temp_dir.path .. "/tmp"

    --- @type boolean
    local success
    _, success = call(
        { "gpg", "--batch", "--symmetric", "--cipher-algo", "AES256", "--no-symkey-cache", "--output", temp_file,
            "--passphrase-fd", "0", file },
        password)
    if not success then
        temp_dir:destroy()
        return nil
    end

    _, success = call({ "cp", temp_file, file })
    if not success then
        temp_dir:destroy()
        return nil
    end

    temp_dir:destroy()

    vim.cmd("edit!")
end

--- Decrypt a given file with a given password.
--- @param file string The path to the file to decrypt.
--- @param password string The password to decrypt the file with.
M.decrypt = function(file, password)
    -- Extract the data from the given file, decrypt it with AES-256, and overwrite the original file with the decrypted data.
    -- The password is given through stdin so other programs cannot see it.

    -- GPG cannot overwrite the input file, so a temporary output file must be created.
    -- This output file cannot already exist and must be created by GPG.
    -- To ensure that the temporary file does not exist and does not conflict with any other temporary files, create a temporary directory and allow GPG to write output to that directory.
    local temp_dir = TempDir:create()
    if not temp_dir.exists then
        return nil
    end

    --- @type string
    local temp_file = temp_dir.path .. "/tmp"

    --- @type boolean
    local success
    _, success = call(
        { "gpg", "--batch", "--decrypt", "--output", temp_file, "--passphrase-fd", "0", file },
        password)
    if not success then
        temp_dir:destroy()
        return nil
    end

    _, success = call({ "mv", "--force", temp_file, file })
    if not success then
        temp_dir:destroy()
        return nil
    end

    temp_dir:destroy()

    vim.cmd("edit!")
end

return M
