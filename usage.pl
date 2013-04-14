#!/usr/bin/perl
use strictures 1;
use v5.14;
use Jass::SyntaxHighlighter;
use File::Slurp;

my $filename = "blizzard";
my $jass_text = read_file("./input/$filename.j", binmode => ':encoding(UTF-8)');
Jass::SyntaxHighlighter::colorize(\$jass_text);

my $output = <<"OUTPUT";
<!DOCTYPE html>

<html>

<head>
    <meta charset="UTF-8">

    <link href="../css/reset.css" type="text/css" rel="stylesheet" />
    <link href="../css/jass.css" type="text/css" rel="stylesheet" />

    <title>$filename.j</title>
</head>

<body>
<pre>$jass_text</pre>
</body>

</html>
OUTPUT

chomp $output;
open my $file, '>', "./output/$filename.html" or die "$!";
print { $file } $output;
close $file;
