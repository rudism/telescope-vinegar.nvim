local telescope = require('telescope')

local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local action_set = require('telescope.actions.set')
local utils = require('telescope.utils')
local conf = require('telescope.config').values

local scan = require('plenary.scandir')
local Path = require('plenary.path')
local os_sep = Path.path.sep

return telescope.register_extension {
  exports = {
    file_browser = function(opts)
      opts = opts or {}

      local is_dir = function(value)
        return value:sub(-1, -1) == os_sep
      end

      opts.depth = opts.depth or 1
      opts.cwd = opts.cwd and vim.fn.expand(opts.cwd) or utils.buffer_dir()
      opts.new_finder = opts.new_finder
        or function(o)
          opts.cwd = o.path
          opts.hidden = o.hidden
          local data = {}

          scan.scan_dir(o.path, {
            hidden = opts.hidden or false,
            add_dirs = true,
            depth = opts.depth,
            on_insert = function(entry, typ)
              table.insert(data, typ == "directory" and (entry .. os_sep) or entry)
            end,
          })
          table.insert(data, ".." .. os_sep)

          local maker = function()
            local mt = {}
            mt.cwd = opts.cwd
            mt.display = function(entry)
              local hl_group
              local display = utils.transform_path(opts, entry.value)
              if is_dir(entry.value) then
                display = display .. os_sep
                if not opts.disable_devicons then
                  display = (opts.dir_icon or "") .. " " .. display
                  hl_group = "Default"
                end
              else
                display, hl_group = utils.transform_devicons(entry.value, display, opts.disable_devicons)
              end

              if hl_group then
                return display, { { { 1, 3 }, hl_group } }
              else
                return display
              end
            end

            mt.__index = function(t, k)
              local raw = rawget(mt, k)
              if raw then
                return raw
              end

              if k == "path" then
                local retpath = Path:new({ t.cwd, t.value }):absolute()
                if not vim.loop.fs_access(retpath, "R", nil) then
                  retpath = t.value
                end
                if is_dir(t.value) then
                  retpath = retpath .. os_sep
                end
                return retpath
              end

              return rawget(t, rawget({ value = 1 }, k))
            end

            return function(line)
              local tbl = { line }
              tbl.ordinal = Path:new(line):make_relative(opts.cwd)
              return setmetatable(tbl, mt)
            end
          end

          return finders.new_table { results = data, entry_maker = maker() }
        end

      pickers.new(opts, {
        prompt_title = 'File Browser',
        prompt_prefix = '> ',
        finder = opts.new_finder({ path = opts.cwd, hidden = opts.hidden }),
        previewer = conf.file_previewer(opts),
        sorter = conf.file_sorter(opts),
        initial_mode = opts.initial_mode or 'normal',
        attach_mappings = function(prompt_bufnr, map)
          action_set.select:replace_if(function()
            return is_dir(action_state.get_selected_entry().path)
          end, function()
            local new_cwd = vim.fn.expand(action_state.get_selected_entry().path:sub(1, -2))
            local current_picker = action_state.get_current_picker(prompt_bufnr)
            current_picker.cwd = new_cwd
            current_picker:refresh(opts.new_finder({ path = new_cwd, hidden = opts.hidden }), { reset_prompt = true })
            vim.cmd('stopinsert')
          end)

          local refresh_prompt = function(path)
            vim.cmd('stopinsert')
            local current_picker = action_state.get_current_picker(prompt_bufnr)
            current_picker.cwd = path or current_picker.cwd
            local new_prefix = opts.new_file_mode and 'Create File> ' or '> '
            current_picker:refresh(
              opts.new_finder({ path = path or current_picker.cwd, hidden = opts.hidden }),
              { reset_prompt = true, new_prefix = new_prefix }
            )
          end

          local create_new_file = function()
            local current_picker = action_state.get_current_picker(prompt_bufnr)
            local file = action_state.get_current_line()
            if file == "" then
              refresh_prompt()
              return
            end

            local fpath = current_picker.cwd .. os_sep .. file
            if not is_dir(fpath) then
              Path:new(fpath):touch { parents = true }
              refresh_prompt()
            else
              Path:new(fpath:sub(1, -2)):mkdir { parents = true }
              local new_cwd = vim.fn.expand(fpath)
              refresh_prompt(new_cwd)
            end
          end

          map("n", "-", function() -- go up a level
            local current_picker = action_state.get_current_picker(prompt_bufnr)
            local new_cwd = Path:new(current_picker.cwd):parent():absolute()
            refresh_prompt(new_cwd)
          end)

          map("n", "/", function() -- enter insert mode to search
            vim.cmd('startinsert')
          end)

          map("n", "+", function() -- enter insert mode to create new file
            opts.new_file_mode = true
            refresh_prompt()
            vim.cmd('startinsert')
          end)

          map("n", "h", function() -- toggle hidden
            local current_picker = action_state.get_current_picker(prompt_bufnr)
            current_picker:refresh(
              opts.new_finder({ path = current_picker.cwd, hidden = not opts.hidden }),
              { reset_prompt = true }
            )
          end)

          map("i", "<esc>", function()
            opts.new_file_mode = false
            refresh_prompt()
          end)

          map("i", "<cr>", function() -- create file or default
            if opts.new_file_mode then
              opts.new_file_mode = false
              create_new_file()
            else
              actions.select_default(prompt_bufnr)
            end
          end)

          return true
        end,
      }):find()
    end
  }
}
