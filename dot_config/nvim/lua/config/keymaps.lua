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
      Snacks.terminal(nil, { cwd = LazyVim.root() })
    end,
    desc = "Terminal (Root Dir)",
    icon = " ",
  },
})
