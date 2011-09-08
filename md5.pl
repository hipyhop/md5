#!/usr/bin/env perl
use strict;
use warnings;

use 5.010;
use Getopt::Long;
use Digest::MD5;

our $VERSION = 0.11;

#flags
my $file; 
my $output;
my $verify;
my $help;

my $output_file = 'checksums.md5';

GetOptions(
           "verify|v" => \$verify,
           "file|f"   => \$file,
           "output|o" => \$output,
           "help|h" => \$help,
          ) or die "Error reading arguments\n";

help() && exit 255 if $help;

# Main program
if (@ARGV > 0)
{
    die "--output must be used with --file\n" if ($output && !$file);

    if($verify)
    {
        verify(@ARGV)
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

#Digest multiple files
sub md5_files
{
    my @filenames = @_;
    my $hasher    = Digest::MD5->new;

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
    my $seperator = '=>';
    while(my $line = <>)
    {
       chomp $line;
       next if($line =~ /^#/); #Skip lines with comments

       my ($filename, $checksum) = split $line, $seperator;

       $checksum =~ s/ //g; #Remove any spaces from checksum string
       $filename =~ s/(.+) *$/$1/; #Remove any trailing spaces from filename


       say $line;
    }
}

sub help
{
    printf << "HELP", $VERSION 
File and string checksum MD5 digester / verifier v%f
    $0 [OPTIONS] string1, string2, ...
    $0 -f [-o] file1, file2, ...
    $0 -v checksum_file1, [checksum_file2, ...]

Options:
    -f, --file        Digest files instead of strings
    -v, --verify      Verifies checksum file(s) in 'filename => checksum' format
    -o, --output      Outputs checksums to 'checksums.md5', must be used with -f
    -h, --help        Displays this message

HELP
}
