
pattern {
	find = true,
	p = "'a'(?:'b'/'c')'d'",
	input = { {"zzzzzzabd", {"abd"}} }
}

pattern {
	find = true,
	p = "[0-9]+",
	input = { {"this string has 28 characters", {"28"}} }
}

