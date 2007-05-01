#!/usr/bin/perl -0777 -nl

use strict;

# the first part is a duplication of colorterm-to-html.pl which I
# wrote for my Munich talk:

s!\&!\&amp;!g;
s!"!&quot;!g;
s!<!&lt;!g;
s!>!&gt;!g;
s!\e\[1;3[45](?:;\d+)?m(.*?)\e\[0m!<span style="color: blue">$1</span>!sg;
s!\e\[1;31(?:;\d+)?m(.*?)\e\[0m!<span style="color: red">$1</span>!sg;
#s!\n!<br/>\n!g;
s!\r\n!\n!g;
s!.+\r!!g;




=pod

lines like

  CPAN.pm: Going to build (A/AB/ABH/XML-RSS-1.22.tar.gz)

can occur once or twice. The latter means dependencies get in the way
and between the first and second occurrence there are the dependencies.

$1 is the distro.

=cut

my @distros = /^  CPAN\.pm: Going to build (.*)/mg;
my %S; map { $S{$_}++; "$S{$_}: $_\n" } @distros;

=pod

From the second occurrence (or if there is only one, from the first)
until the consecutive two lines

  /^$HTMLSPANSTUFF {2}(.+)\n$HTMLSPANSTUFF {2}.+install.+\s+--\s(NOT )?OK$/

we expect the data for exactly this distro. $1 is again the distro.

=cut

BEGIN { our $HTMLSPANSTUFF = qr/(?:<[^<>]+>)*/; }
for my $d (@distros) {
  pos($_) = 0;
  if ($S{$d} == 2) {
    m/^  CPAN\.pm: Going to build $d/gc;
    warn sprintf "FOUND FIRSTMATCH %s at %d", $d, pos $_;
  }
  my $shortdistro = $d;
  $shortdistro =~ s!^[A-Z]/[A-Z][A-Z]/!!;
  our $HTMLSPANSTUFF;
  if (s/(\G[\s\S]+)(^  CPAN\.pm: Going to build $d\n[\s\S]*\n^$HTMLSPANSTUFF {2}($shortdistro)\n$HTMLSPANSTUFF {2}.+\s+--\s+(NOT\s)?OK\n)/$1/m) {
    warn sprintf "FOUND: %s (%d;%d)", $d, $S{$d}, length($2);
  } else {
    warn "not found: $d ($S{$d})";
  }
}

=pod

This is the data we want to gather:

	distribution            MIYAGAWA/XML-Atom-1.2.3.tar.gz
	perl                    /home/src/perl/..../perl              !reveals maint vs perl
	logfile (=date)         megainstall.20070422T1717.out
	ok                      OK or "make_test NO" or something
	log_as_xml

So if we take the input filename, s/.out/.d/ on it and make that a
directory, we have the storage area and the first metadata. If we then
write a file "perl" with the path to perl, we have the second metadata
thing. We should really store the output of '$perl -V' there, just in
case.

If we then use the distroname and replace slashes with bangs, we have
a good flat filename. We could then even s|!.+!|!| for the filename if
we keep the original distroname for inside. We could write

  <distro time="$time" perl="$perl_path" distro="$distro_orig">
  $report
  </distro>

and of course, we must escape properly.


=cut

