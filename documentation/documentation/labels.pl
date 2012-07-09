# LaTeX2HTML 2008 (1.71)
# Associate labels original text with physical files.


$key = q/sec:introduction/;
$external_labels{$key} = "$URL/" . q|node1.html|; 
$noresave{$key} = "$nosave";

$key = q/tab:syntax/;
$external_labels{$key} = "$URL/" . q|node1.html|; 
$noresave{$key} = "$nosave";

$key = q/sec:examples/;
$external_labels{$key} = "$URL/" . q|node5.html|; 
$noresave{$key} = "$nosave";

$key = q/sec:functions/;
$external_labels{$key} = "$URL/" . q|node2.html|; 
$noresave{$key} = "$nosave";

1;


# LaTeX2HTML 2008 (1.71)
# labels from external_latex_labels array.


$key = q/sec:introduction/;
$external_latex_labels{$key} = q|1|; 
$noresave{$key} = "$nosave";

$key = q/tab:syntax/;
$external_latex_labels{$key} = q|1|; 
$noresave{$key} = "$nosave";

$key = q/sec:examples/;
$external_latex_labels{$key} = q|3|; 
$noresave{$key} = "$nosave";

$key = q/sec:functions/;
$external_latex_labels{$key} = q|2|; 
$noresave{$key} = "$nosave";

1;

