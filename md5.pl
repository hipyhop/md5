#!/usr/bin/env perl
use strict;
use warnings;

use 5.010;
use Getopt::Long;
use Digest::MD5;

#Determine if digesting files or strings
my $file   = 0;
my $output = '';

GetOptions(
           "file|f"   => \$file,
           "output|o" => \$output
          ) or die "Error reading arguments\n";

# Main program
if (@ARGV > 0)
{
  die "--output must be used with --file\n" if($output && !$file);

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

#Digest multiple strings
sub md5_string
{
  my @strings = @_;
  my $hasher = Digest::MD5->new;

  foreach (@strings)
  {
    $hasher->add($_);

    #print hex digest and clear for next $val
    say "$_ => ", $hasher->hexdigest;
  }
  return 1;
}

#Digest multiple files
sub md5_file
{
  my @filenames = @_;
  my $hasher = Digest::MD5->new;

  if ($output)
  {
    if (open(my $OUTH, '>', 'checksums.md5'))
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
      warn "Could not open 'checksums.md5' for output\n";
    }
  }

  foreach (@filenames)
  {
    if (!open(my $FH, "<", $_))
    {
      say "$_ => Error opening file";
    }
    else
    {
      $hasher->addfile($FH);
      close $FH;

      #print hex digest and clear for next $val
      say "$_ => ", $hasher->hexdigest;
    }
  }
  close $OUTH
  select *STDOUT;
  return 1;
}
