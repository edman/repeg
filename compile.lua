module ("compile", package.seeall)

local m = require "lpeg"

--[[
-- sintaxe lpeg
local lpeg = require 'lpeg'
 any = lpeg.P(1)				--> padrão que aceita um caracter
 space = lpeg.S(" \t\n")		--> conjunto com os caracteres dados
 lower = lpeg.R("az")			--> range contendo [a-z]
 upper = lpeg.R("AZ")			--> range contendo [A-Z]
 letter = lower + upper			--> '+' é escolha ordenada
 								--> '*' denota concatenação
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

--<mod-capture>
local captureid;


-- valores constantes para representar o tipo de um nó
local tag = { empty = 'empty', char = 'char', set = 'set',
		any = 'any', con = 'con', ord = 'ord', var = 'var',
		star = 'star', plus = 'plus', quest = 'quest',
		lazy = 'lazy', possv = 'possv', andp = 'andp',
		notp = 'notp', opencapt = 'opencapt', closecapt = 'closecapt'}
		--<mod-lazy><mod-possv><mod-pred><mod-capture>

function parse(s)
	-- regrammar é um objeto, a chamada 'regrammar:match(s)'
	-- é o mesmo que 'regramar.match(regrammar, s)'
	tree = {}
	captureid = 0;
	regrammar:match(s)
	--<mod-capture>
	-- flag para indicar se o padrao possui capturas
	tree[start].capture = captureid > 0
	return tree[start]
end

function gettag()
	return tag
end

local function pattern(body)
	tree[start] = body
end

-- makev cria um nó para terminais e nao-terminais
function makev(k, v1, v2)
	if not v2 then
		return { kind=k, v=v1 }
	end
	return { kind=k, v1=v1, v2=v2 }
end

-- cria um novo nó com a tag k
-- p2 pode nem sempre existir, como quando k é tag.star
-- nesse caso, olhamos apenas para no.p1
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

function makeset(v1, v2)
	return makev(tag.set, v1, v2)
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

--<mod-lazy>
function makelazy(p1)
	return makep(tag.lazy, p1)
end

--<mod-possv>
function makepossv(p1)
	return makep(tag.possv, p1)
end

--<mod-rept>
-- repete exatamente n1
function makerept1(p1, n1)
	p = p1
	for i = 2, n1 do
		p = makecon(p, p1)
	end
	return p
end

--<mod-rept>
-- repete n1 ou mais
function makerept2(p1, n1)
	p = makerept1(p1, n1)
	return makecon(p, makestar(p1))
end

--<mod-rept>
-- repete entre n1 e n2, inclusive
function makerept3(p1, n1, n2)
	p = makerept1(p1, n1);
	s = makeord(p1, makeempty())
	for i = n1+2, n2 do
		s = makeord(makecon(p1, s), makeempty())
	end
	return makecon(p, s)
end

--<mod-anchor>
function makedollar()
	return makenot(makeany())
end
--<mod-anchor>
function makeendline()
	return makeord(makeand(makechar("\n")), makedollar())
end
--<mod-anchor>
function makelineeof()
	return makeand(makecon(makequest(makechar("\n")), makedollar()))
end

--<mod-capture>
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

-- start		--> string contendo 'pattern'
-- S			--> casa conjunto contendo espaços ou tabs lpeg.S(" \t")^0
-- endline		--> casa quebra de linha, lpeg.P('\n')
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
		--<mod-pred>
		= ("?!" * S * m.V("rep")) / makenot
		+ ("?=" * S * m.V("rep")) / makeand
		+ m.V("rep")
	, rep
		= (m.V("elem") * "+") / makeplus
		--<mod-lazy>
		+ (m.V("elem") * "*?") / makelazy
		--<mod-possv>
		+ (m.V("elem") * "*+") / makepossv
		+ (m.V("elem") * "*") / makestar
		--+ (m.V("elem") * "?") / makequest
		+ (m.V("elem") * "?" * -m.S("!=")) / makequest
		--<mod-rept>
		+ (m.V("elem") * "{" * m.V("digits") * "}") / makerept1
		+ (m.V("elem") * "{" * m.V("digits") * ",}") / makerept2
		+ (m.V("elem") * "{" * m.V("digits") * "," * m.V("digits") * "}") / makerept3
		+ m.V("elem")
	, elem
		= m.V("char") / makechar
		+ m.V("empty") / makeempty
		+ m.V("any") / makeany
		+ m.V("set") / makeset
		--<mod-capture>
		+ ('(?:' * S * m.V("ord") * S * ')')
		+ ('(' * -m.P("?:") * S * m.V("ord") * S * ')') / makecapture
		--<mod-anchor>
		+ m.P("$") / makedollar
		+ m.P("\z") / makeendline
		+ m.P("\Z") / makelineeof
	-- -- -- -- -- -- -- -- -- -- -- -- --
	--, char = "'" * m.C((m.P(1) - m.P("'"))^1) * "'"
	, char = "'" * m.C(m.P(m.P(1) - m.P("'"))^1) * "'"
	, set = "[" * m.C(m.P(1)) * '-' * m.C(m.P(1)) * "]"
	, any = lpeg.P(".")
	, empty = m.P"'" * m.P"'"
	--<mod-rept>
	, digit = m.C(m.R("09"))
	, digits = m.C(m.R("09")^1)
}



