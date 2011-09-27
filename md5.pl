#!/usr/bin/env perl
use strict;
use warnings;

use 5.010;
use Getopt::Long;
use Digest::MD5;

our $VERSION = 0.12;

#flags
my $verify;
my $recurse;
my $file;
my $output;
my $help;

my $output_file = 'checksums.md5';

GetOptions(
           "verify|v"    => \$verify,
           "recursive|r" => \$recurse,
           "file|f"      => \$file,
           "output|o"    => \$output,
           "help|h"      => \$help,
          ) or die "Error reading arguments\n";

help() && exit 255 if $help;

# Main program
if (scalar @ARGV > 0)
{
    die "--output must be used with --file\n" if ($output && !$file);

    if ($verify)
    {
        verify(@ARGV);
    }
    elsif ($file)
    {
        md5_files(@ARGV);
    }
    else
    {
        md5_strings(@ARGV);
    }
}
else
{
    help();
    exit 255;
}

#Digest multiple strings
sub md5_strings
{
    my @strings = @_;
    my $hasher  = Digest::MD5->new;

    foreach (@strings)
    {
        $hasher->add($_);

        #print hex digest and clear for next $val
        say "$_ => ", $hasher->hexdigest;
    }
    return 1;
}

sub open_output_file
{
    my ($filename) = @_;
    my $OUTH = undef;
    if (-e $filename)
    {
        print "$filename already exists, overwrite? [Y/N] : ";
        chomp(my $response = <STDIN>);
        if ($response =~ /[yY]/)
        {
            open $OUTH, '>', $filename
              or die "Could not open $filename for writing\n";
        }
    }
    return $OUTH;
}

#Digest multiple files
sub md5_files
{
    my @filenames = @_;
    my $hasher    = Digest::MD5->new;

    eval {
        my $OUTH = open_output_file($output_file) if ($output);
        select $OUTH if (defined $OUTH);
    };

    if ($output)
    {
        if (!-e $output_file && open(my $OUTH, '>', $output_file))
        {
            select $OUTH;
            printf(
                "#Checksum file created on %02d/%02d/%02d\n",
                sub { ($_[3], $_[4] + 1, $_[5] + 1900) }
                  ->(localtime)
            );
        }
        else
        {
            warn "Could not open '$output_file' for output: $!\n";
        }
    }

    foreach (@filenames)
    {
        if (-d)
        {
            push @filenames, glob "$_/*" if ($recurse);
            next;
        }

        say "$_ => ", md5_file($_);
    }
    select *STDOUT;
    return 1;
}

sub md5_file
{
    my ($file, $return) = @_;
    if (!open(my $FH, "<", $file))
    {
        $return = "Error opening file";
    }
    else
    {
        $return = Digest::MD5->new->addfile($FH)->hexdigest;
        close $FH;
    }
    return $return;
}

sub verify
{
    my @checksum_files = @_;
    my $seperator      = '=>';
    for my $file (@checksum_files)
    {
        open my $fh, '<', $file;
        while (my $line = <$fh>)
        {
            chomp $line;
            next if ($line =~ /^#/);    #Skip lines with comments

            my ($filename, $checksum) = split /$seperator/, $line;

            $checksum =~ s/ //g;      #Remove any spaces from checksum string
            $filename =~ s/\s*$//;    #Remove any trailing spaces from filename

            print "Checking '$filename' ... ";
            my $result = md5_file($filename);
            say $result eq $checksum
              ? '[OK]'
              : "[FAIL] expected $checksum got $result";
        }
    }
}

sub help
{
    printf << "HELP", $VERSION
File and string checksum MD5 digester / verifier v%f
    $0 [OPTIONS] string1, string2, ...
    $0 -f [-r -o] file1, file2, ...
    $0 -v checksum_file1, [checksum_file2, ...]

Options:
    -f, --file        Digest files instead of strings
    -v, --verify      Verifies checksum file(s) in 'filename => checksum' format
    -r, --recursive   Recurse into directories when using --file
    -o, --output      Outputs checksums to 'checksums.md5', must be used with -f
    -h, --help        Displays this message

HELP
}
