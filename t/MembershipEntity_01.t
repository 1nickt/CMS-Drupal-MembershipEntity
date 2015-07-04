#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

use Test::More tests => 10;
use DBI;

say '-' x 78;

say "CMS::Drupal::Modules::MembershipEntity ";
say "test 01 - object and parameter validation.\n";

my $dbh = DBI->connect('DBI:Mock:', '', '', { RaiseError => 1 });

use_ok( 'CMS::Drupal::Modules::MembershipEntity',
  'use() this module.' );

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

ok( my $ME = CMS::Drupal::Modules::MembershipEntity->new( dbh => $dbh ) ,
  'Instantiate an object with valid $dbh and no prefix parameter.' );

ok( my $ME2 = CMS::Drupal::Modules::MembershipEntity->new( dbh => $dbh, prefix => 'foo_' ),
  'Instantiate an object with valid $dbh and valid prefix parameter.' );


say "-" x 78;

__END__
