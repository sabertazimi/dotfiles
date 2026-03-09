return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options = opts.options or {}
      opts.options.component_separators = ""
      opts.options.section_separators = { left = "", right = "" }
      opts.sections = opts.sections or {}

      local function apply_capsule(section)
        if not section or not section[1] then
          return
        end

        if type(section[1]) == "table" then
          section[1].separator = { left = "", right = "" }
        else
          section[1] = { section[1], separator = { left = "", right = "" } }
        end
      end

      apply_capsule(opts.sections.lualine_a)
      apply_capsule(opts.sections.lualine_z)
    end,
  },
}
