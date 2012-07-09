require 'regex'

-- TODO find a better way of getting the size of a table
-- return the size of a table
function tablesize(t)
	local size = 0;
	for k in pairs(t) do
		size = size + 1;
	end
	return size;
end

-- return a table with the sorted keys of "t"
function getkeys(t)
	-- get all the keys of "t" in the table "index"
	local index = {}
	for key in pairs(t) do table.insert(index, key) end
	-- sort and return "index"
	table.sort(index)

	return index
end

-- return true if the table "gotten" contains the same
-- elements in the same order as "result"
function correctresult(result, gotten)
	if #result ~= tablesize(gotten) then
		return false
	end

	-- "i" is the index for the table 'result'
	-- "key" is the index for the table 'gotten'
	i = 1
	for _, key in ipairs(getkeys(gotten)) do
		if result[i] ~= gotten[key] then
			return false
		end
		i = i + 1
	end
	return true
end

-- returns the table concatenating its elements in a string
function writetable(t)
	if tablesize(t) == 0 then
		return "{}"
	end

	local s = ""
	local first = true
	for _, key in ipairs(getkeys(t)) do
		if first then
			if t[key] == '' then
				s = "{''"
			else
				s = "{" .. t[key]
			end
		else
			if t[key] == '' then
				s = s .. ", ''"
			else
				s = s .. ", " .. t[key]
			end
		end
		first = false
	end

	return s .. "}"
end

-- imprime mensagem de erro 
function errormessage(input, expected, got)
	return ("For input " .. input .. " the expected result was " .. expected .. " but we got " .. got)
end

local t = {}
function pattern(e) 
	table.insert (t, e)	
end

local input = ({...})[1] or "sample.lua"
local f, e = loadfile(input)


if f then f() else error (e) end

-- for every regex in table t
for _, v in ipairs(t) do
	-- let's try to match several inputs
	for _, vin in ipairs (v.input) do
		local s = vin[1]  -- the subject 
		local res = vin[2]  -- the expected result
		local n = regex.match(v.p, s) -- the result of the match
		local erro = false

		-- se o match retornar nil, atribui 0 ou {}
		if n == nil then
			if type(res) == 'number' then
				n = 0
			elseif type(res) == 'table' then
				n = {}
			end
		end

		-- comparacao dos resultados esperado e obtido
		if (type(res) == 'table') then
			--erro = not comparetables(res, n)
			erro = not correctresult(res, n)
			-- transforma res e n em uma string para a mensagem de erro
			res = writetable(res)
			n = writetable(n)
		elseif (type(res) == 'number') and (res ~= n) then
			erro = true
		end

		print('Res = ', n)
		assert (not erro, errormessage(s, res, n))
		print("")
	end
	print("")
end


