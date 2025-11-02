
# External dependencies
- [ripgrep]()


# Installation


- [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    "fvalenza/vaultview",
    dependencies = { "ColinKennedy/mega.cmdparse", "ColinKennedy/mega.logging", "folke/snacks.nvim" },
    -- TODO: (you) - Make sure your first release matches v1.0.0 so it auto-releases!
    version = "v1.*",
}
```

# Configuration


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
                    subfolder = "vault/0-dailynotes", -- optional subfolder inside vault to limit the scope of the parser
                    pattern = "yyyy-mm-dd", -- only the filename, without extension -- TODO: support regex
					-- show_empty_months = false, -- TODO: not implemented yet
				},
				{
					name = "mocBoard",
					parser = "moc",
					viewlayout = "columns",
                    subfolder = "vault/1-MOCs",
                    pattern = "*", -- only the filename, without extension -- TODO: support regex
					file_title = "strip-moc", -- TODO: could be "date" or "basename" or "strip-moc". Currently the moc parser always strips because for MY needs it's prettier
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


# Roadmap


# Known Issues
- [ ] When opening a file associated to an entry with <CR>, and when quitting it to return to main window of the vaultview ("q"), it comes back to the first board instead of the previsouly active one
- [ ] Action to "center cursor/focus" on viewlayoutcarousel to fix
