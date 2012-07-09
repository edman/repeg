pattern {
	p = "(?:'a' / 'a''b') 'c'",
	input = { {"a", 0}, {"ac", 3}, {"abc", 4}, {"ab", 0}, {"c", 0}} 
}

pattern {
	p = "(?:'' / 'a''b' / 'a') 'c'",
	input = { {"a", 0}, {"ac", 3}, {"abc", 4}, {"ab", 0}, {"c", 2}} 
}

pattern {
	p = "'a'*'a' / 'b'",
	input = { {"a", 2}, {"ac", 2}, {"abc", 2}, {"aa", 3}, {"c", 0}} 
}

pattern {
	p = "'a'*[a-z]* / 'b'",
	input = { {"a", 2}, {"ac", 3}, {"abc", 4}, {"aa", 3}, {"c", 2}} 
}

pattern {
	p = "[a-z].",
	input = { {"a", 0}, {"ac", 3}, {"a9z", 3}, {"9az", 0}, {"c", 0}} 
}

pattern {
	p = "[a-z]+",
	input = { {"a", 2}, {"", 0}, {"a9z", 2}, {"9az", 0}, {"ccb", 4}} 
}

pattern {
	p = "'a'?[a-e]?",
	input = { {"a", 2}, {"", 1}, {"af", 2}, {"e", 2}, {"aeb", 3}} 
}

--
pattern {
	p = "'aa'",
	input = { {"aa", 3} }
}

pattern {
	p = "'tes'",
	input = { {'tes"te', 4} }
}

--]]

