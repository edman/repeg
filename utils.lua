module("utils", package.seeall)

local regex = require'regex'

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

-- concatenate two tables considering only integer indices
function concat_tables(table1, table2)
	tb = {}
	for i=1,#table1 do
		tb[#tb + 1] = table1[i]
	end
	for i=1,#table2 do
		tb[#tb + 1] = table2[i]
	end

	return tb
end

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

function is_lower(str)
	return str == string.lower(str)
end

function is_upper(str)
	return str == string.upper(str)
end

-- print a given table expected to represent a first set
function print_first(tb)
    for k,v in pairs(tb) do
        if k == 'range' then
            s = '| '
            for i=1,#tb.range do
                s = s .. tb.range[i].v1 .. ', ' .. tb.range[i].v2 .. ' | '
            end
            print('', 'range', s)
		else
			print('', k, v)
		end
	end
end

