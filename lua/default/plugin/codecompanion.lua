-- Intallation {{{
local specs = require "specs"

vim.pack.add {
    specs["which-key.nvim"],
    specs["plenary.nvim"],
    specs["mcphub.nvim"],
    specs["VectorCode"],
    specs["codecompanion-history.nvim"],
    specs["codecompanion.nvim"],
}
-- }}}

-- Setup {{{
vim.g.codecompanion_current_model = "gpt-4.1"

require("codecompanion").setup {
    memory = {
        default = {
            description = "Default Memory",
            files = {
                "~/.rules/core.md",
                -- "~/.rules/commit-message.md",
                -- "~/.rules/code-review.md",
                -- "~/.rules/doc-docstring-comment.md",
                ".rules",
                ".github/copilot-instructions.md",
            },
            is_default = true,
        },
        ["Code Review"] = {
            description = "Code Review Memory",
            files = {
                "~/.rules/code-review.md",
            },
        },
        opts = {
            chat = {
                enabled = true,
            },
        },
    },
    display = {
        chat = {
            show_settings = false,
        },
    },
    extensions = {
        history = {
            enabled = true,
            opts = {
                -- Keymap to open history from chat buffer (default: gh)
                keymap = "gh",
                -- Automatically generate titles for new chats
                auto_generate_title = true,
                ---On exiting and entering neovim, loads the last chat on opening chat
                continue_last_chat = false,
                ---When chat is cleared with `gx` delete the chat from history
                delete_on_clearing_chat = false,
                -- Picker interface ("telescope" or "snacks" or "default")
                picker = "snacks",
                ---Enable detailed logging for history extension
                enable_logging = false,
                ---Directory path to save the chats
                dir_to_save = vim.fn.stdpath "data" .. "/codecompanion-history",
                -- Save all chats by default
                auto_save = true,
                -- Keymap to save the current chat manually
                save_chat_keymap = "sc",
            },
        },
        vectorcode = {
            opts = {
                prompt_library = {
                    --           ["Diff code review"] = {
                    --               strategy = "chat",
                    --               description = "Perform a code review",
                    --               opts = {
                    --                   auto_submit = false,
                    --                   user_prompt = false,
                    --               },
                    --               prompts = {
                    --                   {
                    --                       role = "user",
                    --                       content = function()
                    --                           local target_branch =
                    --                               vim.fn.input("Target branch for merge base diff (default: main): ", "main")
                    --
                    --                           return string.format(
                    --                               [[
                    -- You are a senior software engineer performing a code review. Analyze the following code changes.
                    --  Identify any potential bugs, performance issues, security vulnerabilities, or areas that could be refactored for better readability or maintainability.
                    --  Explain your reasoning clearly and provide specific suggestions for improvement.
                    --  Consider edge cases, error handling, and adherence to best practices and coding standards.
                    --  Here are the code changes:
                    --  ```
                    --   %s
                    --  ```
                    --  ]],
                    --                               vim.fn.system("git diff --merge-base " .. target_branch)
                    --                           )
                    --                       end,
                    --                   },
                    --               },
                    --           },
                },
                tool_group = {
                    -- this will register a tool group called `@vectorcode_toolbox` that contains all 3 tools
                    enabled = true,
                    -- a list of extra tools that you want to include in `@vectorcode_toolbox`.
                    -- if you use @vectorcode_vectorise, it'll be very handy to include
                    -- `file_search` here.
                    extras = {},
                    collapse = false, -- whether the individual tools should be shown in the chat
                },
                tool_opts = {
                    ["*"] = {},
                    ls = {},
                    vectorise = {},
                    query = {
                        max_num = { chunk = -1, document = -1 },
                        default_num = { chunk = 50, document = 10 },
                        include_stderr = false,
                        use_lsp = false,
                        no_duplicate = true,
                        chunk_mode = false,
                        summarise = {
                            system_prompt = "",
                            enabled = false,
                            adapter = "copilot",
                            query_augmented = true,
                        },
                    },
                    files_ls = {},
                    files_rm = {},
                },
            },
        },
    },
    strategies = {
        chat = {
            adapter = {
                -- name = "copilot",
                name = "llama.cpp",
                model = vim.g.codecompanion_current_model,
            },
        },
        inline = {
            adapter = "llama.cpp",
            model = vim.g.codecompanion_current_model,
        },
        cmd = {
            adapter = "llama.cpp",
            model = vim.g.codecompanion_current_model,
        },
    },
    adapters = {
        http = {
            ["llama.cpp"] = function()
                return require("codecompanion.adapters").extend("openai_compatible", {
                    env = {
                        url = "http://127.0.0.1:8080",
                        api_key = os.getenv "LLAMA_API_KEY", -- Set LLAMA_API_KEY in your environment
                        chat_url = "/v1/chat/completions",
                    },
                    handlers = {
                        form_messages = function(self, messages)
                            local system_content = {}
                            local other_messages = {}
                            -- 1. Separate system messages from everything else
                            for _, msg in ipairs(messages) do
                                if msg.role == "system" then
                                    table.insert(system_content, msg.content)
                                else
                                    table.insert(other_messages, msg)
                                end
                            end
                            local final_messages = {}
                            -- 2. If there are system messages, merge them into ONE message at the top
                            if #system_content > 0 then
                                table.insert(final_messages, {
                                    role = "system",
                                    content = table.concat(system_content, "\n\n"),
                                })
                            end
                            -- 3. Append all the user/assistant messages
                            for _, msg in ipairs(other_messages) do
                                table.insert(final_messages, msg)
                            end
                            -- 4. Pass the cleaned messages to the standard OpenAI handler
                            local openai = require "codecompanion.adapters.http.openai"
                            return openai.handlers.form_messages(self, final_messages)
                        end,
                        parse_message_meta = function(self, data)
                            local extra = data.extra
                            if extra and extra.reasoning_content then
                                data.output.reasoning = { content = extra.reasoning_content }
                                if data.output.content == "" then
                                    data.output.content = nil
                                end
                            end
                            return data
                        end,
                    },
                })
            end,
            openrouter = function()
                return require("codecompanion.adapters").extend("openai_compatible", {
                    env = {
                        url = "https://openrouter.ai/api",
                        api_key = os.getenv "API_OPENROUTER",
                        chat_url = "/v1/chat/completions",
                    },
                    schema = {
                        model = {
                            default = vim.g.codecompanion_current_model or "mistralai/devstral-small-2505:free",
                            order = 1,
                            mapping = "parameters",
                            type = "enum",
                            desc = "ID of the model to use. See the model endpoint compatibility table for details on which models work with the Chat API.",
                            choices = {
                                ["o3-mini-2025-01-31"] = { opts = { can_reason = true } },
                                ["o1-2024-12-17"] = { opts = { can_reason = true } },
                                ["o1-mini-2024-09-12"] = { opts = { can_reason = true } },
                                "claude-3.5-sonnet",
                                "claude-3.7-sonnet",
                                "claude-3.7-sonnet-thought",
                                "gpt-4o-2024-08-06",
                                "gemini-2.0-flash-001",
                            },
                        },
                    },
                })
            end,
        },
    },
    prompt_library = {},
}

-- }}}

-- Setup Keybindings {{{
--
require("which-key").add {
    { "<leader>a", mode = "n", group = "CodeCompanion" },
}

vim.keymap.set("n", "<leader>ah", function()
    vim.cmd.CodeCompanionHistory()
end, { noremap = true, silent = true, desc = "Code Companion History" })

vim.keymap.set(
    { "n", "v" },
    "<leader>ak",
    "<cmd>CodeCompanionActions<cr>",
    { noremap = true, silent = true, desc = "Code Companion Actions" }
)
vim.keymap.set(
    { "n", "v" },
    "<leader>at",
    "<cmd>CodeCompanionChat Toggle<cr>",
    { noremap = true, silent = true, desc = "Toggle Code Companion Chat" }
)
vim.keymap.set(
    "v",
    "ga",
    "<cmd>CodeCompanionChat Add<cr>",
    { noremap = true, silent = true, desc = "Add Code Companion Chat" }
)

-- vim.keymap.set(
--     "n",
--     "<leader>as",
--     vim.g.codecompanion_current_model,
--     { noremap = true, silent = true, desc = "Select Model" }
-- )

-- expand 'cc' into 'CodeCompanion' in the command line.
vim.cmd [[cab cc CodeCompanion]]
-- }}}
