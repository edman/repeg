module("utils", package.seeall)

local regex = require'regex'

-- receive the limits of a range and return a string representing its content
function expand_range(v1, v2)
	expanded = ''
	byteini = string.byte(v1)
	byteend = string.byte(v2)

	while byteini <= byteend do
		expanded = expanded .. string.char(byteini)
		byteini = byteini + 1
	end

	return expanded
end

-- returns whether a given syntactic tree matches the empty character
function contains_empty(tree)
	if regex.ischar(tree) or regex.isrange(tree) or regex.isset(tree)
			or regex.isany(tree) then
		return false
	elseif regex.isempty(tree) then
		return true
	elseif regex.isord(tree) then
		return contains_empty(tree.p1) or contains_empty(tree.p2)
	elseif regex.iscon(tree) then
		return contains_empty(tree.p1) and contains_empty(tree.p2)
	elseif regex.isstar(tree) or regex.islazy(tree) or regex.ispossv(tree) then
		return true
	elseif regex.isand(tree) then
		-- to be discussed
		return true
	elseif regex.isnot(tree) then
		-- to be discussed
		return true
	elseif regex.isplus(tree) then
		return contains_empty(tree.p1)
	elseif regex.isquest(tree) then
		return true
	elseif regex.isopencapt(tree) or regex.isclosecapt(tree) then
		return true
	end
end

-- returns a string that describes the given syntactic tree p
function syntactic_tree_to_string(p)
	if regex.ischar(p) then
		return "'" .. p.v .. "'"
	elseif regex.isrange(p) then
		return "range{" .. p.v1 .. "-" .. p.v2 .. "}"
	elseif regex.isset(p) then
		return "set{" .. p.v .. "}"
	elseif regex.isempty(p) then
		return "empty"
	elseif regex.isany(p) then
		return "any"
	elseif regex.isord(p) then
		local s1 = syntactic_tree_to_string(p.p1)
		local s2 = syntactic_tree_to_string(p.p2)
		return "ord{" .. s1 .. ", " .. s2 .. "}"
	elseif regex.iscon(p) then
		local s1 = syntactic_tree_to_string(p.p1)
		local s2 = syntactic_tree_to_string(p.p2)
		return "con{" .. s1 .. ", " .. s2 .. "}"
	elseif regex.isstar(p) then
		local s = syntactic_tree_to_string(p.p1)
		return 'star{' .. s .. '}'
	elseif regex.islazy(p) then
		local s = syntactic_tree_to_string(p.p1)
		return 'lazy{' .. s .. '}'
	elseif regex.ispossv(p) then
		local s = syntactic_tree_to_string(p.p1)
		return "possv{" .. s .. "}"
	elseif regex.isand(p) then
		local s = syntactic_tree_to_string(p.p1)
		return 'and{' .. s .. '}'
	elseif regex.isnot(p) then
		local s = syntactic_tree_to_string(p.p1)
		return 'not{' .. s .. '}'
	elseif regex.isplus(p) then
		local s = syntactic_tree_to_string(p.p1)
		return 'plus{' .. s .. '}'
	elseif regex.isquest(p) then
		local s = syntactic_tree_to_string(p.p1)
		return 'quest{' .. s .. '}'
	elseif regex.isopencapt(p) then
		return 'open_' .. p.v
	elseif regex.isclosecapt(p) then
		return '_close'
	elseif regex.isvar(p) then
		return 'var{' .. p.v .. '}'
	else
		error("Unknown kind: " .. p.kind)
	end
end

-- print a PEG in the form of a tree
function syntactic_tree_to_expression(p, incon)
	-- traverse the tree recursively
	if regex.ischar(p) then
		return "'" .. p.v .. "'"
	elseif regex.isrange(p) then
		return "[" .. p.v1 .. "-" .. p.v2 .. "]"
	elseif regex.isset(p) then 
		return "[" .. p.v .. "]"
	elseif regex.isempty(p) then
		return "''"
	elseif regex.isany(p) then
		return "."
	elseif regex.isord(p) then
		local s1 = syntactic_tree_to_expression(p.p1, false)
		local s2 = syntactic_tree_to_expression(p.p2, false)
		if incon then
			return '(' .. s1 .. " / " .. s2 .. ')'
		else
			return s1 .. " / " .. s2
		end
	elseif regex.iscon(p) then
		local s1 = syntactic_tree_to_expression(p.p1, true)
		local s2 = syntactic_tree_to_expression(p.p2, true)
		return s1 .. "" .. s2
	elseif regex.isrept(p) then
		local s = syntactic_tree_to_expression(p.p1)
		local op = operator_to_string(p)
		if regex.isterm(p.p1) or regex.isempty(p.p1) then
			return s .. op
		else
			return "(" .. s .. ")" .. op
		end
	elseif regex.ispred(p) then
		local s = syntactic_tree_to_expression(p.p1)
		local op = operator_to_string(p)
		if regex.isterm(p.p1) or regex.isempty(p.p1) then
			return op .. s
		else
			return op .. "(" .. s .. "("
		end
	elseif regex.isopencapt(p) then
		return '{'
	elseif regex.isclosecapt(p) then
		return '}'
	elseif regex.isvar(p) then
		return p.v
	else
		error("Unknown kind: " .. p.kind)
	end
end

function operator_to_string(p)
	if regex.isstar(p) then
		return "*"
	elseif regex.isplus(p) then
		return "+"
	elseif regex.isquest(p) then
		return "?"
	elseif regex.islazy(p) then
		return "*?"
	elseif regex.ispossv(p) then
		return "*+"
	elseif regex.isand(p) then
		return "&"
	elseif regex.isnot(p) then
		return "!"
	end
end

function pegtable_to_string(g)
	local s = ''
	for k, v in pairs(g) do
		local var = k
		local pegtree = v
		s = s .. var ..'\t->\t'.. syntactic_tree_to_expression(pegtree) .. '\n'
	end

	if #s > 0 then s = s:sub(1, #s - 1) end
	return s
end

