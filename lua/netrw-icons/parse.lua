-- SPDX-License-Identifier: MIT
--
-- Copyright (c) 2026 Mikołaj Kozłowski
--
-- Portions of this file are derived from:
-- prichrd/netrw.nvim (MIT)
-- https://github.com/prichrd/netrw.nvim

local M = {}

M.TYPE_DIR = 0
M.TYPE_FILE = 1
M.TYPE_SYMLINK = 2

---@alias PWord {dir:string, node:string, link:string|nil, extension:string|nil, type:number, icon_col:number, name_col:number, lsp_col:number}

---@param line string
---@param curdir string
---@return PWord|nil
local parse_liststyle_0 = function(line, curdir)
	local _, _, node, link = string.find(line, "^(.+)@\t%s*%-%->%s*(.+)")
	if node then
		return {
			dir = curdir,
			icon_col = 0,
			name_col = 0,
			lsp_col = #node,
			node = node,
			extension = vim.fn.fnamemodify(node, ":e"),
			link = link,
			type = M.TYPE_SYMLINK,
		}
	end

	local _, _, dir = string.find(line, "^(.*)/")
	if dir then
		return {
			dir = curdir,
			icon_col = 0,
			name_col = 0,
			lsp_col = #dir + 1, -- +1 for the "/"
			node = dir,
			type = M.TYPE_DIR,
		}
	end

	local ext = vim.fn.fnamemodify(line, ":e")
	local clean_line = line
	if string.sub(ext, -1) == "*" then
		ext = string.sub(ext, 1, -2)
		clean_line = string.sub(line, 1, -2)
	end

	return {
		dir = curdir,
		icon_col = 0,
		name_col = 0,
		lsp_col = #clean_line,
		node = clean_line,
		extension = ext,
		type = M.TYPE_FILE,
	}
end

---@param line string
---@param curdir string
---@return PWord|nil
local parse_liststyle_1 = function(line, curdir)
	local _, _, node, link = string.find(line, "^(.+)@%s+")
	if node then
		return {
			dir = curdir,
			icon_col = 0,
			name_col = 0,
			lsp_col = #node,
			node = node,
			extension = vim.fn.fnamemodify(node, ":e"),
			link = link,
			type = M.TYPE_SYMLINK,
		}
	end

	local _, _, dir = string.find(line, "^(.*)/")
	if dir then
		return {
			dir = curdir,
			icon_col = 0,
			name_col = 0,
			lsp_col = #dir + 1,
			node = dir,
			type = M.TYPE_DIR,
		}
	end

	local file = vim.fn.substitute(line, "^\\(\\%(\\S\\+ \\)*\\S\\+\\).\\{-}$", "\\1", "e")
	local ext = vim.fn.fnamemodify(file, ":e")
	if string.sub(ext, -1) == "*" then
		ext = string.sub(ext, 1, -2)
		file = string.sub(file, 1, -2)
	end

	return {
		dir = curdir,
		icon_col = 0,
		name_col = 0,
		lsp_col = #file,
		node = file,
		extension = ext,
		type = M.TYPE_FILE,
	}
end

---@param line string
---@return PWord|nil
local parse_liststyle_3 = function(line)
	local current_dir = vim.b.netrw_curdir;
	local type = M.TYPE_FILE;

	local _, tree_end = string.find(line, "^[|%s]*");

	local content = string.sub(line, tree_end + 1, #line);
	if content == "" then
		return nil;
	end

	local _, _, link, link_target = string.find(content, "^(.+)@\t%s*%-%->%s*(.+)")
	if link then
		type = M.TYPE_SYMLINK;
	end

	local _, _, dir = string.find(content, "^(.*)/")
	if dir then
		type = M.TYPE_DIR;
	end

	return {
		name = link_target or content,
		path = current_dir .. "/" .. (link_target or content),
		icon = tree_end,
		lsp = tree_end + #content,
		type = type,
	}
end

---@param line string
---@return PWord|nil
M.get_node = function(line)
	if string.find(line, '^"') then
		return nil
	end

	if line == "" then
		return nil
	end

	local curdir = vim.b.netrw_curdir
	local liststyle = vim.b.netrw_liststyle

	if liststyle == 0 then
		return parse_liststyle_0(line, curdir)
	elseif liststyle == 1 then
		return parse_liststyle_1(line, curdir)
	elseif liststyle == 3 then
		return parse_liststyle_3(line)
	end

	return nil
end

return M
