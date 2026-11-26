# Third-party notices and acknowledgements

This repository is a personal Neovim configuration. Plugins declared in
`lua/specs.lua` are downloaded by `vim.pack` during setup. No plugin source
is stored here.

## Code taken from a third party

`lua/default/plugin/snacks/picker.lua` contains the `copy_file_path`,
`search_in_directory`, and `diff` actions from Rico Berger's post
"Neovim: Extend snacks.nvim Explorer" at
https://ricoberger.de/blog/posts/neovim-extend-snacks-nvim-explorer/.
The three function bodies reproduce the post. The post has no license
statement. Berger's dotfiles repository is MIT licensed.

MIT License

Copyright (c) 2026 Rico Berger

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Behavior adapted from other projects

`lua/default/plugin/open-selection.lua` follows the selection keymaps and
seditor write-back approach of yode-nvim by Stefan Gojan. I scanned the 43
upstream Lua files for identifiers used here and found no matches, so this
implementation is separate. yode-nvim is MIT licensed.

MIT License

Copyright (c) 2021 Stefan Gojan

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

diffview.nvim and diffview-plus.nvim are GPL-3.0-or-later. The command layout
in `lua/default/plugin/diff/` follows diffview.nvim, and its DiffDirs
behavior follows diffview-plus.nvim. I scanned the 78 upstream Lua files
from diffview.nvim and found none of the identifiers used here, so the
explorer is a separate implementation.

Diffview.nvim is a tool for Neovim that adds an interface that enables
easy review of changes made in any Git revision.
Copyright (C) 2021 Sindre T. Strøm

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

Diffview.nvim is a tool for Neovim that adds an interface that enables
easy review of changes made in any Git revision.
Copyright (C) 2021 Sindre T. Strøm
Copyright (C) 2025 David Yonge-Mallo

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
