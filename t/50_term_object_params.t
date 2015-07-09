#!/usr/bin/env perl

use strict;
use warnings;

use 5.010;
use open ':std', ':encoding(utf8)';
use Test::More tests => 2;
use Test::Group;
use Carp qw/ croak /;
use Data::Dumper;

use CMS::Drupal;
use CMS::Drupal::Modules::MembershipEntity;
use CMS::Drupal::Modules::MembershipEntity::Test qw/ build_test_db build_test_data/;

my $drupal = CMS::Drupal->new;
my $dbh    = build_test_db( $drupal );
my $ME     = CMS::Drupal::Modules::MembershipEntity->new( dbh => $dbh );

# test the object, parameters

subtest '::Membership objects contain ::Term objects', sub {
  plan tests => 3;
  for ([3694], [3694, 2966], []) {
    my $array = $_;
    my $hashref = $ME->fetch_memberships( $array );
    test 'isa valid Term object for '. @$array .' Memberships' , sub {
      foreach my $mem ( values $hashref ) {
        foreach my $term ( values %{ $mem->{terms} } ) {
          isa_ok( $term, 'CMS::Drupal::Modules::MembershipEntity::Term',
            'tid => '. $term->{tid} );
        }
      } 
    };
  }
};

subtest 'Manually create a ::Term object', sub {
  plan tests => 10;
 
  my %params = (
    tid            => 666,
    mid            => 999,
    status         => 1,
    term           => '1 year',
    modifiers      => 'a:0:{}',
    start          => time - (180 * 24 * 3600), # functions are relative to "now"
    end            => time + (180 * 24 * 3600), # so test data must be, too.
    array_position => 1
  );  
  
  ok( ! eval { my $term = CMS::Drupal::Modules::MembershipEntity::Term->new },
      'Correctly fail to create an object with no parameters provided.' );

  foreach my $param (keys %params) {
    my %args = %params;
    delete $args{ $param };
    ok( ! eval { my $term = CMS::Drupal::Modules::MembershipEntity::Terms->new( \%args ) },
      'Correctly fail to create object with missing parameter: '. $param );
  }

  my $term = CMS::Drupal::Modules::MembershipEntity::Term->new( %params );
  isa_ok( $term, 'CMS::Drupal::Modules::MembershipEntity::Term',
    'Created object ' );

};

say '  ---  ' x 7;

__END__
