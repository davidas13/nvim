# Your personal Neovim tips


# Title: Rerun last substitution command
# Category: substitution
# Tags: command, substitution
---

```markdown
- `:&` (in Normal mode): Repeats the last substitute command on the current line, but does not remember the flags (like g for global or c for confirm).
- `:&&` (in Command mode): Repeats the last substitute command on the current line and re-uses the flags from the previous command.
- `g&` (in Normal mode): Repeats the last substitute command on all lines in the file, using the same flags.
- `@:` (in Normal mode): Repeats the last executed Ex command (including complex ones like :%s/old/new/g).
- `:` followed by Up Arrow: Opens the command-line history where you can press Enter to run the last replace again. 
```

***


# Title:  Command Line Symbols
# Category: commandline
# Tags:  command
---


```markdown
- `%` Current file.
- `:p` Expands to the absolute path.
- `@+` The system clipboard register.
- `@a` Execute marcro 'a'.
```

***



# Title: Diff
# Category: diff
# Tags:  diff
---


```markdown
:diffupdate: Refresh the diff view.
:diffget or :dg: Get changes from the other buffer (like do).
:diffput or :dp: Put changes into the other buffer (like dp).
:diffoff: Turn off diff mode for the current window.
:diffthis: Enable diff mode for the current window (used with :windiff).
:vertical diffsplit or :vsplit | diffthis: Open a vertical split and enable diff.
```


***
