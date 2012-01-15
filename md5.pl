#!/usr/bin/env perl
use strict;
use warnings;

use 5.010;
use Getopt::Long;
use Digest::MD5;

our $VERSION = 0.16;

run();

sub run
{
    my $settings = get_settings();

    help() if (defined $$settings{help});

    my $in_list;
    if (scalar(@ARGV))
    {
        $in_list = \@ARGV;
    }
    else
    {
        $in_list = \*STDIN;
    }

    if (defined $in_list)
    {
        my $handle =
          $$settings{output}
          ? open_output_file($$settings{out_file})
          : undef;

        my $printer = build_printer($$settings{format}, $handle);

        if ($$settings{verify})
        {
            verify($in_list);
        }
        elsif ($$settings{file})
        {
            md5_files($in_list, $printer, $$settings{recursive});
        }
        else
        {
            md5_strings($in_list, $printer);
        }
    }
    else
    {
        help();
        exit 1;
    }
}

## @method HashRef get_settings()
# Parse the command line arguments into a settings hash
# @return A Hash Reference containing the parsed arguments
sub get_settings
{
    my $settings = {};
    GetOptions($settings, 'verify|v', 'recursive|r', 'file|f', 'output|o',
               'out_file:s', 'format:s', 'help|h',)
      or die "Error reading arguments\n";
    $$settings{out_file} = 'checksums.md5' unless defined $$settings{out_file};
    return $settings;
}

## @method md5_string ( mixed strings, CodeRef printer)
# Digests the strings from the first parameter and prints them using the printer->() code ref
# @param strings An ArrayRef of strings to be digested OR a file GLOB to read strings from
# @param printer A code reference that takes two arguments( string/filename, MD5Hash) and prints output
sub md5_strings
{
    my ($strings, $printer) = @_;
    my $hasher = Digest::MD5->new;

    my $runner = sub {
        my ($str) = @_;
        $hasher->add($str);
        $printer->($str, $hasher->hexdigest);
    };

    if (ref $strings eq 'ARRAY')
    {
        foreach (@{$strings})
        {
            $runner->($_);
        }
    }
    elsif (ref $strings eq 'GLOB')
    {
        while (<$strings>)
        {
            chomp;
            $runner->($_);
        }
    }
}

## @method open_output_file( String filename, Boolean overwrite )
# Opens a write only filehandle to the given filename. If the file exists will prompt for specified action if not defined
# @param filename Filename to open
# @param overwrite Set true to overwrite, false to not overwrite or undef to prompt
# @return A write only filehandle to the output file
sub open_output_file
{
    my ($filename, $overwrite) = @_;
    my $OUTH = undef;

    my $file_exist = -e $filename;
    if ($file_exist)
    {
        unless (defined $overwrite)
        {
            print "$filename already exists, overwrite? [Y/N] : ";
            chomp(my $response = <STDIN>);
            $overwrite = 1 if ($response =~ /^y/i);
        }
    }

    if (!$file_exist || $overwrite)
    {
        eval {
            open $OUTH, '>', $filename
              or die "Could not open $filename for writing\n";
        };
        print STDERR
          "Could not open $filename for writing, Printing to stdout instead: $@"
          if $@;
    }
    return $OUTH;
}

## @method void md5_files( mixed filesnames, CodeRef printer, Boolean recurse )
# Takes a list of filenames and computes the MD5 checksums and passes them to
# the printer Code reference.
# @param filenames An Array reference to an array of filesnames OR a file Glob containing a filename on each line, relative or absolute.
# @param printer [NOT undef] A code reference that takes 2 arguments, the filename and the MD5 checksum
# @param recurse [Optional] If true will recurse into any directories passed as filenames
sub md5_files
{
    my ($filenames, $printer, $recurse) = @_;
    my $hasher = Digest::MD5->new();

    my $runner = sub {
        my ($filename) = @_;
        $printer->($filename, md5_file($filename));
    };

    if (ref $filenames eq 'ARRAY')
    {
        for (@{$filenames})
        {
            if (-d)
            {
                push @{$filenames}, glob "$_/*" if $recurse;
                next;
            }
            $runner->($_);
        }
    }
    elsif (ref $filenames eq 'GLOB')
    {
        while (<$filenames>)
        {
            chomp;
            if (-d)
            {
                md5_files([$_], $printer, $recurse) if $recurse;
                next;
            }
            $runner->($_);
        }
    }
}

## @method String md5_file( String filename )
# Computes the MD5 Checksum of the supplied filename
# @param filename [NOT undef] The filename to read
# @return MD5 checksum of the filename or an error message
sub md5_file
{
    my ($file, $return) = @_;
    if (!open(my $FH, "<", $file))
    {
        $return = "!!! Error opening file !!!";
    }
    else
    {
        $return = Digest::MD5->new->addfile($FH)->hexdigest;
        close $FH;
    }
    return $return;
}

## @method verify( ArrayRef filenames );
# Verifies the checksums found in a file. Currently only supports file format 'filename => checksum'.
# @param filenames A list of filenames to read filename/checksum pairs from and verify 
sub verify
{
    my ($checksum_files) = @_;
    my $seperator = '=>';
    for my $file (@$checksum_files)
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

## @method CodeRef build_print( String format, FileHandle handle)
# Builds a printer function using the optional printf style format
# and outputs to the optional filehandle
# @param format [Optional] A printf style format which will have a newline
#                          appened to it, Default: %s => %s
# @param handle [Optional] A filehandle to output to, Default: STDOUT
# @return a CodeRef that will print formatted input to the specified output
sub build_printer
{
    my ($format, $handle) = @_;
    $handle = *STDOUT unless defined $handle;
    my $printer;
    if ($format)
    {
        $printer = sub { printf $handle "$format\n", @_ };
    }
    else
    {
        $printer = sub { say $handle "$_[0] => $_[1]" };
    }
    return $printer;
}

## @method void help()
# Prints help text
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
        --out-file    The filename to output the results to
        --format      Printf style custom format that takes two string arguments,
                      the string/filename and the checksum. A new line will be 
                      added to the format string

    -h, --help        Displays this message

HELP
}
