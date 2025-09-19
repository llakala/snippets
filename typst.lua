local ls = require("luasnip")

-- Check recursively whether our current node is in some set of allowed nodes,
-- and not in some set of disallowed nodes.
-- Referenced from
-- 1: https://github.com/CaptainKills/dotfiles/blob/20d7d30f8507280795f5f14014752b40f7c7eff0/nvim/luasnippets/typst.lua#L22
-- 2: https://github.com/ThetaOmega01/dotfiles/blob/a16df1873bb1f75e8bee2d59fc4c1ea48e7fd252/.config/nvim/lua/snippets/typst.lua#L15
local function in_group(allowed, disallowed)
	local ts = require("nvim-treesitter.ts_utils")
	local node = ts.get_node_at_cursor()

	while node do
		local type = node:type()

		-- Sometimes these are within math - if we see these before we see math,
		-- we're currently in them, and should exit early
		if vim.tbl_contains(disallowed, type) then
			return false
		end
		if vim.tbl_contains(allowed, type) then
			return true
		end

		node = node:parent()
	end

	return false
end

local in_math = function()
	return in_group({ "math" }, { "code", "content", "string" })
end

-- We would use `extend_decorator.apply`, but it doen't allow a string trig,
-- which I would miss. Instead, we write a simple wrapper that makes it an
-- autosnippet that only triggers in math mode
local autoparse = function(trig, body, opts)
	trig = {
		snippetType = "autosnippet",
		condition = in_math,
		trig = trig,
	}

	return ls.parser.parse_snippet(trig, body, opts)
end

-- Referenced from:
-- https://github.com/michaelfortunato/dotfiles/blob/a4365bc2eec20c84003e01099edb861f568a299a/nvim/.config/nvim/lua/plugins/luasnip/typst.lua
-- Slightly modified to add indentation on each row, take cols first, and overall make more readable
local generate_matrix = function(_, snip)
	-- We swap cols and rows, so 21mat is horizontal, and 12mat is vertical
	local cols = tonumber(snip.captures[1])
	local rows = tonumber(snip.captures[2])

	local nodes = {}
	local index = 1

	for row = 1, rows, 1 do
		-- Start out by indenting every line correctly!
		table.insert(nodes, t("  "))

		table.insert(nodes, r(index, tostring(row) .. "x1", i(1)))
		index = index + 1

		for col = 2, cols, 1 do
			table.insert(nodes, t(", "))
			table.insert(nodes, r(index, tostring(row) .. "x" .. tostring(col), i(1)))
			index = index + 1
		end

		table.insert(nodes, t({ ";", "" }))
	end

	nodes[#nodes] = t(";")
	return sn(nil, nodes)
end

return {
	autoparse("sum", "sum_(i=${1:1})^(${2:N})"),
	autoparse("*", "dot"),
	autoparse("ihat", "hat(i)"),
	autoparse("jhat", "hat(j)"),
	autoparse("khat", "hat(k)"),

	s(
		{
			trig = "(%d)(%d)mat",
			regTrig = true,
			snippetType = "autosnippet",
		},
		fmta(
			[[
        mat(
        <>
        )<>]],
			{
				d(1, generate_matrix),
				i(0),
			}
		),
		{ condition = in_math }
	),
}
