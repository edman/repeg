
pattern {
	p = "[abc]*",
	input = { {"a", 2}, {"bc", 3}, {"abc", 4}, {"dba", 1}, {"abbcd", 5}} 
}

pattern {
	p = "[abc]+",
	input = { {"a", 2}, {"bc", 3}, {"abc", 4}, {"dba", 0}, {"abbcd", 5}} 
}

pattern {
	p = "[^a]* 'b'",
	input = { {"ab", 0}, {"b", 2}, {"cb", 3}, {"sldfcibb", 9}, {"ie djal kob", 0}} 
}

pattern {
	p = "[^ab]* 'b'",
	input = { {"ab", 0}, {"b", 2}, {"cb", 3}, {"sldfcibb", 8}, {"ie djal kob", 0}} 
}

pattern {
	p = "[a][0-9]* / [b][a-z]* / [cd][A-Z]* / [^abcd]'!'",
	input = { {"a012", 5}, {"bpoz", 5}, {"dRGT", 5}, {"f!", 3}, {"8zx", 0}}
}

--]]

