------------------------------------------------------------------------
--                              TabLine                               --
------------------------------------------------------------------------
local M = {}
local api = vim.api
local cmd = api.nvim_command
local icons = require('tables._icons')
local config = require('modules.config')

-- Separators
local left_separator = ''
local right_separator = ''
local space = ' '

local TrimmedDirectory = function(dir)
	local home = os.getenv('HOME')
	local _, index = string.find(dir, home, 1)
	if index ~= nil and index ~= string.len(dir) then
		if string.len(dir) > 30 then
			dir = '..' .. string.sub(dir, 30)
		end
		return string.gsub(dir, home, '~')
	end
	return dir
end

local getBufLabel = function(bufnr)
	local file_name = api.nvim_buf_get_name(bufnr)

	-- handle terminal buffers
	if string.find(file_name, 'term://') ~= nil then
		return ' ' .. api.nvim_call_function('fnamemodify', { file_name, ':p:t' })
	end

	file_name = api.nvim_call_function('fnamemodify', { file_name, ':p:t' })

	if file_name == '' then
		return 'No Name'
	end

	local icon = icons.deviconTable[file_name]

	-- show modified indicator
	local modified = api.nvim_buf_get_option(bufnr, 'modified') and ' ●' or ''

	if icon ~= nil then
		return icon .. space .. file_name .. modified
	end
	return file_name .. modified
end

local set_colours = function()
	local colors = require('modules.colors').get()
	cmd('hi TabLineSel gui=Bold guibg=' .. colors.green .. ' guifg=' .. colors.black_fg)
	cmd('hi TabLineSelSeparator gui=bold guifg=' .. colors.green)
	cmd('hi TabLine guibg=' .. colors.inactive_bg .. ' guifg=' .. colors.white_fg .. ' gui=None')
	cmd('hi TabLineSeparator guifg=' .. colors.inactive_bg)
	cmd('hi TabLineFill guibg=None gui=None')
end

function M.init()
	if not config.get().tabline then
		return ''
	end
	set_colours()

	local tabline = ''

	-- get all listed buffers only (no hidden/unlisted ones)
	local buf_list = vim.tbl_filter(function(b)
		return api.nvim_buf_is_valid(b) and api.nvim_buf_get_option(b, 'buflisted')
	end, api.nvim_list_bufs())

	local current_buf = api.nvim_get_current_buf()

	for _, bufnr in ipairs(buf_list) do
		local file_name = getBufLabel(bufnr)

		if bufnr == current_buf then
			tabline = tabline .. '%' .. bufnr .. 'T'
			tabline = tabline .. '%#TabLineSelSeparator# ' .. left_separator
			tabline = tabline .. '%#TabLineSel# ' .. file_name
			tabline = tabline .. ' %#TabLineSelSeparator#' .. right_separator
			tabline = tabline .. '%T'
		else
			tabline = tabline .. '%' .. bufnr .. 'T'
			tabline = tabline .. '%#TabLineSeparator# ' .. left_separator
			tabline = tabline .. '%#TabLine# ' .. file_name
			tabline = tabline .. ' %#TabLineSeparator#' .. right_separator
			tabline = tabline .. '%T'
		end
	end

	-- right side: show current working directory
	tabline = tabline .. '%='
	local dir = api.nvim_call_function('getcwd', {})
	tabline = tabline
		.. '%#TabLineSeparator#'
		.. left_separator
		.. '%#Tabline# '
		.. TrimmedDirectory(dir)
		.. '%#TabLineSeparator#'
		.. right_separator
	tabline = tabline .. space

	return tabline
end

return M
