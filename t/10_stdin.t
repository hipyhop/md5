#! /usr/bin/perl
use strict;
use warnings;

use Test::More;
use TestUtils;

#Run Tests

test1();
test2();

# Test1 - Checksum of string from STDIN matches known checksum
sub test1 {
    my $testname        = 'String checksum from STDIN as expected';
    my $expected_result = '098f6bcd4621d373cade4e832627b4f6';

    #execute md5.pl with single argument and store output
    my @result = `echo test | perl md5.pl -`;

    #Check command executed successfully
    diag("$!\n") if ( $? == -1 );

    #Scrape only resulting hash
    my $checksum = get_md5_from_string( $result[0] );

    #Check checksum is valid
    diag("Invalid checksum") if ( !is_checksum($checksum) );

    ok( $checksum eq $expected_result, $testname );
}

# Test2, writes a-zA-Z0-9 to a file and feeds the filename via STDIN
sub test2 {
    my $testname        = 'Known file md5 as expected';
    my $expected_result = 'c5721e84f80f551cec9f252473d47ced';

    my $dir = tempdir( CLEANUP => 1 );
    my $filename = catfile( $dir, 'all_chars.txt' );
    open( my $fh, '>', $filename );

    #Opened file, write test chars to it
    print $fh 'a' .. 'z', "\n";
    print $fh 'A' .. 'Z', "\n";
    print $fh '0' .. '9', "\n";
    close($fh);

    #md5 the file and grab the results;
    my @result = `echo $filename | perl md5.pl -f -`;

    #Check command executed successfully
    diag("$!") if ( $? == -1 );

    #Scrape only resulting hash
    my $checksum = get_md5_from_string( $result[0] );

    #Check checksum is valid
    diag("Invalid Checksum") if ( !is_checksum($checksum) );

    ok( $checksum eq $expected_result, $testname );
}

done_testing();
