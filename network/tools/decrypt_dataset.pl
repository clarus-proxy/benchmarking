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
            #$enc_field = `printf $& | openssl enc -aes-256-cbc -a -d -k "CLARUSISTHEBESTANONYMIZATIONTOOLBOX"`;
            $enc_field = decode_base64($&);
            $decrypted = $cipher->decrypt_hex($enc_field);
            $new_text =~ s/$&/$decrypted/;
        }
        print $new_text;
}
