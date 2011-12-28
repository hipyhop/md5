#! /usr/bin/perl
use strict;
use warnings;

use Test::More;
require_ok('Digest::MD5');

#Run Tests

test1();
test2();
test3();
test4();

# Test1 - Checks md5 checksum of string 'test' matches known checksum
sub test1
{
    my $testname        = 'Known string md5 as expected';
    my $expected_result = '098f6bcd4621d373cade4e832627b4f6';

    #execute md5.pl with single argument and store output
    my @result = `perl md5.pl test`;

    #Check command executed successfully
    diag("$!\n") if ($? == -1);

    #Scrape only resulting hash
    my $checksum = get_md5_from_string($result[0]);

    #Check checksum is valid
    diag("Invalid checksum") if (!is_checksum($checksum));

    ok($checksum eq $expected_result, $testname);
}

# Test2, writes a-zA-Z0-9 to a file and md5s the contents
sub test2
{
    my $testname        = 'Known file md5 as expected';
    my $expected_result = 'c5721e84f80f551cec9f252473d47ced';

    my $filename = 'all_chars.txt';
    open(my $fh, '>', $filename);

    #Opened file, write test chars to it
    print $fh 'a' .. 'z', "\n";
    print $fh 'A' .. 'Z', "\n";
    print $fh '0' .. '9', "\n";
    close($fh);

    #md5 the file and grab the results;
    my @result = `perl md5.pl -f all_chars.txt`;

    #Check command executed successfully
    diag("$!") if ($? == -1);

    #Scrape only resulting hash
    my $checksum = get_md5_from_string($result[0]);

    #Check checksum is valid
    diag("Invalid Checksum") if (!is_checksum($checksum));

    ok($checksum eq $expected_result, $testname);
    remove_files($filename);
}

# Test 3 - Checks the --output option with no args
sub test3
{
    my $testname = "--output created 'checksums.md5'";
    my $CHECKSUM_FILE = 'checksums.md5';   #Name of auto generated checksum file
    my $CHECKSUM_FILE_SEPERATOR =
      ' => ';    #Char sequence separating filenames and checksums

    #Names of junk files to be testes
    my $junkfile1 = './tmp_junkfile1.jnk';
    my $junkfile2 = './tmp_junkfile2.jnk';

    #Cleanup any pre-existing junk files
    remove_files($CHECKSUM_FILE, $junkfile1, $junkfile2);

    #create the junk files before testing
    make_junk_file($junkfile1, 256);
    make_junk_file($junkfile2, 1024);

    #Check the --output option with no args actually creates a 'checksums.md5' file
    `perl md5.pl --file --output $junkfile1 $junkfile2`;

    #Check command executed successfully
    ok($? != -1, "Output to file successful");

    #Check File exists
    ok(-e $CHECKSUM_FILE, "File Exists");

    #Split 'checksums.md5' into hash of filenames => md5sum
    open my $fh, '<', $CHECKSUM_FILE;
    ok($fh, "File handle opened");
    my %results;
    while (<$fh>)
    {
        chomp;
        if (!/^#/)    #Only check if line does NOT start with #
        {
            my ($filename, $checksum) = split(/$CHECKSUM_FILE_SEPERATOR/);
            $results{$filename} = $checksum;
        }
    }
    close($fh);

    while (my ($fname, $chksum) = each %results)
    {
        ok(md5_file($fname) eq $chksum, "Junk file checksum verified");
    }

    #cleanup files after testing
    remove_files($CHECKSUM_FILE, $junkfile1, $junkfile2);
}

# Test --format option
sub test4
{
    my $testname = 'test --format \'%s:%s\'';
    chomp(my $output = `perl md5.pl --format '%s:%s' test`);
    my $expected = 'test:098f6bcd4621d373cade4e832627b4f6';
    ok($output eq $expected, '--format test 1 passed');
    
    
}

#create a random textfile
sub make_junk_file
{
    my ($filename, $length) = @_;

    if (open(my $fh, '>', $filename))
    {
        my @chars = ('A' .. 'Z', 'a' .. 'z', 0 .. 9, "\n");
        my $contents = '';
        while ($length > 0)
        {
            $contents .= $chars[rand(@chars)];
            $length--;
        }
        print($fh $contents);
        close($fh);
        return 1;
    }
    else
    {
        print "Error creating file $filename: $!\n";
        return 0;
    }
}    #end make_junk_file

#Verify checksum is a valid checksum
sub is_checksum
{
    return $_[0] =~ /[\p{Hex}]{32}/;
}

#Extract MD5 checksum from string, return empty string on fail
sub get_md5_from_string
{
    if ($_[0] =~ /([a-fA-F0-9]{32})/)
    {
        return $1;
    }
    return '';
}

#Attempt to delete all filenames that are passed
sub remove_files
{
    foreach (@_)
    {
        if (open(my $fh, '<', $_))
        {
            unlink $_ or warn "Could not unlink $_ : $!";
        }
    }
}

#Digest a file returning the md5 checksum
sub md5_file
{
    if (open(my $fh, '<', $_[0]))
    {
        return Digest::MD5->new->addfile($fh)->hexdigest;
    }
    else
    {

        #could not read file
        return 0;
    }
}

done_testing();
