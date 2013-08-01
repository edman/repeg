
pattern {
	p = "'a'(?:'b'/'c')'d'",
	input = { {"abd", 4} }
}
pattern {
	p = "( 'a' (?: 'b' 'd' / 'c' / '' ) ) 'd'",
	input = { {"ad", {{1, 1}}}, {"abdd", {{1, 3}}}, {"acd", {{1, 2}}} }
}

--[[
pattern {
	p = "( 'a' ('b' 'd' / 'c' / '' ) ) 'd'",
	input = { {"ad", {"", "a"}}, {"abdd", {"bd", "abd"}}, {"acd", {"c", "ac"}} }
}

pattern {
	p = "('a' 'b')",
	input = { {"ab", {"ab"}}, {"abc", {"ab"}}, {"bab", {}} }
}

pattern {
	p = "('a' 'b' 'c' / '')",
	input = { {"abc", {'abc'}}, {"abd", {""}}, {"", {''}}, {"abcd", {"abc"}} }
}

pattern {
	p = "('a' ('b'*) ('c'))",
	input = { {"abbc", {"bb", "c", "abbc"}}, {"ac", {"", "c", "ac"}} }
}

pattern {
	p = "'a' ('b'*) ('c')",
	input = { {"abbc", {"bb", "c"}}, {"ac", {"", "c"}} }
}

pattern {
	p = "('b'?) ('c')",
	input = { {"bc", {"b", "c"}}, {"c", {"", "c"}} }
}

pattern {
	p = "('b') / ('c')",
	input = { {"c", {"c"}} }
}

pattern {
	p = "('b')* ('c')",
	input = { {"c", {"c"}}, {"bbbbc", {"b", "c"}} }
}

pattern {
	p = "('b')? ('c')",
	input = { {"bc", {"b", "c"}}, {"c", {"c"}} }
}


pattern {
	p = "'a' ('b')* ('c')",
	input = { {"abbc", {"b", "c"}}, {"ac", {"c"}} }
}

pattern {
	p = "('a' ('b')* ('c'))",
	input = { {"abbc", {"b", "c", "abbc"}}, {"ac", {"c", "ac"}} }
}

pattern {
	p = "(?: ([0-9]) / [a-z] )*",
	input = { {"123abc456", {6} } } 
}
--]]


