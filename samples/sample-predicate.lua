
pattern {
	p = ".* '<' (?:[a-z] / '/')*+ '>'",
	input = { {"<html> blablabla <color bg=#ffffff> </html>", 44} }
}

pattern {
	p = ".*? '<' (?:[a-z] / '/')* '>'",
	input = { {"<html> blablabla <color bg=#111111> </html>", 7} }
}

pattern {
	p = "'a' / ?='b'",
	input = { {"a", 2}, {"b", 1} }
}

pattern {
	p = "'a' ?='b'",
	input = { {"ab", 2} }
}

pattern {
	p = "'am' ?!'b'",
	input = { {"am", 3}, {"b", 0} }
}

pattern {
	p = "?!'b'",
	input = { {"b", 0} }
}

pattern {
	p = "'a' ?![a-z]",
	input = { {"ab", 0}, {"aha", 0}, {"a?!", 2} }
}

pattern {
	p = ".*'e o fim' ?=.",
	input = { {"isso nao e o fim pois continua", 17}, {"isso e o fim", 0} }
}

pattern {
	p = "'a' (?:'b' 'c' / 'd' 'e') (?:'f' 'g' / 'h' 'i')",
	input = { {"abcfg", 6}, {"adefg", 6}, {"abchi", 6}, {"adefg", 6}, {"adehi", 6} }
}

-- dá erro nesse teste
pattern {
	p = "'caro' (?:'ab' ?='cc' / 'ab'?!.) (?:?='cc' / ?!.)",
	input = { {"caroabcccc", 7}, {"caro, esse nao vai", 0}, {"caroabccasa", 7} }
}

pattern {
	p = ".* 'minha' ?=' casa'",
	input = { {"essa e minha casa", 13}, {"disse minha casca e sim minha casa", 30}, {"minha nossa", 0} }
}

