module ("regex", package.seeall)
local lpeg = require'lpeg'
local compile = require'compile'
local utils = require'utils'

-- variable used to number the non-terminals of the final PEG
local varnumber
local casas
local zeros

local init = 'S'
local tag = compile.gettag()

local makeempty = compile.makeempty
local makechar = compile.makechar
local makerange = compile.makerange
local makeset = compile.makeset
local makeany = compile.makeany
local makevar = compile.makevar
local makecon = compile.makecon
local makeord = compile.makeord
local makestar = compile.makestar
local makeplus = compile.makeplus
local makequest = compile.makequest
local makelazy = compile.makelazy
local makepossv = compile.makepossv
local makenot = compile.makenot
local makeand = compile.makeand

function cmpkind(p, k)
	return p.kind == k
end

function isempty(p)
	return cmpkind(p, tag.empty)
end

function ischar(p)
	return cmpkind(p, tag.char)
end

function isrange(p)
	return cmpkind(p, tag.range)
end

function isset(p)
	return cmpkind(p, tag.set)
end

-- tag.any represents the character that matches any (".")
function isany(p)
	return cmpkind(p, tag.any)
end

-- returns true when the node has only a fixed value, having no more operators,
-- that is, when this is a terminal node
function isterm(p)
	return ischar(p) or isrange(p) or isany(p) or isopencapt(p)
		or isclosecapt(p) or isset(p)
end

function iscon(p)
	return cmpkind(p, tag.con)
end

function isord(p)
	return cmpkind(p, tag.ord)
end

function isvar(p)
	return cmpkind(p, tag.var)
end

function isstar(p)
	return cmpkind(p, tag.star)
end

function isplus(p)
	return cmpkind(p, tag.plus)
end

function isquest(p)
	return cmpkind(p, tag.quest)
end

function islazy(p)
	return cmpkind(p, tag.lazy)
end

function ispossv(p)
	return cmpkind(p, tag.possv)
end

function isand(p)
	return cmpkind(p, tag.andp)
end

function isnot(p)
	return cmpkind(p, tag.notp)
end

function isopencapt(p)
	return cmpkind(p, tag.opencapt)
end
function isclosecapt(p)
	return cmpkind(p, tag.closecapt)
end

function isrept(p)
	return isstar(p) or islazy(p) or ispossv(p) or
		isplus(p) or isquest(p)
end

function ispred(p)
	return isand(p) or isnot(p)
end

-- given the syntactic tree of PEG's rule, return the corresponding lpeg
-- pattern
function makepeg (p)
	if ischar(p) then
		return lpeg.P(p.v)
	elseif isrange(p) then
		return lpeg.R(p.v1 .. p.v2)
	elseif isset(p) then
		if p.v:sub(1,1) ~= "^" then
			return lpeg.S(p.v)
		else
			return lpeg.P(lpeg.P(1) - lpeg.S(p.v:sub(2)))
		end
	elseif isempty(p) then
		return lpeg.P""
	elseif isany(p) then
		return lpeg.P(1)
	elseif isord(p) then
		return makepeg(p.p1) + makepeg(p.p2)
	elseif iscon(p) then
		return makepeg(p.p1) * makepeg(p.p2)
	elseif isstar(p) then
		return makepeg(p.p1)^0
	elseif isplus(p) then
		return makepeg(p.p1)^1
	elseif isquest(p) then
		return makepeg(p.p1)^-1
	elseif isvar(p) then
		return lpeg.V(p.v)
	elseif isand(p) then
		return #makepeg(p.p1)
	elseif isnot(p) then
		return -makepeg(p.p1)
	elseif isopencapt(p) then
		return lpeg.Cc('open', p.v) * lpeg.Cp()
	elseif isclosecapt(p) then
		return lpeg.Cc('close') * lpeg.Cp()
	else
		error("Unknown kind: " .. p.kind)
	end
end

-- search for any free position in the table g
-- this funtion is used to name a non-terminal
local function getvar(g)
	local n = 100000
	local v = 'V' .. math.random(n)
	while g[v] do
		v = 'V' .. math.random(n)
	end
	return v
end

