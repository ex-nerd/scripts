#!/usr/bin/perl -w

my $odd  = shift @ARGV;
my $even = shift @ARGV;
my $pdf  = shift @ARGV;

die "need 3 args\n" unless ($odd && $even && $pdf);

die "incorrect formated odd param:  $odd\n"   unless ($odd  =~ s/(_\d+)(_\d+)?\.jpg$/$1/);
die "incorrect formated even param:  $even\n" unless ($even =~ s/(_\d+)(_\d+)?\.jpg$/$1/);

print "Odd:  $odd\nEven: $even\n";

my @odd_pages  = sort by_scan_num <$odd*>;
my @even_pages = reverse sort by_scan_num <$even*>;

die "mismatch page count\n" unless (scalar(@odd_pages) == scalar(@even_pages));

print join(', ', @even_pages), "\n",
      join(', ', @odd_pages), "\n";

my @pages = ();
while (@odd_pages && @even_pages) {
    my $p1 = shift @odd_pages;
    my $p2 = shift @even_pages;
    push @pages, $p1, $p2;
}

#my $x = 1;
#foreach my $page (@pages) {
#    print "$page -> $pdf-".sprintf('%03d', $x), "\n";
#    $x++;
#}

die "No pages built\n" unless (scalar(@pages) >= 2);

$cmd = 'convert -quality 60 -define pdf:use-trimbox=true ' . join(' ', map { shell_escape($_) } @pages) . ' ' . shell_escape("$pdf.pdf");
#print "command:  $cmd\n";
system($cmd);


# Sort by the trailing number the scanner generages
    sub by_scan_num {
        my ($n1) = ($a =~ /_(\d+)\.jpg$/);
        my ($n2) = ($a =~ /_(\d+)\.jpg$/);
        $n1 ||= 0;
        $n2 ||= 0;
        return $n1 <=> $n2;
    }

# Escape a parameter for safe use in a commandline call
    sub shell_escape {
        $str = shift;
        $str =~ s/'/'\\''/sg;
        return "'$str'";
    }
