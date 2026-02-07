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
			return { symbol = M.options.dir, hi = "netrwDir" };
		end
	elseif node.type == parse.TYPE_SYMLINK and M.options.sym then
		if M.options.sym then
			return { symbol = M.options.sym, hi = "netrwSymlink" };
		end
	elseif node.type == parse.TYPE_FILE and M.options.file then
		local file_type = vim.fn.fnamemodify(node.name, ":e");
		if string.sub(file_type, -1) == "*" then
			return get_icon_from_provider("executable")
		end
		return get_icon_from_provider(node.name);
	end

	return nil;
end

local function get_lsp_diagnostics()
	local all_diagnostics = vim.diagnostic.get(nil);

	local file_diagnostics_map = {};
	local dir_diagnostics_map = {};

	for _, diag in ipairs(all_diagnostics) do
		local diag_path = vim.api.nvim_buf_get_name(diag.bufnr);
		diag_path = vim.fn.fnamemodify(diag_path, ":p");

		if not file_diagnostics_map[diag_path] then
			file_diagnostics_map[diag_path] = { info = 0, hint = 0, warn = 0, error = 0 };
		end

		if diag.severity == vim.diagnostic.severity.ERROR and M.options.lsp.error then
			file_diagnostics_map[diag_path].error = file_diagnostics_map[diag_path].error + 1
		elseif diag.severity == vim.diagnostic.severity.WARN and M.options.lsp.warn then
			file_diagnostics_map[diag_path].warn = file_diagnostics_map[diag_path].warn + 1
		elseif diag.severity == vim.diagnostic.severity.INFO and M.options.lsp.info then
			file_diagnostics_map[diag_path].info = file_diagnostics_map[diag_path].info + 1
		elseif diag.severity == vim.diagnostic.severity.HINT and M.options.lsp.hint then
			file_diagnostics_map[diag_path].hint = file_diagnostics_map[diag_path].hint + 1
		end
	end

	if M.options.lsp_sum_dir then
		for file_path, counts in pairs(file_diagnostics_map) do
			file_path = file_path:gsub("/+$", "")

			local dir = file_path:match("(.+)/[^/]+$")
			while dir do
				local dir_key = dir .. "/"

				if not dir_diagnostics_map[dir_key] then
					dir_diagnostics_map[dir_key] = {
						info = 0,
						hint = 0,
						warn = 0,
						error = 0,
					}
				end

				dir_diagnostics_map[dir_key].info  = dir_diagnostics_map[dir_key].info + counts.info
				dir_diagnostics_map[dir_key].hint  = dir_diagnostics_map[dir_key].hint + counts.hint
				dir_diagnostics_map[dir_key].warn  = dir_diagnostics_map[dir_key].warn + counts.warn
				dir_diagnostics_map[dir_key].error = dir_diagnostics_map[dir_key].error + counts.error

				if dir == "/" then
					break
				end

				dir = dir:match("(.+)/[^/]+$")
			end
		end
	end

	return file_diagnostics_map, dir_diagnostics_map;
end

local function format_diagnostic(count, config, hi)
	if not config then
		return nil;
	end

	if count == 0 then
		return nil;
	end

	local prefix = "";
	if type(config) == "string" then
		prefix = config;
	end

	return { (prefix .. tostring(count)), hi }
end


local function draw(bufnr)
	local namespace_icons = vim.api.nvim_create_namespace("netrw-icons")
	local namespace_diagnostics = vim.api.nvim_create_namespace("netrw-diagnostics")

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	local file_diagnostics_map, dir_diagnostics_map = nil, nil;
	if M.options.lsp then
		file_diagnostics_map, dir_diagnostics_map = get_lsp_diagnostics();
	end

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
			if M.options.lsp then
				local diagnostics = nil;

				if node.type == parse.TYPE_DIR and M.options.lsp_sum_dir then
					if dir_diagnostics_map then
						diagnostics = dir_diagnostics_map[node.path];
					end
				else
					if file_diagnostics_map then
						diagnostics = file_diagnostics_map[node.path];
					end
				end

				if diagnostics then
					local virt_text = { { "  " } };
					local diag_items = {
						{ count = diagnostics.error, config = M.options.lsp.error, hl = "DiagnosticError" },
						{ count = diagnostics.warn,  config = M.options.lsp.warn,  hl = "DiagnosticWarn" },
						{ count = diagnostics.hint,  config = M.options.lsp.hint,  hl = "DiagnosticHint" },
						{ count = diagnostics.info,  config = M.options.lsp.info,  hl = "DiagnosticInfo" },
					};

					local has_diagnostics = false;
					for _, item in ipairs(diag_items) do
						local formated = format_diagnostic(item.count, item.config, item.hl);
						if formated then
							if has_diagnostics then
								table.insert(virt_text, { " " });
							end
							table.insert(virt_text, formated);
							has_diagnostics = true;
						end
					end

					if has_diagnostics then
						vim.api.nvim_buf_set_extmark(bufnr, namespace_diagnostics, i - 1, node.lsp, {
							id = i,
							virt_text_pos = "inline",
							virt_text = virt_text,
						});
					end
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

	file = true, -- TODO: Accept table with extension -> icon mapping
	file_default = true,

	dir = " ",
	sym = " ",

	lsp = {
		info = false,
		hint = false,
		warn = "W-",
		error = "E-",
	},

	lsp_sum_dir = true,
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

			-- if vim.b.netrw_liststyle ~= 0 and vim.b.netrw_liststyle ~= 1 and vim.b.netrw_liststyle ~= 3 then
			if vim.b.netrw_liststyle ~= 3 then
				return
			end

			draw(args.buf)
		end
	})
end

return M
