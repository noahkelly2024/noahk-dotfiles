local C = require("shared-colors")

vim.cmd("highlight Normal guibg=" .. C.bg .. " guifg=" .. C.fg)
vim.cmd("highlight CursorLine guibg=" .. C.selbg)
vim.cmd("highlight Visual guibg=" .. C.selbg .. " guifg=" .. C.selfg)
vim.cmd("highlight Pmenu guibg=" .. C.bg .. " guifg=" .. C.fg)
vim.cmd("highlight PmenuSel guibg=" .. C.teal .. " guifg=" .. C.bg)
vim.cmd("highlight LineNr guifg=" .. C.grey)
vim.cmd("highlight CursorLineNr guifg=" .. C.blue)

-- Optional plugin highlight examples
vim.cmd("highlight StatusLine guibg=" .. C.bg .. " guifg=" .. C.accent)
