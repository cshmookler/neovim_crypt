## **neovim_crypt**

A Neovim plugin for encrypting and decrypting files on Linux.

### Install with [Lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{ "cshmookler/neovim_crypt" },
```

### Commands

- :Encrypt
    - Encrypts all content written to the current file (unsaved content is lost!).
- :Decrypt
    - Attempts to decrypt an encrypted file.

### **TODO**

- [X] file encryption
- [X] file decryption
- [ ] Ask for confirmation if there are unsaved changes
