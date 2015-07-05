#!/usr/bin/env perl

# CMS::Drupal::Modules::MembershipEntity
# test 01 - object and parameter validation

use strict;
use warnings;
use 5.010;

use Test::More tests => 10;
use DBI;

my $dbh = DBI->connect('DBI:Mock:', '', '', { RaiseError => 1 });

BEGIN {
  use_ok( 'CMS::Drupal::Modules::MembershipEntity',
    'use() this module.' ) or die;
}

ok( ! eval{ my $ME = CMS::Drupal::Modules::MembershipEntity->new() },
  'Correctly fail to instantiate an object with no parameters.' );

ok( ! eval{ my $ME = CMS::Drupal::Modules::MembershipEntity->new( prefix => '' ) },
  'Correctly fail to instantiate an object with missing dbh parameter and empty string prefix parameter.' );

ok( ! eval{ my $ME = CMS::Drupal::Modules::MembershipEntity->new( prefix => 'foo' ) },
  'Correctly fail to instantiate an object with missing dbh parameter and invalid prefix parameter.' );

ok( ! eval{ my $ME = CMS::Drupal::Modules::MembershipEntity->new( prefix => 'foo_' ) },
  'Correctly fail to instantiate an object with missing dbh parameter and valid prefix parameter.' );

ok( ! eval{ my $ME = CMS::Drupal::Modules::MembershipEntity->new( dbh => 'foo', prefix => 'bar_' ) },
  'Correctly fail to instantiate an object with invalid $dbh and valid prefix parameter.' );

ok( ! eval{ my $ME = CMS::Drupal::Modules::MembershipEntity->new( dbh => '$dbh', prefix => '' ) },
  'Correctly fail to instantiate an object with valid $dbh and empty string prefix parameter.' );

ok( ! eval{ my $ME = CMS::Drupal::Modules::MembershipEntity->new( dbh => '$dbh', prefix => 'foo' ) },
  'Correctly fail to instantiate an object with valid $dbh and invalid prefix parameter "foo".' );

my $ME = CMS::Drupal::Modules::MembershipEntity->new( dbh => $dbh );
isa_ok( $ME, 'CMS::Drupal::Modules::MembershipEntity',
  'Instantiate an object with valid $dbh and no prefix parameter.' );

my $ME2 = CMS::Drupal::Modules::MembershipEntity->new( dbh => $dbh, prefix => 'foo_' );
isa_ok( $ME2, 'CMS::Drupal::Modules::MembershipEntity',
  'Instantiate an object with valid $dbh and valid prefix parameter.' );


say "-" x 78;

__END__
