
pattern {
	find = true,
	p = "'a'(?:'b'/'c')'d'*",
	input = {
        {"zzzzzzzzzabdd", {{10, 13}}}, {"abd", {{1, 3}}}, {"acd", {{1, 3}}}
    }
}

pattern {
	find = true,
	p = "[0-9]+",
	input = { {"this string has 28 characters", {{17, 18}}} }
}

