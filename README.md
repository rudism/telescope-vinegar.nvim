# telescope-vinegar.nvim

A modified version of [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)'s built-in file browser with behavior inspired by [vim-vinegar](https://github.com/tpope/vim-vinegar) and [vim-filebeagle](https://github.com/jeetsukumaran/vim-filebeagle).

## Archived

After using this for a while I've decided that Telescope is the wrong tool for this. I'm just sticking with `netrw`.

## Usage

File browser opens in the current buffer's directory in normal mode by default.

- `-` goes up a level to the parent directory
- `/` enters insert mode to search files
- `+` prompts for a new file name to create
- `h` toggles whether hidden files are displayed or not

## Installation

Install with packer (or similar equivalent package manager):

```lua
use 'rudism/telescope-vinegar.nvim'
```

Bind this to a key (I recommend `-`) and execute it to open the file browser in the current file's directory:

```lua
require('telescope').extensions.vinegar.file_browser()
```
