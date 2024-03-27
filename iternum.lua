--[[

iternum: the ULTIMATE!!! number library

infinity is in its number form
undefined outputs give nan
nan is not properly handled yet

uses iterated function notation

representation:
{..., {a_2, b_2, ...}, {a_1, b_1, ...}, n} = ...|a_2 b_2 ...|a_1 b_1 ...|n
evaluates right to left
1 1|n is 2^n
a ...|n is 1 ...| repeated a times then n
(c 1's) 1 1|n is (c 1's) n+2|0
(c 1's) 1 b ...|n is (c 1's) n+2 b-1 ...|0 where b > 1

normalisation:
n is stored as normal numbers, ...|n is stored as tables
new functions are added iff the lower one reaches 2^53
(1 1|2^53 -> 2 1|53, 2^53 1|1 -> 1 2|1 1|53)
function magnitudes must be ordered from greatest to least
more than 5 functions get cut off (stored as infinity in table)
(1 6|1 5|1 4|1 3|1 2|(1 1|53 to 2^53-1 1|2^53-1) -> 1 6|1 5|1 4|1 3|1 2|...)

]]--

local module = {}

maxFuncs = 5

function name(a)
	local str
	for _, v in a do
		str =
			(str and str .. "|" or "") ..
			(type(v) == "table" and table.concat(v, " ") or
				(v == math.huge and "..." or v))
	end
	return str
end

function addmt(a)
	setmetatable(a, {__tostring = name})
	return a
end

function copy(a)
	if type(a) == "number" then return a end
	local aCopy = addmt(table.clone(a))
	for i, v in aCopy do
		if type(v) == "number" then continue end
		aCopy[i] = table.clone(v)
	end
	return aCopy
end

function funcCompare(a, b)
	if #a > #b then return 1 end
	if #b > #a then return -1 end
	for i = #a, 1, -1 do
		local ai, bi = a[i], b[i]
		if ai > bi then return 1 end
		if bi > ai then return -1 end
	end
	return 0
end

--only gives a comparison if a or b is a number, treating a table as greater
--returns 1 if a > b, 0 if a = b and -1 if a < b
function numCompare(a, b)
	if type(a) == "number" then
		if type(b) == "number" then
			return math.sign(a - b)
		else
			return a == math.huge and 1 or -1
		end
	elseif type(b) == "number" then
		return b == math.huge and -1 or 1
	end
end

