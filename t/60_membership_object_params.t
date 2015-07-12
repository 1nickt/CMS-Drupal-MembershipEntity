#! perl
use strict;
use warnings;

use Test::More tests => 2;
use Test::Group;

use CMS::Drupal;
use CMS::Drupal::Modules::MembershipEntity;
use CMS::Drupal::Modules::MembershipEntity::Test qw/ build_test_db build_test_data/;

my $drupal = CMS::Drupal->new;
my $dbh    = build_test_db( $drupal );
my $ME     = CMS::Drupal::Modules::MembershipEntity->new( dbh => $dbh );

# test the object, parameters

subtest 'fetch_memberships() returns ::Membership objects', sub {
  plan tests => 3;
  for ([3694], [3694, 2966], []) {
    my $array = $_;
    my $hashref = $ME->fetch_memberships( $array );
    test 'isa valid object for '. @$array .' mids', sub {
      foreach my $mem ( values %{ $hashref } ) {
        isa_ok( $mem, 'CMS::Drupal::Modules::MembershipEntity::Membership' );
      }
    }; 
  }
};

subtest 'Manually create a ::Membership object', sub {
  plan tests => 10;
 
  my %params = (
    'mid'       => 666,
    'member_id' => 999,
    'type'      => 'membership',
    'status'    => 1,
    'uid'       => 6996,
    'created'   => 1379916000,
    'changed'   => 1379987654,
    'terms'     => { 23456 => bless( {}, 'CMS::Drupal::Modules::MembershipEntity::Term' ) },
  );  
  
  ok( ! eval { my $mem = CMS::Drupal::Modules::MembershipEntity::Membership->new },
      'Correctly fail to create an object with no parameters provided.' );

  foreach my $param (keys %params) {
    my %args = %params;
    delete $args{ $param };
    ok( ! eval { my $mem = CMS::Drupal::Modules::MembershipEntity::Membership->new( \%args ) },
      'Correctly fail to create object with missing parameter: '. $param );
  }

  my $mem = CMS::Drupal::Modules::MembershipEntity::Membership->new( %params );
  isa_ok( $mem, 'CMS::Drupal::Modules::MembershipEntity::Membership',
    'Created object ' );
};

__END__

