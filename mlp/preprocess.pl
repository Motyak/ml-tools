#!/usr/bin/env perl
use strict;
use warnings;
binmode(STDOUT, ":utf8");

my $filename = shift @ARGV;

my @INCLUDE_PATH = (
    "../ml-std/include",
);

sub rjust {
    my ($str, $width) = @_;
    return sprintf("%${width}s", $str);
}

sub search_file {
    my ($dirs, $filename) = @_;

    foreach my $dir (@$dirs) {
        my $file = "${dir}/${filename}";
        if (-f $file) {
            return $file;
        }
    }

    return undef; # not found
}

sub INCLUDE_ERR {
    my ($filename, $line, $linenb) = @_;

    my $include = substr $line, 9, -1;
    my $err_msg = "${filename}:$.:10: ERR: no include path in which to search for `${include}`\n";
    $err_msg .= rjust("$linenb", 5) . " | " . $line . "\n";
    $err_msg .= " " x 5 . " | " . " " x 9 . "^\n";
    print STDERR $err_msg;

    exit 1;
}

sub preprocess {
    my ($filename) = @_;
    my $res = "";

    open my $fh, "<:encoding(UTF-8)", $filename or die "Could not open file `$filename`: $!"; # TODO: better err reporting
    while (my $line = <$fh>) {
        chomp $line;

        if ($line =~ /^include <(\S+)>$/) {
            my $filename = search_file(\@INCLUDE_PATH, $1) or INCLUDE_ERR($filename, $line, $.);
            $res .= preprocess($filename);
        }

        else {
            $res .= "$line\n";
        }
    }
    close $fh;

    return $res;
}

unless (caller) {
    my $res = preprocess($filename);
    print($res);
}
