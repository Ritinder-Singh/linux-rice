return {
  -- Rose Pine Moon
  {
    "rose-pine/neovim",
    name = "rose-pine",
    opts = {
      variant          = "moon",
      dark_variant     = "moon",
      dim_inactive_windows = true,
      extend_background_behind_borders = true,
      styles = {
        bold         = true,
        italic        = true,
        transparency  = true,
      },
    },
  },

  -- Set as LazyVim colorscheme
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "rose-pine-moon",
    },
  },

  -- Noice — floating command UI, notifications top-right
  {
    "folke/noice.nvim",
    opts = {
      notify = {
        enabled = true,
        view    = "notify",
      },
      views = {
        notify = {
          position = { row = 2, col = "100%" },
        },
      },
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"]                = true,
          ["cmp.entry.get_documentation"]                  = true,
        },
      },
      presets = {
        bottom_search         = false,
        command_palette       = true,
        long_message_to_split = true,
        inc_rename            = true,
      },
    },
  },
}
