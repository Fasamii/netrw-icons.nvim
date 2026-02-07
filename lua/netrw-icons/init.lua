-- SPDX-License-Identifier: MIT
--
-- Copyright (c) 2026 Mikołaj Kozłowski
--
-- Portions of this file are derived from:
-- prichrd/netrw.nvim (MIT)
-- https://github.com/prichrd/netrw.nvim

local M = {}

local parse = require("netrw-icons.parse")

local icon_provider = nil

local function get_icon_provider(prefer)
	local providers = {}

	local has_devicons, devicons = pcall(require, "nvim-web-devicons")
	if has_devicons then
		providers.devicons = devicons
	end

	local has_miniicons, miniicons = pcall(require, "mini.icons")
	if has_miniicons then
		providers.miniicons = miniicons
	end

	if prefer and providers[prefer] then
		return { type = prefer, provider = providers[prefer] }
	end

	if providers.miniicons then
		return { type = "miniicons", provider = providers.miniicons }
	elseif providers.devicons then
		return { type = "devicons", provider = providers.devicons }
	end

	return nil
end

local function get_icon_from_provider(name)
	if icon_provider then
		local provider = icon_provider.provider;
		local type = icon_provider.type;
		if type == "devicons" then
			local symbol, hi = provider.get_icon(name, nil, { strict = true, default = M.options.icon_fallback });
			if symbol then
				return { symbol = symbol .. " ", hi = hi };
			end
		elseif type == "miniicons" then
			local symbol, hi, is_default = provider.get("file", name)
			if symbol then
				if is_default and not M.options.icon_fallback then
					symbol = "";
				end
				return { symbol = symbol .. " ", hi = hi };
			end
		end
	end

	return nil;
end

local function get_icon_from_table(name, hi)
	if M.options.file and type(M.options.file) == "table" then
		local entry = M.options.file[name];
		if entry then
			if type(entry) == "table" then
				return { symbol = entry[1], hi = entry[2] }
			else
				if hi then
					return { symbol = entry, hi = hi }
				else
					return { symbol = entry }
				end
			end
		end
	end
end

local function get_icon(node)
	if node.type == parse.TYPE_DIR then
		return get_icon_from_table("dir", "netrwDir");
	elseif node.type == parse.TYPE_SYMLINK then
		return get_icon_from_table("sym", "netrwSymlink");
	elseif node.type == parse.TYPE_EXE then
		return get_icon_from_table("exe", "netrwExe");
	else
		if M.options.file then
			local extension = vim.fn.fnamemodify(node.name, ":e");
			local from_table = get_icon_from_table(extension);
			if from_table then
				return from_table
			else
				return get_icon_from_provider(node.name);
			end
		end
	end

	return nil;
end

local function draw(bufnr)
	local namespace_icons = vim.api.nvim_create_namespace("netrw-icons")

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	for i, line in ipairs(lines) do
		local node = parse.get_node(line)

		if node then
			local icon = get_icon(node);
			if icon then
				local symbol = icon.symbol;
				local virt_text = { symbol };
				if icon.hi then
					virt_text[2] = icon.hi;
				end

				vim.api.nvim_buf_set_extmark(bufnr, namespace_icons, i - 1, node.icon, {
					id = i,
					virt_text_pos = "inline",
					virt_text = { virt_text },
				});
			end
		end
	end
end

--- @class Config
M.options = {}

--- @class Config
local default = {
	prefer = nil,

	icon_fallback = true,
	file = {
		dir = " ",
		sym = " ",
		exe = " ",
	},
}

---@param options Config|nil
function M.setup(options)
	M.options = vim.tbl_deep_extend("force", {}, default, options or {})

	icon_provider = get_icon_provider(M.options.prefer)
	if not icon_provider then
		error("[netrw-icons] No icon provider found");
	end

	vim.api.nvim_create_autocmd("BufModifiedSet", {
		pattern = { "*" },
		group = vim.api.nvim_create_augroup("netrw_icons", { clear = false }),
		callback = function(args)
			if not (vim.bo and vim.bo.filetype == "netrw") then
				return
			end

			-- if vim.b.netrw_liststyle ~= 0 and vim.b.netrw_liststyle ~= 1 and vim.b.netrw_liststyle ~= 3 then
			if vim.b.netrw_liststyle ~= 3 then
				return
			end

			draw(args.buf)
		end
	})
end

return M
