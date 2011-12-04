#!/usr/bin/env perl
use strict;
use warnings;

use 5.010;
use Getopt::Long;
use Digest::MD5;

our $VERSION = 0.14;

# TODO: Update build_printer to produce code that takes an output filehandle, defaults to STDOUT(04/12/2011)

run();

sub build_printer
{
    my ($format, $handle) = @_;
    $handle = *STDOUT unless defined $handle;
    my $printer = sub { printf $handle "$format\n", @_ };
    return $printer;
}

sub run
{
    my $settings = get_settings();
    if (defined $$settings{output} && !defined $$settings{file})
    {
        die "--output must be used with --file\n";
    }

    help() if (defined $$settings{help});

    if (@ARGV)
    {

        #TODO: Swap this for build_printer once complete
        my $format = $settings->{format};
        my $printer =
          $format
          ? sub { printf "$format\n", $_[0], $_[1] }
          : sub { say "$_[0] => $_[1]" };

        if ($$settings{verify})
        {
            verify(@ARGV);
        }
        elsif ($$settings{file})
        {
            md5_files(\@ARGV, $printer, $$settings{recursive},
                      $$settings{output}, $$settings{output_file});
        }
        else
        {
            md5_strings(\@ARGV, $printer);
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
    GetOptions(
               $settings,  'verify|v', 'recursive|r', 'file|f',
               'output|o', 'format:s', 'help|h',
              ) or die "Error reading arguments\n";
    $$settings{output_file} = 'checksums.md5';
    return $settings;
}

## @method md5_string ( ArrayRef strings, CodeRef printer)
# Prints 'string => checksum' for each string in the array reference passed
# @param strings Strings to be digested
# @param printer A code reference that takes two arguments( string/filename, MD5Hash) and prints output
sub md5_strings
{
    my ($strings, $printer) = @_;
    my $hasher = Digest::MD5->new;

    foreach (@{$strings})
    {
        $hasher->add($_);
        $printer->($_, $hasher->hexdigest);
    }
    return 1;
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
        print
          "Could not open $filename for writing, Printing to stdout instead: $@"
          if $@;
    }

    return $OUTH;
}

#Digest multiple files
sub md5_files
{
    my ($filenames, $printer, $recurse, $output, $output_file) = @_;
    my $hasher = Digest::MD5->new();

    if ($output)
    {
        my $OUTH = open_output_file($output_file);
        if (defined $OUTH)
        {
            select $OUTH;
            printf(
                "#Checksum file created on %02d/%02d/%02d\n",
                sub { ($_[3], $_[4] + 1, $_[5] + 1900) }
                  ->(localtime)
            );
        }
    }

    for (@{$filenames})
    {
        if (-d)
        {
            push @{$filenames}, glob "$_/*" if ($recurse);
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
