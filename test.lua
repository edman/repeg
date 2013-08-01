require 'regex'

-- return the size of a table
function tablesize(t)
	local size = 0;
	for _ in pairs(t) do size = size + 1; end
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

-- return true if the table "gotten" contains the same elements
-- in the same order as the table "expected"
function correctresult(expected, gotten)
    return writetable(expected) == writetable(gotten)
end

-- recursively parse a table into a string format
function writetable(t)
	-- if t is a literal, just print it
    if type(t) ~= 'table' then
        if t == '' then return "''" end
        return '' .. t
    end

	-- otherwise, t is a table
	local s = "{"
	local first = true
	for _, key in ipairs(getkeys(t)) do
        local toadd = writetable(t[key])

        if not first then
            toadd = ', ' .. toadd
        end

        s = s .. toadd
		first = false
	end

	return s .. "}"
end

-- prints error message
function errormessage(input, expected, gotten)
	return ("For input " .. input .. " the expected result was " .. expected .. " but we got " .. gotten)
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
	-- the function we are going to test, match or find
	local isfind = v.find

	-- let's try to match several inputs
	for _, vin in ipairs (v.input) do
		local s = vin[1]  -- the subject 
		local res = vin[2]  -- the expected result
		local n = true -- the result of the match
		local erro = false

		if isfind then
			n = regex.find(v.p, s)
		else
			n = regex.match(v.p, s)
		end

        -- if the match returns nil, assign 0 or {} to n
		if n == nil then
			if type(res) == 'number' then
				n = 0
			elseif type(res) == 'table' then
				n = {}
			end
		end

        -- compare the expected result with what we got from regex.match()
		if (type(res) == 'table') then
			erro = not correctresult(res, n)
            -- get the string representation of res and n
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

