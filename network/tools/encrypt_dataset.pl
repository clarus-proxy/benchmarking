#!/usr/bin/perl
use Crypt::CBC;
use MIME::Base64;

my $key = 'CLARUSISTHEBESTA';
my $iv = '1234567890abcdef';

my $cipher = Crypt::CBC->new(
    {
        'key'         => $key,
        'cipher'      => 'Rijndael',
        'iv'          => $iv,
        'literal_key' => 1,
        'padding'     => 'null',
        'header'      => 'none',
        keysize       => 128 / 8
    }
);

foreach $text ( <STDIN> ) {
    #if ( $text =~ /'(.+?)'/) {
        my $new_text = $text;
        while($text =~ /'(.+?)'/g) {
            #$enc_field = `nice -n 20 ./network/tools/encrypt.sh $&`;
            #$enc_field = `printf $& | openssl enc -a -A -aes-128-cbc -k CLARUSISTHEBESTANONYMIZATIONTOOLBOX`;
            #$enc_field = `printf $&`;
            $encrypted = $cipher->encrypt_hex($&);
            $enc_field = encode_base64($encrypted, '');
            $new_text =~ s/$&/'$enc_field'/;
        }
        print $new_text;
        #} else {
        #print $text;
        #}
}