local function getnextvar()
	varnumber = varnumber + 1
	if varnumber == casas then
		casas = casas * 10
		zeros = zeros:sub(1, #zeros - 1)
	end
	return 'V' .. zeros .. varnumber
end

-- transformation function that turns the regex syntactic tree from p into a
-- PEG syntactic tree in g
function pi(g, p, k)
	if isempty(p) then
		return k
	elseif isterm(p) then
		if isempty(k) then
			return p
		else
			return makecon(p, k)
		end	
	elseif isord(p) then
		return makeord(pi(g, p.p1, k), pi(g, p.p2, k))
	elseif iscon(p) then
		return pi(g, p.p1, pi(g, p.p2, k))
	elseif isstar(p) then
		local v = getnextvar()
		g[v] = makeord(pi(g, p.p1, makevar(v)), k)
		return makevar(v)
	elseif isquest(p) then
		local v = getnextvar()
		g[v] = makeord(pi(g, p.p1, k), k)
		return makevar(v)
	elseif isplus(p) then
		local v = getnextvar()
		g[v] = makeord(pi(g, p.p1, makevar(v)), k)
		return pi(g, p.p1, makevar(v))
	-- e1*?e2 ==> V <- e2 / e1V
	elseif islazy(p) then
		local v = getnextvar()
		g[v] = makeord(k, pi(g, p.p1, makevar(v)))
		return makevar(v)
	-- e1*+e2 ==> e1*e2
	elseif ispossv(p) then
		if isempty(k) then
			return makestar(pi(g, p.p1, makeempty()))
		else
			return makecon(makestar(pi(g, p.p1, makeempty())), k)
		end
	-- pi(&e1, e2) = &pi(e1,"")e2
	elseif isand(p) then
		if isempty(k) then
			return makeand(pi(g, p.p1, makeempty()))
		else
			return makecon(makeand(pi(g, p.p1, makeempty())), k)
		end
	-- pi(!e1, e2) = !pi(e1,"")e2
	elseif isnot(p) then
		if isempty(k) then
			return makenot(pi(g, p.p1, makeempty()))
		else
			return makecon(makenot(pi(g, p.p1, makeempty())), k)
		end
	elseif isvar(p) then
		error("Should not receive a variable")
	else
		error("Unknown kind: " .. p.kind)
	end
end

function initialize_globals()
	varnumber = 0
	casas = 10
	zeros = "0000"
end

-- print general information about the input
function print_info(retree, g, subject)
	print("Regex: ", utils.syntactic_tree_to_expression(retree))
	print("Input: ", subject)
	print("Arvore: " .. utils.syntactic_tree_to_string(retree))
	print("PEG\n" .. utils.pegtable_to_string(g))
end

function handle_capture(subject, peg)
	-- capt holds the captures found by lpeg
	local capt = lpeg.Ct(peg):match(subject)

	-- return nil if nothing was captured
	if capt == nil then
		return nil
	end

	-- initialize control variables
	local indices = {}
	local last = {}
	local i = 1

	-- process each of the captures to know its start and end
	while i <= #capt do
		if capt[i] =='open' then
			indices[capt[i+1]] = {}
			indices[capt[i+1]].ini = capt[i+2]
			table.insert(last, capt[i+1])
			i = i + 3
		else
			indices[last[#last]].fim = capt[i+1] - 1
			table.remove(last)
			i = i + 2
		end
	end

	for key in pairs(indices) do
		--indices[key] = subject:sub(indices[key].ini, indices[key].fim)
		indices[key] = {indices[key].ini, indices[key].fim}
	end
	return indices
end

-- matches the peg pattern to the given subject taking care of captures
function handle_matching(peg, subject, has_captures)
	local result
	-- retree.capture is set to true in compile.lua when the pattern has captures
	if has_captures then
		result = handle_capture(subject, peg)
	else
		result = peg:match(subject)
	end
	return result
end

function peg_from_retree(retree)
	local g = {}
	g[init] = pi(g, retree, makeempty())
	return g
end

-- re --> regular expression described in a string
-- subject --> subject to be mathed by "re"
-- optimization_function --> a function to optmize the generated PEG
function match(re, subject, optimization_function)
	initialize_globals()

	local retree = compile.parse(re)
	local has_captures = retree.capture

	local g = peg_from_retree(retree)

	-- print general debug information
	print_info(retree, g, subject)

	local peg = createpattern(g)

	--------------------------------------------------------
	-- Here is the place I must call the optimization routine. After we have
	-- the PEG's syntatic tree and before the actual PEG pattern is created
	
	-- if an optmization function was given, apply it to g and peg now
	if optimization_function then
		peg = optimization_function(g, peg)
	end
	--------------------------------------------------------

	local result = handle_matching(peg, subject, has_captures)
	return result
end

-- search the subject for the first substring that matches the expression
function find_normal(re, subject)
	--re = '.* (?: ' .. re .. ' )'
	re = '.*? ( ' .. re .. ' )'
	return match(re, subject)
end

-- optmized version of find
function find(re, subject)
	-- insert a capture around the entire argument re
	re = '(' .. re .. ')'
	-- pass the search optimization routine to match
	return match(re, subject, search_optimization)
	--return find_normal(re, subject)
end

-- modify the table g, adding a new starting rule to optmize search
-- g => table that represents the PEG
-- peg => the pattern represented by g
function search_optimization(g, peg)
	-- get the pattern that represents the first set
	local fpeg = eval_first(g)

	local optmized_peg = lpeg.P {
		"S"
		, S = (-fpeg * lpeg.P(1))^0 * (peg + lpeg.P(1) * lpeg.V('S'))
	}

	return optmized_peg
end

-- evaluates the FIRST set of g, returning a regex string that describes it
function eval_first(g)
	local pegtree = g[init]

	-- get the syntactic tree to describe the FIRST set
	local ftree = first_tree(pegtree, g)
	print('Arvore FIRST: ' .. utils.syntactic_tree_to_string(ftree))

	-- get the lpeg pattern to match the FIRST set
	local fpeg = first(ftree)
	if fpeg.any then
		fpeg = lpeg.P(1)
	else
		fpeg = fpeg.peg
	end

	return fpeg
end

-- returns a syntactic tree that represents the first set of pegtree from the
-- grammar described in g
function first_tree(pegtree, g)
	if isterm(pegtree) then
		return pegtree
	elseif isempty(pegtree) then -- consider merging this with the previous
		return pegtree
	elseif isord(pegtree) then
		local f1 = first_tree(pegtree.p1, g)
		local f2 = first_tree(pegtree.p2, g)

		return makeord(f1, f2)
	elseif iscon(pegtree) then
    	local f1 = first_tree(pegtree.p1, g)
    	if utils.contains_empty(f1) then
    		local f2 = first_tree(pegtree.p2, g)
    		return makecon(f1, f2)
		end
		return f1
	elseif isstar(pegtree) then
		local f1 = first_tree(pegtree, g)
		return makestar(f1)
	elseif islazy(pegtree) then
		local f1 = first_tree(pegtree, g)
		return makelazy(f1)
	elseif ispossv(pegtree) then
		local f1 = first_tree(pegtree, g)
		return makepossv(f1)
   	elseif isand(pegtree) then
   		-- to be discussed
		local f1 = first_tree(pegtree.p1, g)
		return makeand(f1)
   	elseif isnot(pegtree) then
   		-- to be discussed
		local f1 = first_tree(pegtree.p1, g)
		return makenot(f1)
    elseif isplus(pegtree) then
    	return first_tree(pegtree, g)
    elseif isquest(pegtree) then
		local f1 = first_tree(pegtree.p1, g)
		return makequest(f1)
	elseif isvar(pegtree) then
		pegtree = g[pegtree.v]
		return first_tree(pegtree, g)
    end
end

-- returns an lpeg pattern that matches the first set described in ftree
function first(ftree)
	-- table that will hold the resulting first set
	local tb = {peg = lpeg.S(''), any = false, empty = false}
	--local tb = {set = '', any = false, empty = false}

	if ischar(ftree) then
		local char = ftree.v:sub(1,1)  -- gets only the first character
		tb.peg = lpeg.S(char)
		return tb
	elseif isset(ftree) then
    	tb.peg = lpeg.S(ftree.v)
    	return tb
	elseif isrange(ftree) then
		local range = ftree.v1 .. ftree.v2
		tb.peg = lpeg.R(range)
		return tb
    elseif isempty(ftree) then
    	tb.empty = true
        return tb
    elseif isany(ftree) then
    	-- QUESTION: thoughts on using lpeg.P(1) here
    	-- pattern that matches one character
    	tb.peg = lpeg.P(1)
    	tb.any = true
        return tb
    elseif isord(ftree) then
    	local tb1 = first(ftree.p1)
    	local tb2 = first(ftree.p2)

		-- lpeg's ordered choice operator (+) is equivalent to set union if
		-- both operands are character sets
    	tb.peg = tb1.peg + tb2.peg
    	tb.empty = tb1.empty or tb2.empty
    	tb.any = tb1.any or tb2.any
        return tb
    -- special case for the not predicate
	elseif iscon(ftree) and isnot(ftree.p1) then
		local tb1 = first(ftree.p1)
		local tb2 = first(ftree.p2)

		-- pattern that does not match tb1 and then matches tb2
		tb.peg = tb2.peg - tb1.peg
		tb.empty = tb2.empty and not tb1.empty
		tb.any = tb2.any and not tb1.any
		return tb
    elseif iscon(ftree) then
    	tb = first(ftree.p1)
    	if tb.empty then
    		local tb2 = first(ftree.p2)
    		-- again, ordered choice is equivalent to set union
    		tb.peg = tb.peg + tb2.peg
    		tb.empty = tb2.empty
    		tb.any = tb.any or tb2.any
		end
		return tb
	elseif isstar(ftree) or islazy(ftree) or ispossv(ftree) then
		tb = first(ftree.p1)
		tb.empty = true
		return tb
	elseif isand(ftree) then
		-- to be discussed
		tb = first(ftree.p1)
		return tb
   	elseif isnot(ftree) then
   		-- QUESTION: will the fact that ftree.p1 has empty or any affect this?
   		local tb1 = first(ftree.p1)
		tb.peg = lpeg.P(1) - tb1.peg
   		return tb
    elseif isplus(ftree) then
    	tb = first(ftree.p1)
    	return tb
    elseif isquest(ftree) then
    	tb = first(ftree.p1)
    	tb.empty = true
    	return tb
    elseif isopencapt(ftree) or isclosecapt(ftree) then
    	tb.empty = true
    	return tb
    end
end

-- return a table representing the first of a regex's parse tree
-- TODO: delete this method
function first_old(pegtree, g)
	-- table that will hold the resulting first set
	local tb = {set = '', any = false, empty = false}

	if ischar(pegtree) then
		tb.set = pegtree.v:sub(1,1)  -- gets only the first character
		return tb
	elseif isset(pegtree) then
    	tb.set = pegtree.v
    	return tb
	elseif isrange(pegtree) then
		tb.set = utils.expand_range(pegtree.v1, pegtree.v2)
		return tb
    elseif isempty(pegtree) then
    	tb.empty = true
        return tb
    elseif isany(pegtree) then
    	tb.any = true
        return tb
    elseif isord(pegtree) then
    	local tb1 = first(pegtree.p1, g)
    	local tb2 = first(pegtree.p2, g)
    	tb.set = tb1.set .. tb2.set
    	tb.empty = tb1.empty or tb2.empty
    	tb.any = tb1.any or tb2.any
        return tb
    -- special case for the not predicate
    --elseif iscon(pegtree) and isnot(pegtree.p1) then
    	--
    elseif iscon(pegtree) then
    	tb = first(pegtree.p1, g)
    	if tb.empty then
    		local tb2 = first(pegtree.p2, g)
    		tb.set = tb.set .. tb2.set
    		tb.empty = tb2.empty
    		tb.any = tb.any or tb2.any
		end
        return tb
    elseif isstar(pegtree) or islazy(pegtree) or ispossv(pegtree) then
    	tb = first(pegtree.p1, g)
    	tb.empty = true
    	return tb
   	elseif isand(pegtree) then
   		-- to be discussed
   		tb = first(pegtree.p1, g)
   		return tb
   	elseif isnot(pegtree) then
   		-- to be discussed
   		return tb -- empty first set
    elseif isplus(pegtree) then
    	tb = first(pegtree.p1, g)
    	return tb
    elseif isquest(pegtree) then
    	tb = first(pegtree.p1, g)
    	tb.empty = true
    	return tb
    elseif isopencapt(pegtree) or isclosecapt(pegtree) then
    	tb.empty = true
    	return tb
	elseif isvar(pegtree) then
		pegtree = g[pegtree.v]
		return first(pegtree, g)
    end
end

function createpattern(g)
	local p = {}
	-- pairs iterates over all the elements in a table using the function "next",
	-- which does not ensure any order on the traversal
	-- --
	-- ipairs iterates sequencially over integer indices, starting at 1 with
	-- unitary increments until it finds the first nil value in the table
	for k, v in pairs(g) do
		p[k] = makepeg(v)
	end
	p[1] = init
	return lpeg.P(p)
end

