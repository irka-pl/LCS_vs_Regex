#! /usr/bin/perl -w

use strict;
use v5.10;
use Data::Dumper;

use LCS; 
use LCS::Regex;

$LCS::Regex::quiet_debug = 0;
my $quiet_debug = 0;
sub debug {
    print STDERR $_[0] // 'undefined' unless $quiet_debug;
}

my $iterations = 1000;

my $search_string = "..some-thing 1 action.."; 
my $output="2020/03/02 08:03:53: ..Type#sme-t\\n2020/03/02 08:03:53: *Mar 2 16:05:22.115: %DIRTY-6-COMMENT_SUBSTRING: Saving Type summary (type-reaction-summary)... Please wait. Do not interrupt.hing 1 action.."; 

say "use_lcs result: ".use_lcs($search_string, $output).";";
say "use_regex_short result: ".use_regex_short($search_string, $output).";";
say "use_regex result: ".use_regex($search_string, $output).";";

$LCS::Regex::quiet_debug = 1;
$quiet_debug = 1;

my $time = time;
for (my $i=0; $i < $iterations; $i++) {
    use_lcs($search_string, $output);
}
say "use_lcs time: ".(time() - $time).";";

$time = time();
for (my $i=0; $i < $iterations; $i++) {
    use_regex($search_string, $output);
}
say "use_regex time: ".(time() - $time).";";

$time = time();
for (my $i=0; $i < $iterations; $i++) {
    use_regex_short($search_string, $output);
}
say "use_regex_short time: ".(time() - $time).";";


sub use_regex {
    my ($needle, $haystack) = @_;
    my $re_str = LCS::Regex::generate_fuzzy_regex($needle);
    my $re = qr{$re_str};
    return 1 if ($haystack =~ $re);
}

sub use_regex_short {
    my ($needle, $haystack) = @_;
    my $re_str = LCS::Regex::generate_fuzzy_regex_short($needle);
    my $re = qr{$re_str};
    return 1 if ($haystack =~ $re);
}

sub use_lcs {
    my ($str1,$str2) = @_;
    my $arr1 = [split "", $str1]; 
    my $arr2 = [split "", $str2];
    my $lcs = LCS->LCS($arr1,$arr2);
    #Smy $clcs = LCS->lcs2clcs($lcs);
    #my $align = LCS->lcs2align($lcs);
    #debug(Dumper($lcs));
    my $slcs = [map {[$arr1->[$_->[0]],$arr2->[$_->[1]] ]} @$lcs];
    #print Dumper ['salign', $salign];
    my($resstr1,$resstr2) = LCS->align2strings($slcs);
    return 1 if ($resstr1 eq $resstr2 && $resstr1 eq $str1);
    #debug(Dumper([$resstr1,$resstr2]));
}


