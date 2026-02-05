local M = {}
local parse = require("netrw.parse")

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

local function get_file_icon(node)
	if not icon_provider then
		return nil, nil
	end

	if icon_provider.type == "devicons" then
		local icon, hl = icon_provider.provider.get_icon(node.node, nil, { strict = true, default = false })
		return icon, hl
	elseif icon_provider.type == "miniicons" then
		local icon, hl = icon_provider.provider.get("file", node.node)
		return icon, hl
	end

	return nil, nil
end

local function get_lsp_diagnostics(bufnr, node)
	local diagnostics = {}
	local filepath = node.dir .. "/" .. node.node

	local diag = vim.diagnostic.get(nil, { path = filepath })

	for _, d in ipairs(diag) do
		if d.severity == vim.diagnostic.severity.ERROR and M.options.lsp.error then
			table.insert(diagnostics, { icon = "E", hl = "DiagnosticError" })
		elseif d.severity == vim.diagnostic.severity.WARN and M.options.lsp.warn then
			table.insert(diagnostics, { icon = "W", hl = "DiagnosticWarn" })
		elseif d.severity == vim.diagnostic.severity.INFO and M.options.lsp.info then
			table.insert(diagnostics, { icon = "I", hl = "DiagnosticInfo" })
		elseif d.severity == vim.diagnostic.severity.HINT and M.options.lsp.hint then
			table.insert(diagnostics, { icon = "H", hl = "DiagnosticHint" })
		end
	end

	return diagnostics
end

local function draw(bufnr)
	local namespace = vim.api.nvim_create_namespace("netrw")
	vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	for i, line in ipairs(lines) do
		local node = parse.get_node(line)
		if node then
			-- Draw file/dir icon on the left
			if (node.type == parse.TYPE_FILE and M.options.file) or
				(node.type == parse.TYPE_DIR and M.options.dir) then
				local icon, hl = get_file_icon(node)
				if icon then
					local opts = {
						id = i * 2, -- Unique ID for icon
						virt_text = hl and { { icon .. " ", hl } } or { { icon .. " " } },
						virt_text_pos = "inline",
					}
					vim.api.nvim_buf_set_extmark(bufnr, namespace, i - 1, node.icon_col, opts)
				end
			end

			-- Draw LSP diagnostics on the right
			if node.type == parse.TYPE_FILE then
				local diagnostics = get_lsp_diagnostics(bufnr, node)
				if #diagnostics > 0 then
					local virt_text = {}
					for _, diag in ipairs(diagnostics) do
						table.insert(virt_text, { " " .. diag.icon, diag.hl })
					end

					local opts = {
						id = i * 2 + 1, -- Unique ID for LSP
						virt_text = virt_text,
						virt_text_pos = "inline",
					}
					vim.api.nvim_buf_set_extmark(bufnr, namespace, i - 1, node.lsp_col, opts)
				end
			end
		end
	end
end

--- @class Config
M.options = {}

--- @class Config
local default = {
	prefer = nil, -- "miniicons" or "devicons"
	file = true,
	dir = true,
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
	end

	vim.api.nvim_create_autocmd({ "BufEnter", "DiagnosticChanged" }, {
		pattern = "*",
		group = vim.api.nvim_create_augroup("netrw_icons", { clear = true }),
		callback = function(args)
			if vim.bo[args.buf].filetype ~= "netrw" then
				return
			end
			draw(args.buf)
		end
	})
end

return M
