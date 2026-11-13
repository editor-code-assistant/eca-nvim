local cwd = vim.fn.getcwd()

vim.opt.packpath = {}
vim.opt.runtimepath = {
  cwd,
  cwd .. "/deps/plenary.nvim",
  vim.env.VIMRUNTIME,
}
