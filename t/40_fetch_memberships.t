#!/usr/bin/env perl

use strict;
use warnings;

use 5.010;
use open ':std', ':encoding(utf8)';
use Test::More tests => 1;

use CMS::Drupal;
use CMS::Drupal::Modules::MembershipEntity;
use CMS::Drupal::Modules::MembershipEntity::Test qw/ build_test_db build_test_data/;

my $drupal = CMS::Drupal->new;
my $dbh    = build_test_db( $drupal );
my $ME     = CMS::Drupal::Modules::MembershipEntity->new( dbh => $dbh );

subtest 'Feed various things to fetch_memberships()', sub {
  plan tests => 2;
  subtest 'Various arrays of valid mids', sub {
    for (
          [3694],
          [3694, 2966],
          [3694, 2966, 42],
          [3302, 3358, 3414, 3470, 3530, 3582, 3638, 3694, 3750, 3948, 3974, 4006, 4030, 4086],
        ) {
      my $array = $_;
      my $hashref = $ME->fetch_memberships( $array );
      my $cmp_data = build_test_data( $array );
    
      is( (scalar keys $hashref), (scalar keys $cmp_data),
        'One hashref element for each valid mid passed in' );
    
      is_deeply($hashref, $cmp_data, "Data matches for @$array");
    }
  };

  subtest 'Various arrays with invalid mids', sub {
    for (
          [],
          [3694, 'foo'],
          [3694, $ME],
          [3694, chr(0x263a)],
          [3694, sub { print "Hello, world\n" }],
        ) {
      my $array = $_;
      ok( ! eval{ my $hashref = $ME->fetch_memberships( $array ) },
        "Correctly died with bad mid ('". $array ? $array->[1] : '' ."') in call to fetch_memberships()" );
    }
  };
};

say '  ---  ' x 7;

__END__
