#!/usr/bin/env perl

use strict;
use warnings;

use 5.010;
use open ':std', ':encoding(utf8)';
use Test::More tests => 1;
use Test::Group;
use Carp qw/ croak /;
use Data::Dumper;

use CMS::Drupal;
use CMS::Drupal::Modules::MembershipEntity;
use CMS::Drupal::Modules::MembershipEntity::Test qw/ build_test_db build_test_data/;

my $drupal = CMS::Drupal->new;
my $dbh    = build_test_db( $drupal );
my $ME     = CMS::Drupal::Modules::MembershipEntity->new( dbh => $dbh );

# test the object functions

subtest 'Test a Membership object', sub {
 
  my %params = (
    mid       => 666,
    member_id => 999,
    type      => 'membership',
    status    => 1,
    uid       => 6996,
    created   => 1379916000,
    changed   => 1379987654,
    terms     => { 23456 => bless( {}, 'CMS::Drupal::Modules::MembershipEntity::Term' ) },
  );  
  
  my $mem = CMS::Drupal::Modules::MembershipEntity::Membership->new( %params );
  
  isa_ok( $mem, 'CMS::Drupal::Modules::MembershipEntity::Membership',
    'Created a Membership object ' );

  subtest 'Check static properties', sub {
    plan tests => 8;
    foreach my $prop (keys %params) {
      is( $mem->{ $prop }, $params{ $prop }, $prop );
    }
  };

  subtest 'can_ok methods', sub {
    plan tests => 2;
    foreach my $method ( qw/ is_active has_renewal / ) {
      can_ok( $mem, $method );
    }
  };

  subtest 'Validate methods', sub {
    
    is( $mem->is_active, 1, 'is_active when status = 1' );
    
    for (0, 2, 3) {
      $mem->{status} = $_;
      isnt( $mem->is_active, 1, 'not is_active when status = '. $_ );
    }

    # depends on Term object; will have to test that first.
    # is( $mem->has_renewal, 1, 'has_renewal' );

    done_testing;
  };


done_testing;

};

say '  ---  ' x 7;

__END__
