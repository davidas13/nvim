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


# Title: Debug Python, Rust, Zig, C/C++
# Category: debugging
# Tags: dap, debug, workflow
---

```markdown
Set a breakpoint with `<leader>Dt` (plain) or `:DebugBreakpoint` (with a
condition) or `:DebugLogPoint` (prints a message, never stops). Start a
session with `:DapContinue`: it picks a configuration for the current
filetype, or `:DapNew` and Tab-complete the configuration name. The
executable path is asked for, never guessed, nothing is built for you.

Step with `<leader>DO` (over), `<leader>Di` (into), `<leader>Do` (out),
resume with `<leader>Dc`, rerun with `<leader>Dl`, stop with `<leader>DT`.
Run the current file with arguments via `<leader>Da`. Open or close the
debug view (watches, scopes, stack, breakpoints, REPL) with `:DebugView`.

Per language: Python runs `${file}` with the venv from `VIRTUAL_ENV`, no
build step, through the mason entry `Python: Launch file`. Rust, Zig, C,
and C++ prompt for the binary; the default
starts at `target/debug/` for Rust, `zig-out/bin/` for Zig, and the
project root for C/C++. Build with symbols first: `cargo build` after
setting `debug = true` or `-g` in the profile, `zig build
-Doptimize=Debug`, and `-g` for C/C++ compilers.

Share a configuration with other editors by writing `.vscode/launch.json`
in the project root; Neovim reads it on demand when a session starts, no
reload step needed.

JavaScript, TypeScript, JSX, TSX, and Svelte debug through the js-debug
adapter: those buffers offer `pwa-node` entries (`Launch file` runs the
current file, `Launch entry` prompts for the entry point) and `pwa-chrome`
entries that launch a URL or attach to Chrome on port 9222. The `pwa-node`
entries run node by default; in a bun or deno project set
`runtimeExecutable` in `.vscode/launch.json` before starting the session.

Go is wired through delve: a go buffer offers debug of the package, debug
of the folder, and debug of the test under the cursor.
```

***
