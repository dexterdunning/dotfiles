vim.api.nvim_set_keymap('n', '<leader>.', ':BufferNext<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>,', ':BufferPrevious<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>bc', ':BufferClose<CR>', { noremap = true, silent = true })
