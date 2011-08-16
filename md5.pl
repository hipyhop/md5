#!/usr/bin/env perl
use strict;
use warnings;

use v5.10;
use Getopt::Long;
use Digest::MD5;

#Determine if digesting files or strings
my $file   = 0;
my $output = '';
GetOptions(
           "file|f"   => \$file,
           "output|o" => \$output
          ) or die("Error reading arguments");

#Digest multiple strings
sub md5_string
{
  my $hasher = Digest::MD5->new;

  foreach (@_)
  {
    $hasher->add($_);

    #print hex digest and clear for next $val
    say "$_ => ", $hasher->hexdigest;
  }
}

#Digest multiple files
sub md5_file
{
  my $hasher = Digest::MD5->new;

  if ($output)
  {
    if (open(my $fh, '>', 'checksums.md5'))
    {
      select $fh;
      printf(
        "#Checksum file created on %02d/%02d/%02d\n",
        sub { ($_[3], $_[4] + 1, $_[5] + 1900) }
          ->(localtime)
      );
    }
    else
    {
      warn "Could not open 'checksums.md5' for output\n";
    }
  }

  foreach (@_)
  {
    if (!open(my $file, "<", $_))
    {
      say "$_ => Error opening file";
    }
    else
    {
      $hasher->addfile($file);

      #print hex digest and clear for next $val
      say "$_ => ", $hasher->hexdigest;
    }
  }
  select *STDOUT;
}

if (@ARGV > 0)
{
  if ($output && !$file)
  {
    die "--output must be used with --file";
  }

  if ($file)
  {
    md5_file(@ARGV);
  }
  else
  {
    md5_string(@ARGV);
  }
}
else
{
  die "Usage: $0 string OR $0 -f filename\n";
}
