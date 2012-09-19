#! /usr/bin/perl
use strict;
use warnings;

use Test::More;
use TestUtils;
require_ok('Digest::MD5');

#Run Tests

test1();
test2();

# Test 1 - test the checksum of a file whose name contains spaces.
sub test1 {
    my $testname        = 'checksum file name contains spaces';
    my $expected_result = 'c5721e84f80f551cec9f252473d47ced';

    my $dir = tempdir( CLEANUP => 1 );

    my $filename = catfile( $dir, 'all chars spaces.txt' );
    open( my $fh, '>', $filename );

    #Opened file, write test chars to it
    print $fh 'a' .. 'z', "\n";
    print $fh 'A' .. 'Z', "\n";
    print $fh '0' .. '9', "\n";
    close($fh);

    #md5 the file and grab the results;
    my @result = `perl md5.pl -f "$filename"`;

    #Check command executed successfully
    diag($!) if ( $? == -1 );

    #Scrape only resulting hash
    my $checksum = get_md5_from_string( $result[0] );

    #Check checksum is valid
    diag("Invalid Checksum") if ( !is_checksum($checksum) );

    ok( $checksum eq $expected_result, $testname );
}

# Test 2 - test the checksum of a file nested in directories containing spaces.
sub test2 {
    my $testname = 'correctly recurse into directory name containing spaces';
    my $expected_result = 'c5721e84f80f551cec9f252473d47ced';

    my $dir = tempdir( CLEANUP => 1 );

    my $dir_name = catfile( $dir, 'dir with spaces' );
    ok( mkdir($dir_name), 'create directory' );

    my $filename = catfile( $dir_name, 'all chars.txt' );
    open( my $fh, '>', $filename );

    #Opened file, write test chars to it
    print $fh 'a' .. 'z', "\n";
    print $fh 'A' .. 'Z', "\n";
    print $fh '0' .. '9', "\n";
    close($fh);

    #md5 the file and grab the results;
    my @result = `perl md5.pl -f -r $dir`;

    #Check command executed successfully
    diag("ErrMsg: $!\nOutput: $@") if ( $? == -1 );

    #Scrape only resulting hash
    my $checksum = get_md5_from_string( $result[0] );

    #Check checksum is valid
    diag("Invalid Checksum") if ( !is_checksum($checksum) );

    ok( $checksum eq $expected_result, $testname );
}

done_testing();
