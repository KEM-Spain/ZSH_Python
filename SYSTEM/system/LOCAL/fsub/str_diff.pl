#!/usr/bin/env perl
use String::Diff;
use String::Diff qw( diff_fully diff diff_merge diff_regexp );# export functions

# simple diff
my $before = $ARGV[0];
my $after = $ARGV[1];
my($old, $new) = String::Diff::diff($before, $after);
print "$old|$new";

#my $diff = String::Diff::diff('this is Perl', 'this is Ruby');
#print "$diff->[0]\n";# this is [Perl]
#print "$diff->[1]\n";# this is {Ruby}
#
#my $diff = String::Diff::diff('this is Perl', 'this is Ruby',
#    remove_open => '<del>',
#    remove_close => '</del>',
#    append_open => '<ins>',
#    append_close => '</ins>',
#);
#print "$diff->[0]\n";# this is <del>Perl</del>
#print "$diff->[1]\n";# this is <ins>Ruby</ins>
#
## merged
#my $diff = String::Diff::diff_merge('this is Perl', 'this is Ruby');
#print "$diff\n";# this is [Perl]{Ruby}
#
#my $diff = String::Diff::diff_merge('this is Perl', 'this is Ruby',
#    remove_open => '<del>',
#    remove_close => '</del>',
#    append_open => '<ins>',
#    append_close => '</ins>',
#);
#print "$diff\n";# this is <del>Perl</del><ins>Ruby</ins>
#
## change to default marks
#%String::Diff::DEFAULT_MARKS = (
#    remove_open  => '<del>',
#    remove_close => '</del>',
#    append_open  => '<ins>',
#    append_close => '</ins>',
#    separator    => '&lt;-OLD|NEW-&gt;', # for diff_merge
#);
#
## generated for regexp
#my $diff = String::Diff::diff_regexp('this is Perl', 'this is Ruby');
#print "$diff\n";# this\ is\ (?:Perl|Ruby)
#
## detailed list
#my $diff = String::Diff::diff_fully('this is Perl', 'this is Ruby');
#for my $line (@{ $diff->[0] }) {
#    print "$line->[0]: '$line->[1]'\n";
#}
## u: 'this is '
## -: 'Perl'
#
#for my $line (@{ $diff->[1] }) {
#    print "$line->[0]: '$line->[1]'\n";
#}
## u: 'this is '
## +: 'Ruby'
