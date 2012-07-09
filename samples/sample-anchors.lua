
pattern {
	p = "'a'*$",
	input = { {"aaa", 4}, {"aaaaa", 6}, {"aaab", 0} }
}

pattern {
	p = "'a'*\z",
	input = { {"aaa\n", 4}, {"aaa", 4}, {"aaab", 0}, {"baa", 0} }
}

pattern {
	p = "'a'*\Z",
	input = { {"aaa\n", 4}, {"aaa\naaa", 0}, {"aaa", 4} }
}

pattern {
	p = "'<h>'.*'<h>'$",
	input = { {"<h>teste<h>", 12}, {"<h><h>teste", 0} }
}

pattern {
	p = "'cs'(?:'a'$ / 'b'\z)",
	input = { {"csa", 4}, {"csb", 4}, {"csa\n", 0}, {"csb\n", 4} }
}

pattern {
	p = "'<b>'.*?'</b>'",
	input = { {"<b>parsing</b> expression <b>grammars></b>", 15} }
}

pattern {
	p = "'<b>'.*'</b>'",
	input = { {"<b>parsing</b> expression <b>grammars></b>", 43} }
}


