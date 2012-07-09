module ("regex", package.seeall)
local lpeg = require'lpeg'
local compile = require'compile'

-- variaveis utilizadas para numeracao dos
-- nao terminais da peg resultante
local varnumber
local casas
local zeros

local init = 'S'
local tag = compile.gettag()

local makeempty = compile.makeempty
local makechar = compile.makechar
local makeset = compile.makeset
local makeany = compile.makeany
local makevar = compile.makevar
local makecon = compile.makecon
local makeord = compile.makeord
local makestar = compile.makestar
local makeplus = compile.makeplus
local makequest = compile.makequest
--<mod-lazy>
local makelazy = compile.makelazy
--<mod-possv>
local makepossv = compile.makepossv
--<mod-pred>
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

function isset(p)
	return cmpkind(p, tag.set)
end

-- tag.any representa o caractere que casa qualquer outro (".")
function isany(p)
	return cmpkind(p, tag.any)
end

-- quando o nó já tem valor fixo, não possui mais operações (terminal)
--<mod-capture>
local function isterm(p)
	return ischar(p) or isset(p) or isany(p) or isopencapt(p) or isclosecapt(p)
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

--<mod-lazy>
function islazy(p)
	return cmpkind(p, tag.lazy)
end

--<mod-possv>
function ispossv(p)
	return cmpkind(p, tag.possv)
end

--<mod-pred>
function isand(p)
	return cmpkind(p, tag.andp)
end
--<mod-pred>
function isnot(p)
	return cmpkind(p, tag.notp)
end

--<mod-capture>
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

function getOperator(p)
	if isstar(p) then
		return "*"
	elseif isplus(p) then
		return "+"
	elseif isquest(p) then
		return "?"
	elseif islazy(p) then
		return "*?"
	elseif ispossv(p) then
		return "*+"
	elseif isand(p) then
		return "&"
	elseif isnot(p) then
		return "!"
	end
end

-- imprime uma peg dada em forma de árvore
function writepeg (p, incon)
	-- percorre a árvore recursivamente
	if ischar(p) then
		return "'" .. p.v .. "'"
	elseif isset(p) then
		return "[" .. p.v1 .. "-" .. p.v2 .. "]"
	elseif isempty(p) then
		return "''"
	elseif isany(p) then
		return "."
	elseif isord(p) then
		local s1 = writepeg(p.p1, false)
		local s2 = writepeg(p.p2, false)
		if incon then
			return '(' .. s1 .. " / " .. s2 .. ')'
		else
			return s1 .. " / " .. s2
		end
	elseif iscon(p) then
		return writepeg(p.p1, true) .. "" .. writepeg(p.p2, true)
	--<mod-writepeg>
	elseif isrept(p) then
		local s = writepeg(p.p1)
		local op = getOperator(p)
		if isterm(p.p1) or isempty(p.p1) then
			return s .. op
		else
			return "(" .. s .. ")" .. op
		end
	elseif ispred(p) then
		local s = writepeg(p.p1)
		local op = getOperator(p)
		if isterm(p.p1) or isempty(p.p1) then
			return op .. s
		else
			return op .. "(" .. s .. "("
		end
	--<mod-capture>
	elseif isopencapt(p) then
		--return '{' .. p.v
		return '{'
	elseif isclosecapt(p) then
		return '}'
	elseif isvar(p) then
		return p.v
	else
		error("Unknown kind: " .. p.kind)
	end
end

-- dada a peg em forma de árvore, retorna a peg
-- definida em termos da biblioteca lpeg
function makepeg (p)
	if ischar(p) then
		return lpeg.P(p.v)
	elseif isset(p) then
		return lpeg.R(p.v1 .. p.v2)
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
	-- <mod-pred>
	elseif isand(p) then
		return #makepeg(p.p1)
	-- <mod-pred>
	elseif isnot(p) then
		return -makepeg(p.p1)
	--<mod-capture>
	elseif isopencapt(p) then
		return lpeg.Cc('open', p.v) * lpeg.Cp()
	elseif isclosecapt(p) then
		return lpeg.Cc('close') * lpeg.Cp()
	-- quando essa funcao é chamada as tags se referem à sintaxe
	-- de PEGs
	else
		error("Unknown kind: " .. p.kind)
	end
end

-- procura uma posicao qualquer
-- que esteja vazia na tabela g
-- é utilizada para nomear um não-terminal
local function getvar(g)
	local n = 100000
	local v = 'V' .. math.random(n)
	while g[v] do
		v = 'V' .. math.random(n)
	end
	return v
end

