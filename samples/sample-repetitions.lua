
pattern {
	p = "'a'{2}", -- pattern
	input = { {"a", 0}, {"aa", 3}, {"aaab", 3}, {"baa", 0} } -- subject
}

pattern {
	p = "'ts'{3,}",
	input = { {"tststs", 7}, {"tstststststststststs", 21}, {"ts", 0} }
}

pattern {
	p = "'bl'{2,3}",
	input = { {"bl", 0}, {"blblbl", 7}, {"blblblblbl", 7} }
}

pattern {
	p = "'a' (?:'b' / 'c'{3})",
	input = { {"ab", 3}, {"acb", 0}, {"accc", 5} }
}


