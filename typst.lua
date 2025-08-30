local ls = require("luasnip")

-- Referenced from
-- 1: https://github.com/CaptainKills/dotfiles/blob/20d7d30f8507280795f5f14014752b40f7c7eff0/nvim/luasnippets/typst.lua#L22
-- 2: https://github.com/ThetaOmega01/dotfiles/blob/a16df1873bb1f75e8bee2d59fc4c1ea48e7fd252/.config/nvim/lua/snippets/typst.lua#L15
-- Relies on having the typst tree-sitter grammar installed
local in_math = function()
	local ts = require("nvim-treesitter.ts_utils")
	local node = ts.get_node_at_cursor()

	-- String within math mode shouldn't trigger snippets
	if node and node:type() == "string" then
		return false
	end

	while node do
		local type = node:type()
		if type == "math" then
			return true
		end
		node = node:parent()
	end

	return false
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

return {
	autoparse("sum", "sum_(i=${1:1})^(${2:N})"),
}
