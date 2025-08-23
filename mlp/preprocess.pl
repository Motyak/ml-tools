#!/usr/bin/env perl
use strict;
use warnings;
use feature "state";
use constant true => 1;
use constant false => 0;
use constant _ => undef;
binmode(STDOUT, ":utf8");

my $file = shift @ARGV;

my @INCLUDE_PATH = (
    ".",
);

# 1 define @INCLUDE_PATH, init as empty
# 2 parse -I args and add them to @INCLUDE_PATH
# 3 if @INCLUDE_PATH is empty, add "."

sub rjust {
    my ($str, $width) = @_;
    $width =~ /[0-9]+/ or die;
    return sprintf("%${width}s", $str);
}

sub ml_comment {
    my ($msg) = @_;
    my $ML_COMMENT_WIDTH = 80;
    $msg = "=== mlp: ${msg} ===";
    no warnings "numeric"; # when `x` op rhs is negative => same as 0
    my $comment = "\"" . $msg . "=" x ($ML_COMMENT_WIDTH - 2 - length($msg)) . "\"";
    return $comment;
}

sub search_file {
    my ($dirs, $file) = @_;

    foreach my $dir (@$dirs) {
        my $file = "${dir}/${file}";
        if (-f $file) {
            return $file;
        }
    }

    return undef; # not found
}

sub OPEN_FILE_ERR {
    my ($file, $open_err) = @_;
    print STDERR "Could not open file `$file`: $open_err\n";
    exit 1;
}

sub INCLUDE_ERR {
    my ($file, $line, $linenb) = @_;

    my $include = substr $line, 9, -1;
    my $err_msg = "${file}:$.:10: ERR: no include path in which to search for `${include}`\n";
    $err_msg .= rjust("$linenb", 5) . " | " . $line . "\n";
    $err_msg .= " " x 5 . " | " . " " x 9 . "^\n";
    print STDERR $err_msg;

    exit 1;
}

sub preprocess {
    my ($file) = @_;
    state %files = ();
    state $rec_call = 0;
    my $in_package_main = false;
    my $res = "";
    my $module_main = "";

    unless ($rec_call) {
        %files = ($file => _);
    }

    open my $fh, "<:encoding(UTF-8)", $file or OPEN_FILE_ERR($file, $!);
    while (my $line = <$fh>) {
        chomp $line;

        if ($line =~ /^include <(\S+)>$/) {
            my $included_file = search_file(\@INCLUDE_PATH, $1) or INCLUDE_ERR($file, $line, $.);
            next if exists $files{$included_file};
            $files{$included_file} = _;

            {
                my $msg = "BEGIN $included_file";
                my $comment = ml_comment($msg);
                $res .= "${comment}\n\n";
            }

            $rec_call++;
            $res .= preprocess($included_file);
            $rec_call--;

            my $msg = "END $included_file";
            if ($rec_call) {
                $msg .= " (back to $file)";
            }
            else {
                $msg .= " (finally back to $file)";
            }
            my $comment = ml_comment($msg);
            $res .= "${comment}\n";
        }

        elsif ($line =~ /^package main$/) {
            $in_package_main = true;
        }

        elsif ($in_package_main) {
            $module_main .= "$line\n";
        }

        else {
            $res .= "$line\n";
        }

        ; # no logic outside ifs
    }
    close $fh;

    unless ($rec_call) {
        $res .= $module_main;
    }

    return $res;
}

unless (caller) {
    my $res = preprocess($file);
    print($res);
}
