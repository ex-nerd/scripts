#!/usr/bin/perl -w
#
#  show_rpm_macros.pl
#
#    Show the values of the macros that rpm knows
#

# Variables
    our $raw = 0;

# Get options
    use Getopt::Long;
    GetOptions('raw' => \$raw,
              );

# Pull out some info we will need from rpm
    my %rpmrc;
    foreach my $line (split(/\n(?=\S)/, `rpm --showrc`)) {
        next unless ($line =~ /^-\d+:\s+([\w\-]+)\s+(.+)$/s);
        $rpmrc{$1} = $2;
    }

# Not running in raw mode
    if (!$raw) {
    # Fill in any easy-to-parse macros
        my $done     = 0;
        my $overload = 0;
        until ($done || ++$overload > 50) {
            my $count = 0;
            foreach my $key (keys %rpmrc) {
                $count += $rpmrc{$key} =~ s/(\%\{([\w\-]+)\})/if ($rpmrc{$2}) { $rpmrc{$2} } else { --$count;  $1 }/sge;
            }
            $done = 1 if ($count == 0);
        }
        $done = $overload = 0;
        until ($done || ++$overload > 50) {
            my $count = 0;
            foreach my $key (keys %rpmrc) {
                $count += $rpmrc{$key} =~ s/\%\{\?([\w\-]+)\s*:\s*(.+?)\}/$rpmrc{$1} ? $2 : ''/sge;
                $count += $rpmrc{$key} =~ s/\%\{!\?([\w\-]+)\s*:\s*(.+?)\}/$rpmrc{$1} ? '' : $2/sge;
            }
            $done = 1 if ($count == 0);
        }
    }

# Print the macros out
    foreach my $key (sort keys %rpmrc) {
        print "\%$key:\n    $rpmrc{$key}\n";
    }

