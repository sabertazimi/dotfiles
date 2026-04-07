-- Keymaps are automatically loaded on the `VeryLazy` event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local wk = require("which-key")

local spell_lang = "en"
local spell_file = vim.fn.stdpath("config") .. "/spell/" .. spell_lang .. ".utf-8.add"

wk.add({
  { "<leader>|", "<Nop>", hidden = true },
  { "<leader>\\", "<C-W>v", desc = "Split Window Right", remap = true },
  {
    "<leader>um",
    function()
      vim.cmd("mkspell! " .. spell_file)
      vim.notify("Spell dictionary rebuilt: " .. spell_file, vim.log.levels.INFO)
    end,
    desc = "Rebuild Spell Dictionary",
    icon = "󰓫 ",
  },
  {
    "<C-P>",
    function()
      Snacks.picker.commands()
    end,
    desc = "Commands",
    icon = "⌘ ",
  },
  {
    "<C-`>",
    function()
      local cwd = LazyVim.root()
      local terminal = vim.b.snacks_terminal
      if vim.bo.filetype == "snacks_terminal" and type(terminal) == "table" and terminal.cwd and terminal.cwd ~= "" then
        cwd = terminal.cwd
      end
      Snacks.terminal(nil, { cwd = cwd })
    end,
    desc = "Terminal (Root Dir)",
    icon = " ",
    mode = { "n", "t" },
  },
  { "<C-/>", "gcc", desc = "Toggle Comment Line", mode = "n", remap = true },
  { "<C-/>", "gc", desc = "Toggle Comment", mode = "v", remap = true },
  { "<C-_>", "gcc", mode = "n", hidden = true, remap = true },
  { "<C-_>", "gc", mode = "v", hidden = true, remap = true },
  { "<C-C>", "<C-[>", desc = "Exit Insert Mode (Trigger Events)", mode = "i" },
})
