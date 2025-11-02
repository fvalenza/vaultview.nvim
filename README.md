# A Neovim Plugin Template


# Installation

<!-- TODO: (you) - Adjust and add your dependencies as needed here -->

- [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    "fvalenza/vaultview",
    dependencies = { "ColinKennedy/mega.cmdparse", "ColinKennedy/mega.logging" },
    -- TODO: (you) - Make sure your first release matches v1.0.0 so it auto-releases!
    version = "v1.*",
}
```

# Configuration

(These are default values)

<!-- TODO: (you) - Remove / Add / Adjust your configuration here -->

- [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
	"fvalenza/vaultview",
	dependencies = { "ColinKennedy/mega.cmdparse", "ColinKennedy/mega.logging", "folke/snacks.nvim" },

	keys = {
		{ "<leader>vv", "<Plug>(Vaultview)", mode = "n", desc = "Open VaultView" },
	},

	config = function()
		vim.g.vaultview_configuration = {
			vault = {
				path = "/path/to/your/vault", -- full path to your vault
				name = "myVault",
			},
			boards = {
				{
					name = "dailyBoard", -- name of the board as printed in the top of UI
					parser = "daily", -- parser used to retrieve information to display in the view -> currently supported parsers: "daily", "moc"
					viewlayout = "carousel", -- how information is displayed in the view -> currently supported layouts: "carousel", "columns"
					daily_notes_folder = "vault/0-dailynotes", -- folder inside vault where daily notes are stored. Daily_parser currently do NOT parse recursively so all dailynotes should be in the same dir
				},
				{
					name = "mocBoard",
					parser = "moc",
					viewlayout = "columns",
					pattern = "vault/1-MOCs/*.md", -- could be "subdir/*" or "yyyy-mm-dd.md" or "moc-*.md"
				},
			},
		}
	end,
}

```

# Commands

<!-- plugin/vaultview.lua for details. -->

```vim
" A typical subcommand
:Vaultview open
:Vaultview close
:Vaultview refresh
```


# Other Plugins

This template is full of various features. But if your plugin is only meant to
be a simple plugin and you don't want the bells and whistles that this template
provides, consider instead using
[nvim-vaultview](https://github.com/ellisonleao/nvim-plugin-template)
