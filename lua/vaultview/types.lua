-----------------------------
---- Configuration Types ----
-----------------------------

---@class vaultview.LoggingConfig
---@field level string
---@field use_console boolean
---@field use_file boolean
---@field output_path string
---@field raw_debug_console boolean
---

---@class vaultview.Configuration
---@field logging mega.logging.SparseLoggerOptions
---@field vault table
---@field hints table
---@field selectors table
---@field boards table[]
---@field initial_board_idx? integer


----------------------------
----- Vault Data Types -----
----------------------------
---@class vaultview.EntryData
---@field dataType string
---@field title string
---@field filepath string
---@field content string[]

---@class vaultview.ListData
---@field dataType string
---@field title string
---@field items vaultview.EntryData[]

---@class vaultview.PageData
---@field dataType string
---@field title string
---@field lists vaultview.ListData[]


---@class vaultview.BoardData
---@field pages vaultview.PageData[]
---@field title string
---@field vault_key string
---@field vault_path string
---@field vault_uriRoot string

---@class vaultview.VaultData
---@field boards vaultview.BoardData[]


----------------------------
---- View Windows Types ----
----------------------------

---@alias vaultview.ViewWindowsEntry snacks.win

---@class vaultview.ViewWindowsList
---@field win snacks.win
---@field items vaultview.ViewWindowsEntry[]

---@class vaultview.ViewWindowsPage
---@field lists vaultview.ViewWindowsList[]

---@class vaultview.ViewWindows
---@field pages vaultview.ViewWindowsPage[]


----------------------------
----- View State Types -----
----------------------------

---@class vaultview.EntryState
---@field expanded boolean -- Whether the entry is expanded or collapsed
---@field show boolean -- Whether the entry is shown or hidden

---@class vaultview.listEntryPageIndex
---@field start integer Index of the first entry in this page (index referencing entry from the vaultview.ListData.items array)
---@field stop integer Index of the last entry in this page (index referencing entry from the vaultview.ListData.items array)

---@class vaultview.EntryVisbilityWindow
---@field first integer
---@field last integer
---@field length integer

---@class vaultview.ListState
---@field list_pages vaultview.listEntryPageIndex[] -- Pagination of entries within the list (to not draw out of list columns)
---@field entries_visibility vaultview.EntryVisbilityWindow
---@field expanded boolean -- Whether the list is expanded or collapsed
---@field show boolean -- Wheter the list is shown or hidden
---@field current_page integer The current entry page focused
---@field items vaultview.EntryState[] State of entries within the list

---@class vaultview.ListVisbilityWindow
---@field first integer
---@field last integer
---@field length integer

---@class vaultview.PageState
---@field lists_visibility vaultview.ListVisbilityWindow
---@field lists vaultview.ListState[]
---@field center_list_index integer Index of the center list within the page

---@class vaultview.ViewState
---@field pages vaultview.PageState[]
---@field focused table
---@field focused.page integer Index of the currently focused page
---@field focused.list integer Index of the currently focused list within the focused page
---@field focused.entry integer Index of the currently focused entry within the focused list