--<mod-getnextvar>
local function getnextvar()
	varnumber = varnumber + 1
	if (varnumber == casas) then
		casas = casas * 10
		zeros = zeros:sub(1, #zeros - 1)
	end
	return 'V' .. zeros .. varnumber
end

-- g é a gramatica (peg) a ser utilizada na avaliacao do padrao
-- g é a árvore que representa a PEG final
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
	--<mod-lazy>
	-- e1*?e2 ==> V <- e2 / e1V
	elseif islazy(p) then
		local v = getnextvar()
		g[v] = makeord(k, pi(g, p.p1, makevar(v)))
		return makevar(v)
	--<mod-possv>
	--<mod-pred>
	-- e1*+e2 ==> e1*e2
	elseif ispossv(p) then
		if isempty(k) then
			return makestar(pi(g, p.p1, makeempty()))
		else
			return makecon(makestar(pi(g, p.p1, makeempty())), k)
		end
	--<mod-pred>
	-- pi(&e1, e2) = &pi(e1,"")e2
	elseif isand(p) then
		if isempty(k) then
			return makeand(pi(g, p.p1, makeempty()))
		else
			return makecon(makeand(pi(g, p.p1, makeempty())), k)
		end
	--<mod-pred>
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

--<mod-capturematch>
function capturematch(subject, peg)
	local indices = {}
	local last = {}
	local i = 1
	local capt = lpeg.Ct(peg):match(subject)

	-- return nil if no pattern could be captured in "subject"
	if capt == nil then
		return nil
	end

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
		indices[key] = subject:sub(indices[key].ini, indices[key].fim)
	end
	return indices
end

-- re	--> regular expression described in a string
-- s	--> subject to be mathed by "re"
function match(re, subject)
	varnumber = 0; casas = 10; zeros = "0000";
	local g = {}
	local retree = compile.parse(re)
	g[init] = pi(g, retree, makeempty())
	print("Regex: ", writepeg(retree))
	print("Input: ", subject)
	print("Arvore: " .. ptree(retree)) -----------------------
	print("PEG")
	printpeg(g)
	local peg = createpattern(g)

	-- "retree.capture" is set to true when the pattern has captures
	if retree.capture then
		return capturematch(subject, peg)
	end
	return peg:match(subject)
end

-- search the subject for the first substring  
function find(re, subject)
	--re = '.* (?: ' .. re .. ' )'
	re = '.*? ( ' .. re .. ' )'
	return match(re, subject)
end


-- imprime uma peg dada em forma de árvore
function ptree (p)
	if ischar(p) then
		return "'" .. p.v .. "'"
	elseif isset(p) then
		return "set{" .. p.v1 .. "-" .. p.v2 .. "}"
	elseif isempty(p) then
		--return "''"
		return "empty"
	elseif isany(p) then
		--return "."
		return "any"
	elseif isord(p) then
		local s1 = ptree(p.p1)
		local s2 = ptree(p.p2)
		return "ord{" .. s1 .. ", " .. s2 .. "}"
	elseif iscon(p) then
		local s1 = ptree(p.p1)
		local s2 = ptree(p.p2)
		return "con{" .. s1 .. ", " .. s2 .. "}"
	elseif isstar(p) then
		local s = ptree(p.p1)
		return 'star{' .. s .. '}'
	--<mod-lazy>
	elseif islazy(p) then
		local s = writepeg(p.p1)
		return 'lazy{' .. s .. '}'
	--<mod-possv>
	elseif ispossv(p) then
		local s = ptree(p.p1)
		return "possv{" .. s .. "}"
	--<mod-pred>
	elseif isand(p) then
		local s = ptree(p.p1)
		return 'and{' .. s .. '}'
	--<mod-pred>
	elseif isnot(p) then
		local s = ptree(p.p1)
		return 'not{' .. s .. '}'
	elseif isplus(p) then
		local s = writepeg(p.p1)
		return 'plus{' .. s .. '}'
	elseif isquest(p) then
		local s = writepeg(p.p1)
		return 'quest{' .. s .. '}'
	--<mod-capture>
	elseif isopencapt(p) then
		return 'open_' .. p.v
	elseif isclosecapt(p) then
		return '_close'
	--elseif isvar(p) then
		--return p.v
	else
		error("Unknown kind: " .. p.kind)
	end
end

function createpattern(g)
	local p = {}
	-- o pairs itera sobre todos os elementos da tabela
	-- (utiliza a função next, que não garante ordem alguma)
	-- o ipairs itera sequencialmente sobre indices inteiros,
	-- começando em 1 até o primeiro valor nil
	for k, v in pairs(g) do
		p[k] = makepeg(v)
	end
	p[1] = init
	return lpeg.P(p)
end

function printpeg (g)
	for k, v in pairs(g) do
		print(k, "->", writepeg(v))
	end
end

