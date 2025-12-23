# Your personal Neovim tips

## Diff
```vim
:diffupdate: Refresh the diff view.
:diffget or :dg: Get changes from the other buffer (like do).
:diffput or :dp: Put changes into the other buffer (like dp).
:diffoff: Turn off diff mode for the current window.
:diffthis: Enable diff mode for the current window (used with :windiff).
:vertical diffsplit or :vsplit | diffthis: Open a vertical split and enable diff.


## Command Line Symbols

- `%` Current file.
- `:p` Expands to the absolute path.
- `@+` The system clipboard register.
- `@a` Execute marcro 'a'.
