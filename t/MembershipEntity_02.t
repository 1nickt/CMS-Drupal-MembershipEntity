#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

use Test::More tests => 3;
use Data::Dumper;
use Carp qw/ croak confess /;


say '+' x 70;

say "CMS::Drupal::Modules::MembershipEntity test 02 - MembershipEntity functions.";

use_ok( 'CMS::Drupal',
  'use() the parent CMS::Drupal module.' );

use_ok( 'CMS::Drupal::Modules::MembershipEntity',
  'use() this module.' );

my $drupal = CMS::Drupal->new;
my %params;
my $skip = 0;

if ( exists $ENV{'DRUPAL_TEST_CREDS'} ) {
  %params = ( split ',', $ENV{'DRUPAL_TEST_CREDS'} );
} else {
  $skip++;
}

SKIP: {
  skip "No database credentials supplied", 1, if $skip;

  ###########

  ok( my $dbh = $drupal->dbh( %params ),
    'Get a dbh with the credentials.' );

  ###########

 say "+" x 70;

} # end SKIP block

__END__
