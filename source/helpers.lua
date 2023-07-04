function shuffle(tbl)
	for i = #tbl, 2, -1 do
		local j = math.random(i)
		
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
	
	return tbl
end

function each(tbl, fn)
	local result = {}
	
  for i, v in pairs(tbl) do
    result[i] = fn(v)
  end
	
	return result
end

function generate(count, fn)
	local result = {}
	
  for i = 1, count do
    result[i] = fn(i)
  end
	
	return result
end

function any(tbl, fn)
	local result = false
	
  for i, v in pairs(tbl) do
		if fn(v) then result = true end
  end
	
	return result
end

function all(tbl, fn)
	local result = true
	
  for i, v in pairs(tbl) do
		if not fn(v) then result = false end
  end
	
	return result
end