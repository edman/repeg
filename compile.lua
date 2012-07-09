module ("compile", package.seeall)

local m = require "lpeg"

--[[
-- sintaxe lpeg
local lpeg = require 'lpeg'
 any = lpeg.P(1)				--> pattern that matches one character
 space = lpeg.S(" \t\n")		--> set with the given characters
 lower = lpeg.R("az")			--> range of [a-z]
 upper = lpeg.R("AZ")			--> range of [A-Z]
 letter = lower + upper			--> '+' denotes ordered choice
 								--> '*' denotes concatenation
 test = lpeg.P("casa")
 np = 1 - lpeg.S("()")
 temp = "(" * np^0 * ")"
 --par = temp + ("(" * np^0 * temp * np^0 * ")")
 par = lpeg.P{
	 'par',
	 par = "(" * ( lpeg.V("np") + lpeg.V('par') )^0 * ")",
	 np = 1 - lpeg.S("()")
 }
print(test:match("casmento"))
print(par:match("(abriu um (oops) () () (()) (() () ()) e fechou)"))
print(par:match("((a b) c)"))
print(letter:match("a"))
--]]

local S = m.S" \t"^0
local endline = m.P'\n'
local name = m.R("az", "AZ") * m.R("az", "AZ", "09")^0

local regrammar
local tree
local start = 'pattern'

-- each capture has an identifier
local captureid;


-- constant values to represent the type of a node
local tag = { empty = 'empty', char = 'char', range = 'range',
		set = 'set', any = 'any', con = 'con', ord = 'ord', var = 'var',
		star = 'star', plus = 'plus', quest = 'quest',
		lazy = 'lazy', possv = 'possv', andp = 'andp',
		notp = 'notp', opencapt = 'opencapt', closecapt = 'closecapt'}

function parse(s)
	-- regrammar is an object, the call 'regrammar:match(s)' is sugar for
	-- 'regrammar.match(regrammar, s)'
	tree = {}
	captureid = 0;
	regrammar:match(s)

	-- flag to indicate if the pattern has captures
	tree[start].capture = captureid > 0
	return tree[start]
end

function gettag()
	return tag
end

local function pattern(body)
	tree[start] = body
end

-- create a node in the tree for terminals and non-terminals
function makev(k, v1, v2)
	if not v2 then
		return { kind=k, v=v1 }
	end
	return { kind=k, v1=v1, v2=v2 }
end

-- create a node with the tag k
-- p2 may not exist (as when k is tag.star), in which caseA we look only at
-- no.p1
function makep(k, p1, p2)
	return { kind=k, p1=p1, p2=p2 }
end

function makevar(v)
	return makev(tag.var, v)
end

function makechar(v)
	return makev(tag.char, v)
end

function makeany()
	return makev(tag.any, nil)
end

function makeempty()
	return makev(tag.empty, nil)
end

function makerange(v1, v2)
	return makev(tag.range, v1, v2)
end

function makeset(v)
	return makev(tag.set, v)
end

function makenot(p1)
	return makep(tag.notp, p1)
end

function makeand(p1)
	return makep(tag.andp, p1)
end

function makeplus(p1)
	return makep(tag.plus, p1)
end

function makestar(p1)
	return makep(tag.star, p1)
end

function makequest(p1)
	return makep(tag.quest, p1)
end

function makeord(p1, p2)
	return makep(tag.ord, p1, p2)
end

function makecon(p1, p2)
	return makep(tag.con, p1, p2)
end

function makelazy(p1)
	return makep(tag.lazy, p1)
end

function makepossv(p1)
	return makep(tag.possv, p1)
end

-- repete exatamente n1
function makerept1(p1, n1)
	p = p1
	for i = 2, n1 do
		p = makecon(p, p1)
	end
	return p
end

-- repete n1 ou mais
function makerept2(p1, n1)
	p = makerept1(p1, n1)
	return makecon(p, makestar(p1))
end

-- repetes between n1 and n2 time, inclusive
function makerept3(p1, n1, n2)
	p = makerept1(p1, n1);
	s = makeord(p1, makeempty())
	for i = n1+2, n2 do
		s = makeord(makecon(p1, s), makeempty())
	end
	return makecon(p, s)
end

function makedollar()
	return makenot(makeany())
end
function makeendline()
	return makeord(makeand(makechar("\n")), makedollar())
end
function makelineeof()
	return makeand(makecon(makequest(makechar("\n")), makedollar()))
end

function makeopencapt()
	captureid = captureid + 1
	return makev(tag.opencapt, captureid)
end
function makeclosecapt()
	return makev(tag.closecapt)
end
function makecapture (p1)
	return makecon(makecon(makeopencapt(), p1), makeclosecapt())
end

-- start		--> string containing 'pattern'
-- S			--> matches the set of spaces or tabs, lpeg.S(" \t")^0
-- endline		--> matches end-of-line, lpeg.P("\n")
regrammar = m.P {
	start
	, pattern
		= S * m.V("ord") / pattern * S * (endline + -1)
	, ord
		= (m.V("con") * S * '/' * S * m.V("ord")) / makeord
		+ m.V("con")
	, con
		= (m.V("pred") * S *  m.V("con")) / makecon
		+ m.V ("pred")
	, pred
		= ("?!" * S * m.V("rep")) / makenot
		+ ("?=" * S * m.V("rep")) / makeand
		+ m.V("rep")
	, rep
		= (m.V("elem") * "+") / makeplus
		+ (m.V("elem") * "*?") / makelazy
		+ (m.V("elem") * "*+") / makepossv
		+ (m.V("elem") * "*") / makestar
		+ (m.V("elem") * "?" * -m.S("!=")) / makequest
		+ (m.V("elem") * "{" * m.V("digits") * "}") / makerept1
		+ (m.V("elem") * "{" * m.V("digits") * ",}") / makerept2
		+ (m.V("elem") * "{" * m.V("digits") * "," * m.V("digits") * "}") / makerept3
		+ m.V("elem")
	, elem
		= m.V("char") / makechar
		+ m.V("empty") / makeempty
		+ m.V("any") / makeany
		+ m.V("range") / makerange
		+ m.V("set") / makeset
		+ ('(?:' * S * m.V("ord") * S * ')')
		+ ('(' * -m.P("?:") * S * m.V("ord") * S * ')') / makecapture
		+ m.P("$") / makedollar
		+ m.P("\z") / makeendline
		+ m.P("\Z") / makelineeof
	-- -- -- -- -- -- -- -- -- -- -- -- --
	--, char = "'" * m.C((m.P(1) - m.P("'"))^1) * "'"
	, char = "'" * m.C(m.P(m.P(1) - m.P("'"))^1) * "'"
	, range = "[" * m.C(m.P(1)) * '-' * m.C(m.P(1)) * "]"
	, set = "[" * m.C(m.P(m.P(1) - m.P("]"))^1) * "]"
	, any = lpeg.P(".")
	, empty = m.P"'" * m.P"'"
	, digit = m.C(m.R("09"))
	, digits = m.C(m.R("09")^1)
}



