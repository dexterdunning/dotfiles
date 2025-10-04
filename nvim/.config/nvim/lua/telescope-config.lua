local actions = require('telescope.actions')
local trouble = require('trouble.providers.telescope')

-- Performance optimizations for large repositories
require('telescope').setup {
    defaults = {
        -- Use faster native sorter
        file_sorter = require('telescope.sorters').get_fuzzy_file,
        generic_sorter = require('telescope.sorters').get_generic_fuzzy_sorter,
        
        prompt_prefix = '🔍 ',
        selection_caret = '➤ ',
        entry_prefix = '  ',
        
        -- Optimize for large repos
        file_ignore_patterns = {
            -- Version control
            '%.git/',
            '%.hg/',
            '%.svn/',
            
            -- Dependencies and build artifacts
            'node_modules/',
            '__pycache__/',
            '%.py[cod]',
            'build/',
            'dist/',
            'target/',
            '%.egg%-info/',
            '.venv/',
            'venv/',
            'env/',
            'env3/',
            
            -- Cache and temp files
            '%.cache/',
            '%.tmp/',
            'tmp/',
            '%.DS_Store',
            '%.swp',
            '%.swo',
            
            -- Large data files
            '%.csv',
            '%.json', -- Be selective with this
            '%.log',
            '%.gz',
            '%.zip',
            '%.tar',
            
            -- IDE files
            '%.idea/',
            '%.vscode/',
            '%.fleet/',
            
            -- Specific to your project
            '.pants.d/',
            '.pids',
            '.pants.workdir.file_lock',
            '.pex',
            'pants_sources.txt',
            'junit.*',
            '.tmp/.*',
            'artifacts/',
            '.ruff_cache/',
        },
        
        -- Reduce initial results for faster startup
        results_limit = 100,
        
        -- Better previewer settings
        preview = {
            treesitter = true,
            timeout = 250,
            filesize_limit = 0.1, -- 0.1 MB limit for preview
        },
        
        -- Layout optimizations
        layout_strategy = 'flex',
        layout_config = {
            width = 0.95,
            height = 0.85,
            flex = {
                flip_columns = 120,
            },
            horizontal = {
                preview_width = 0.6,
            },
            vertical = {
                preview_height = 0.4,
            },
        },
        
        -- Faster file operations
        path_display = { "truncate" },
        
        color_devicons = true,
        use_less = true,
        set_env = { ['COLORTERM'] = 'truecolor' },
        
        mappings = {
            i = {
                ["<C-x>"] = false,
                ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
                ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
                ["<C-t>"] = trouble.open_with_trouble,
                ["<C-h>"] = "which_key",
                ["<esc>"] = actions.close,
                ["<C-u>"] = false, -- Clear prompt
            },
            n = {
                ["<C-t>"] = trouble.open_with_trouble,
                ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
                ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
            },
        },
        
        -- Better file type detection
        file_previewer = require('telescope.previewers').vim_buffer_cat.new,
        grep_previewer = require('telescope.previewers').vim_buffer_vimgrep.new,
        qflist_previewer = require('telescope.previewers').vim_buffer_qflist.new,
    },
    
    pickers = {
        find_files = {
            -- Use fd/rg for faster file finding
            find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
            follow = false, -- Don't follow symlinks for performance
            hidden = false, -- Don't show hidden files by default for speed
        },
        
        live_grep = {
            additional_args = function(opts)
                return {"--hidden", "--glob", "!**/.git/*"}
            end,
            -- Only show first 1000 results to avoid freezing
            max_results = 1000,
        },
        
        grep_string = {
            additional_args = function(opts)
                return {"--hidden", "--glob", "!**/.git/*"}
            end,
            max_results = 1000,
        },
        
        git_files = {
            show_untracked = false, -- Faster for large repos
        },
        
        buffers = {
            sort_lastused = true,
            sort_mru = true,
        },
    },
    
    extensions = {
        fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
        },
    }
}

-- Load extensions
require('telescope').load_extension('fzf')
require('telescope').load_extension('live_grep_args')

local lga_actions = require('telescope-live-grep-args.actions')

-- Configure live-grep-args extension
require('telescope').setup {
    extensions = {
        live_grep_args = {
            auto_quoting = true,
            mappings = {
                i = {
                    ["<C-k>"] = lga_actions.quote_prompt(),
                    ["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
                },
            },
        },
    },
}

local M = {}

-- Original dotfiles search
M.search_dotfiles = function() 
    require("telescope.builtin").find_files({
        prompt_title = "< VimRC >",
        cwd = "$HOME/.config/nvim",
    })
end

-- Rippling-specific optimized commands
M.find_app_files = function()
    require("telescope.builtin").find_files({
        prompt_title = "< App Files >",
        cwd = "app/",
        find_command = { "rg", "--files", "--type", "py", "--glob", "!**/__pycache__/*", "--glob", "!**/*.pyc" },
    })
end

M.find_python_files = function()
    require("telescope.builtin").find_files({
        prompt_title = "< Python Files >",
        find_command = { "rg", "--files", "--type", "py", "--glob", "!**/__pycache__/*", "--glob", "!**/*.pyc" },
    })
end

M.find_js_files = function()
    require("telescope.builtin").find_files({
        prompt_title = "< JavaScript/TypeScript Files >",
        find_command = { "rg", "--files", "--type", "js", "--type", "ts", "--glob", "!**/node_modules/*" },
    })
end

M.search_in_app = function()
    require('telescope').extensions.live_grep_args.live_grep_args({
        prompt_title = "< Live Grep in App/ >",
        search_dirs = { "app/" },
        additional_args = function(opts)
            return {"--type", "py", "--glob", "!**/__pycache__/*"}
        end,
    })
end

M.search_configs = function()
    require("telescope.builtin").find_files({
        prompt_title = "< Config Files >",
        find_command = { "rg", "--files", "--glob", "*.yml", "--glob", "*.yaml", "--glob", "*.toml", "--glob", "*.json", "--max-filesize", "1M" },
    })
end

M.search_tests = function()
    require("telescope.builtin").find_files({
        prompt_title = "< Test Files >",
        find_command = { "rg", "--files", "--glob", "**/test*.py", "--glob", "**/*_test.py", "--glob", "**/tests/*.py" },
    })
end

M.search_recent_files = function()
    -- Search files modified in the last 7 days
    require("telescope.builtin").find_files({
        prompt_title = "< Recent Files (7 days) >",
        find_command = { "find", ".", "-type", "f", "-mtime", "-7", "-not", "-path", "*/.git/*", "-not", "-path", "*/__pycache__/*" },
    })
end

return M
