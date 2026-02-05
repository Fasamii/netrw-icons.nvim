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
			local symbol, hi = provider.get_icon(name, nil, { strict = true, default = M.options.file_default });
			if symbol then
				return { symbol = symbol .. " ", hi = hi };
			end
		elseif type == "miniicons" then
			local symbol, hi, is_default = provider.get("file", name)
			if symbol then
				if is_default and not M.options.file_default then
					symbol = "";
				end
				return { symbol = symbol .. " ", hi = hi };
			end
		end
	end

	return nil;
end


local function get_icon(node)
	if node.type == parse.TYPE_DIR and M.options.dir then
		if M.options.dir then
			return { symbol = M.options.dir, hi = "Directory" };
		end
	elseif node.type == parse.TYPE_SYMLINK and M.options.sym then
		if M.options.sym then
			return { symbol = M.options.sym, hi = "Question" };
		end
	elseif node.type == parse.TYPE_FILE and M.options.file then
		local file_type = vim.fn.fnamemodify(node.name, ":e");
		if string.sub(file_type, -1) == "*" then
			return get_icon_from_provider("exe")
		end
		return get_icon_from_provider(node.name);
	end

	return nil;
end

local function path_to_bufnr(path)
	path = vim.fn.fnamemodify(path, ":p");

	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) then
			local name = vim.api.nvim_buf_get_name(bufnr);
			if name == path then
				return bufnr;
			end
		end
	end

	return nil
end

local function get_lsp_diagnostics(node)
	-- local diagnostics = vim.diagnostic.get(path_to_bufnr(node.path))

	-- for _, d in ipairs(diag) do
	-- 	if d.severity == vim.diagnostic.severity.ERROR and M.options.lsp.error then
	-- 		table.insert(diagnostics, { icon = "E", hl = "DiagnosticError" })
	-- 	elseif d.severity == vim.diagnostic.severity.WARN and M.options.lsp.warn then
	-- 		table.insert(diagnostics, { icon = "W", hl = "DiagnosticWarn" })
	-- 	elseif d.severity == vim.diagnostic.severity.INFO and M.options.lsp.info then
	-- 		table.insert(diagnostics, { icon = "I", hl = "DiagnosticInfo" })
	-- 	elseif d.severity == vim.diagnostic.severity.HINT and M.options.lsp.hint then
	-- 		table.insert(diagnostics, { icon = "H", hl = "DiagnosticHint" })
	-- 	end
	-- end

	-- return diagnostics
	return nil;
end

local function draw(bufnr)
	local namespace = vim.api.nvim_create_namespace("netrw")
	vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)

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
				vim.api.nvim_buf_set_extmark(bufnr, namespace, i - 1, node.icon, {
					id = i,
					virt_text_pos = "inline",
					virt_text = { virt_text },
				});
			end
			if M.options.lsp then
				local diagnostics = get_lsp_diagnostics(node);
				if diagnostics then
					local virt_text = { " " .. "ERROR" };

					vim.api.nvim_buf_set_extmark(bufnr, namespace, i - 1, node.lsp, {
						id = i,
						virt_text_pos = "inline",
						virt_text = { virt_text },
					});
				end
			end
		end
	end
end

--- @class Config
M.options = {}

--- @class Config
local default = {
	prefer = nil,
	file = true,
	file_default = true,
	dir = " ",
	sym = false,
	lsp = {
		info = false,
		hint = false,
		warn = true,
		error = true,
	}
}

---@param options Config|nil
function M.setup(options)
	M.options = vim.tbl_deep_extend("force", {}, default, options or {})

	if M.options.file or M.options.dir then
		icon_provider = get_icon_provider(M.options.prefer)
		if not icon_provider then
			error("No icon provider found");
		end
	end

	vim.api.nvim_create_autocmd("BufModifiedSet", {
		pattern = { "*" },
		group = vim.api.nvim_create_augroup("netrw_icons", { clear = false }),
		callback = function(args)
			if not (vim.bo and vim.bo.filetype == "netrw") then
				return
			end

			if vim.b.netrw_liststyle ~= 0 and vim.b.netrw_liststyle ~= 1 and vim.b.netrw_liststyle ~= 3 then
				return
			end

			draw(args.buf)
		end
	})
end

return M