--returns 1 if a > b, 0 if a = b and -1 if a < b
function compare(a, b)
	local numComp = numCompare(a, b)
	if numComp then return numComp end
	for i = 1, math.min(#a, #b) do
		local ai, bi = a[i], b[i]
		local numComp = numCompare(ai, bi)
		if numComp then return numComp end
		local funcComp = funcCompare(ai, bi)
		if funcComp ~= 0 then return funcComp end
	end
	if #a > #b then return 1 end
	if #b > #a then return -1 end
	return 0
end

--only sorts normal numbers
--returns the pair sorted greatest to least
function normSort(a, b)
	local comp = math.sign(a - b)
	if comp > -1 then
		return a, b
	else
		return b, a
	end
end

--returns the pair sorted greatest to least
function sort(a, b)
	local comp = compare(a, b)
	if comp > -1 then
		return a, b
	else
		return b, a
	end
end

--WARNING - has no checks
--only uses normal numbers (cant overflow)
--log(exp(a) + exp(b)) where a > b
function smp(a, b)
	return a + math.log(1 + 2^(b - a), 2)
end

--WARNING - has no checks
--only uses normal numbers (cant overflow)
--log(exp(a) - exp(b)) where a > b
function smn(a, b)
	return a + math.log(1 - 2^(b - a), 2)
end

function neg(a)
	if type(a) == "number" then
		a = -a
		return a >= 2^53 and addmt({{1, 1}, math.log(a, 2)}) or a
	end
	return #a[1] == 2 and a[1][2] == 1 and a[1][1] == 1 and -2^a[2] or -math.huge
end

function abs(a)
	return type(a) == "number" and a < 0 and neg(a) or a
end

function inv(a)
	if type(a) == "number" then
		if a <= 0 then return 1 / a end
		if 1 / a >= 53 then return addmt({{1, 1}, -math.log(a, 2)}) end
		return 1 / a
	end
	return #a[1] == 2 and a[1][2] == 1 and a[1][1] == 1 and 2^-a[2] or 0
end

--WARNING - mutates input
--2^a
function exp(a)
	if a == math.huge or type(a) == "table" and (#a[1] > 2 or a[1][2] > 1) then
		return a
	end
	if type(a) == "number" then
		local res = 2^a
		if res < 2^53 then
			return res
		end
		a = addmt({{0, 1}, a})
	end
	a[1][1] += 1
	if a[1][1] >= 2^53 then
		a = addmt({1, 2}, a[1][1])
	end
	return a
end

--WARNING - mutates input
--log2(a)
function log(a)
	if type(a) == "table" and (#a[1] > 2 or a[1][2] > 1) then
		return a
	end
	if type(a) == "number" then
		return math.log(a, 2)
	elseif a[1][1] == 1 then
		return a[2]
	else
		a[1][1] -= 1
		return a
	end
end

function magCompare(a, b)
	if #a > #b then return 1 end
	if #b > #a then return -1 end
	for i = #a, 2, -1 do
		local ai, bi = a[i], b[i]
		if ai > bi then return 1 end
		if bi > ai then return -1 end
	end
	return 0
end

function addIterfunc(a, iterfunc)
	local cutoff = false
	for i, v in iterfunc do
		if i == 1 then continue end
		if v <= 2^53 then continue end
		cutoff = true
		break
	end
	local magComp = a[1] == math.huge and 1 or magCompare(iterfunc, a[1])
	if magComp == 1 then
		table.insert(a, 1, iterfunc)
		if #a == maxFuncs + 2 then
			table.remove(a, (#a - 1))
			a[#a] = math.huge
		end
		return a
	end
	if cutoff then return a end
	if magComp == 0 then
		local iter = a[1][1] + iterfunc[1]
		if iter == math.huge then
			iterfunc[1] = 1
			iterfunc[2] += 1
			a = addmt({iterfunc, {1, 1}, smp(log(a[1][1]), log(iterfunc[1]))})
		elseif iter > 2^53 then
			iterfunc[1] = iter
			a = addmt({iterfunc, 0})
		else
			a[1][1] = iter
		end
		return a
	end
	if magComp == -1 then
		local nextFunc = table.clone(iterfunc)
		nextFunc[1] = 1
		nextFunc[2] += 1
		if compare({nextFunc, {2, 1}, 1024}, a) == 1 then
			a[3] = smp(a[3], log(iterfunc[1]))
		end
		return a
	end
end

function absSort(a, b)
	local comp = compare(abs(a), abs(b))
	if comp > -1 then
		return a, b
	else
		return b, a
	end
end

function module.max(a, b)
	return compare(a, b) > -1 and copy(a) or copy(b)
end

function module.min(a, b)
	return compare(a, b) < 1 and copy(a) or copy(b)
end

function module.gt(a, b)
	return compare(a, b) == 1
end

function module.gte(a, b)
	return compare(a, b) > -1
end

function module.eq(a, b)
	return compare(a, b) == 0
end

function module.neq(a, b)
	return compare(a, b) ~= 0
end

function module.lte(a, b)
	return compare(a, b) < 1
end

function module.lt(a, b)
	return compare(a, b) == -1
end

function module.add(a, b)
	local a, b = sort(copy(a), copy(b))
	--handle infinities
	if a == math.huge or b == -math.huge then
		return a == math.huge and (b == -math.huge and a + b or a) or b
	end
	--handle too large numbers
	if type(a) == "table" and (#a[1] > 2 or a[1][2] > 1 or a[1][1] > 1) then
		return a
	end
	--handle small input and outputs
	if type(a) == "number" then
		local sum = a + b
		if sum < 2^53 then
			return sum
		end
	end
	local a, b = absSort(a, b)
	local sign = type(a) == "number" and a < 0 and -1 or 1
	if sign == -1 then
		a, b = neg(a), neg(b)
	end
	local mode = type(b) == "number" and b < 0 and -1 or 1
	if mode == -1 then b = -b end
	a = exp((mode == -1 and smn or smp)(log(a), log(b)))
	return sign == -1 and neg(a) or a
end

function module.sub(a, b)
	local a, b = copy(a), copy(b)
	local max, min = sort(a, b)
	--handle infinities
	if max == math.huge or min == -math.huge then
		return type(a) == "number" and (type(b) == "number" and a - b or a) or b
	end
	--handle too large numbers
	if type(max) == "table" and
		(#max[1] > 2 or max[1][2] > 1 or max[1][1] > 1) then
		local comp = compare(a, b)
		return comp == -1 and -math.huge or comp == 0 and 0 or a
	end
	--handle small input and outputs
	if type(max) == "number" then
		local res = a - b
		if res < 2^53 then
			return res
		end
	end
	local comp = compare(abs(a), abs(b))
	if comp == -1 then
		a, b = b, a
	end
	local sign = type(a) == "number" and a < 0 and -1 or 1
	if sign == -1 then
		a, b = neg(a), neg(b)
	end
	local mode = type(b) == "number" and b < 0 and -1 or 1
	if mode == -1 then
		b = -b
	end
	a = exp((mode == -1 and smp or smn)(log(a), log(b)))
	return sign * comp == -1 and neg(a) or a
end

function module.neg(a)
	return neg(a)
end

function module.mul(a, b)
	local a, b = sort(copy(a), copy(b))
	--handle infinities
	if a == math.huge or b == -math.huge then
		return type(a) == "number" and (type(b) == "number" and a * b or a) or b
	end
	--handle small input and outputs
	if type(a) == "number" and a ~= math.huge then
		local prod = a * b
		if prod < 2^53 then
			return prod
		end
	end
	local sign = type(b) == "number" and b < 0 and -1 or 1
	if sign == -1 then b = -b end
	a = exp(module.add(log(a), log(b)))
	return sign == 1 and neg(a) or a
end

function module.div(a, b)
	local a, b = copy(a), copy(b)
	local max, min = sort(a, b)
	--handle small input and outputs
	if type(max) == "number" and max ~= math.huge then
		local quot = a / b
		if quot < 2^53 then
			return quot
		end
	end
	local sign = 1
	if type(a) == "number" and a < 0 then
		sign, a = -sign, -a
	end
	if type(b) == "number" and b < 0 then
		sign, b = -sign, -b
	end
	a = exp(module.sub(log(a), log(b)))
	return sign == -1 and neg(a) or a
end

function module.inv(a)
	return inv(a)
end

function module.pow(a, b)
	local a, b = copy(a), copy(b)
	local max, min = sort(a, b)
	--handle small input and outputs
	if type(max) == "number" and max ~= math.huge then
		local res = a^b
		if res < 2^53 then
			return res
		end
	end
	return exp(module.mul(log(a), b))
end

function module.exp(a, b)
	return module.pow(b or math.exp(1), a)
end

function module.root(a, b)
	local a, b = copy(a), copy(b or 2)
	local max, min = sort(a, b)
	--handle small input and outputs
	if type(max) == "number" and max ~= math.huge then
		local res = a^(1 / b)
		if res < 2^53 then
			return res
		end
	end
	return exp(module.div(log(a), b))
end

function module.log(a, b)
	local a, b = copy(a), copy(b or math.exp(1))
	local max, min = sort(a, b)
	--handle small input and outputs
	if type(max) == "number" and max ~= math.huge then
		local res = math.log(a, b)
		if res < 2^53 then
			return res
		end
	end
	return module.div(log(a), log(b))
end

--negative and real values for c not included
--negative and real values for a and b not included at c >= 4 (tetration)
function module.hyp(a, b, c)
	local a, b, c = copy(a), copy(b), copy(c)
	if type(c) == "number" and c ~= math.huge and (c < 0 or c % 1 ~= 0) then
		return 0/0
	end
	if c == 0 then return module.add(1, b) end
	if c == 1 then return module.add(a, b) end
	if c == 2 then return module.mul(a, b) end
	if c == 3 then return module.pow(a, b) end
	if type(b) == "number" and b ~= math.huge and (b < 0 or b % 1 ~= 0) then
		return 0/0
	end
	if b == 0 then return 1 end
	if b == 1 then return a end
	if type(a) == "number" and a ~= math.huge and (a < 0 or a % 1 ~= 0) then
		return 0/0
	end
	if a == 0 then
		return type(b) == "number" and b ~= math.huge and (b + 1) % 2 or 1
	end
	if a == 1 then return 1 end
	if type(c) == "table" then
		return addIterfunc(c, {1, 1, 1})
	end
	if c == math.huge then return math.huge end
	if type(b) == "table" then
		return addIterfunc(b, {1, c - 2})
	end
	if b == math.huge then return math.huge end
	if type(a) == "table" then
		return addIterfunc(a, {b - 1, c - 3})
	end
	if a == math.huge then return math.huge end
	if b == 2 then
		if a == 2 then return 4 end
		b, c = a, c - 1
		if c == 3 then return module.pow(a, b) end
	end
	local tower = {{c, 1}, b}
	while #tower > 1 and type(tower[#tower]) == "number" do
		local top = tower[#tower - 1]
		local tip = tower[#tower]
		if #tower == maxFuncs + 2 and tip == 1 then
			if top[2] >= 3 and top[1] >= (a == 2 and 5 or 4) then
				table.remove(tower, (#tower - 1))
				tower[#tower] = math.huge
				break
			end
		end
		if top[1] == 3 then
			tower[#tower] = module.pow(a, tip)
			local iter = top[2] - 1
			if iter == 0 then
				table.remove(tower, (#tower - 1))
			else
				top[2] = iter
			end
		else
			local newIter = tip == 1 and a or tip
			local iter = top[2] - (tip == 1 and 2 or 1)
			if iter == 0 then
				table.remove(tower, (#tower - 1))
			else
				top[2] = iter
			end
			if a == 2 and newIter == 2 then
				tower[#tower] = 4
			else
				table.insert(tower, (#tower), {top[1] - 1, newIter})
				tower[#tower] = 1
			end
		end
	end
	local tip = tower[#tower]
	local res =
		tip == math.huge and addmt({tip}) or
		type(tip) == "number" and tip or addmt(tip)
	if type(res) == "number" or #tower == 1 then return res end
	for i = #tower - 1, 1, -1 do
		local v = tower[i]
		v[1], v[2] = v[2], v[1] - 2
		addIterfunc(res, v)
	end
	return res
end

function module.g(a)
	local a = copy(a)
	if type(a) == "number" and a ~= math.huge and (a < 1 or a % 1 ~= 0) then
		return 0/0
	end
	if type(a) == "number" then
		local res = module.hyp(3, 3, 6)
		if a > 1 then
			res = addIterfunc(res, {a - 1, 1, 1})
		end
		return res
	end
	return addIterfunc(a, {1, 2, 1})
end

return module
