use strict;
use warnings;

use File::Temp qw/tempdir/;
use File::Spec::Functions qw/catfile/;

# create a random textfile
sub make_junk_file {
    my ( $filename, $length ) = @_;

    if ( open( my $fh, '>', $filename ) ) {
        my @chars = ( 'A' .. 'Z', 'a' .. 'z', 0 .. 9, "\n" );
        my $contents = '';
        while ( $length > 0 ) {
            $contents .= $chars[ rand(@chars) ];
            $length--;
        }
        print( $fh $contents );
        close($fh);
        return 1;
    }
    else {
        print "Error creating file $filename: $!\n";
        return 0;
    }
}    #end make_junk_file

#Verify checksum is a valid checksum
sub is_checksum {
    return $_[0] =~ /\p{Hex}{32}/;
}

#Extract MD5 checksum from string, return empty string on fail
sub get_md5_from_string {
    if ( $_[0] =~ /(\p{Hex}{32})/ ) {
        return $1;
    }
    return '';
}

#Attempt to delete all filenames that are passed
sub remove_files {
    foreach (@_) {
        if ( open( my $fh, '<', $_ ) ) {
            unlink $_ or warn "Could not unlink $_ : $!";
        }
    }
}

#Digest a file returning the md5 checksum
sub md5_file {
    if ( open( my $fh, '<', $_[0] ) ) {
        return Digest::MD5->new->addfile($fh)->hexdigest;
    }
    else {

        #could not read file
        return 0;
    }
}

1;

