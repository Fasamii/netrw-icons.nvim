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
M.TYPE_EXE = 2
M.TYPE_SYMLINK = 3

---@alias rwNode{name:string, icon:number, type:number}

---@param line string
---@param curdir string
---@return rwNode|nil
local parse_liststyle_0 = function(line)
	local current_dir = vim.b.netrw_curdir;
	local type = M.TYPE_FILE;

	local name = line;

	if name:sub(-1) == "*" then
		type = M.TYPE_EXE;
	end

	local _, _, link, link_target = string.find(line, "^(.+)@\t%s*%-%->%s*(.+)")
	if link then
		type = M.TYPE_SYMLINK;
		name = link_target;
	end

	local _, _, dir = string.find(line, "^(.*)/")
	if dir then
		type = M.TYPE_DIR;
	end

	return {
		name = name,
		icon = 0,
		type = type,
	}
end

---@param line string
---@return rwNode|nil
local parse_liststyle_1 = function(line)
	local node = {};
	node.type = M.TYPE_FILE;
	node.icon = 0;

	node.name = line:match("^(%S+)")

	if node.name:sub(-1) == "*" then
		node.type = M.TYPE_EXE;
		return node;
	end

	local _, _, link, link_target = string.find(line, "^(.+)@%s+")
	if link then
		node.type = M.TYPE_SYMLINK;
		node.name = link_target;
		return node;
	end

	local _, _, dir = string.find(line, "^(.*)/")
	if dir then
		node.type = M.TYPE_DIR;
		return node;
	end

	return node;
end

---@param line string
---@return rwNode|nil
local parse_liststyle_3 = function(line)
	local node = {};
	node.type = M.TYPE_FILE;

	local _, tree_end = string.find(line, "^[|%s]*");
	node.icon = tree_end;

	local content = string.sub(line, tree_end + 1, #line);
	if content == "" then
		return nil;
	end

	node.name = content;

	if node.name:sub(-1) == "*" then
		node.type = M.TYPE_EXE;
		return node;
	end

	local _, _, link, link_target = string.find(content, "^(.+)@\t%s*%-%->%s*(.+)")
	if link then
		node.type = M.TYPE_SYMLINK;
		node.name = link_target;
		return node;
	end

	local _, _, dir = string.find(content, "^(.*)/")
	if dir then
		type = M.TYPE_DIR;
		return node;
	end

	return node;
end

---@param line string
---@return rwNode|nil
M.get_node = function(line)
	if string.find(line, '^"') then return nil end
	if line == "" then return nil end

	local liststyle = vim.b.netrw_liststyle

	if liststyle == 0 then
		return parse_liststyle_0(line);
	elseif liststyle == 1 then
		return parse_liststyle_1(line);
	elseif liststyle == 3 then
		return parse_liststyle_3(line);
	end

	return nil
end

return M
