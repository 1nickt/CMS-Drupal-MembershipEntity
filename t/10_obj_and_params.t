#! perl
use strict;
use warnings;

use Test::More tests => 3;
use DBI;

BEGIN {
  use_ok( 'CMS::Drupal::Modules::MembershipEntity' ) or die;
  use_ok( 'DBD::SQLite' ) or die;
}

subtest 'Parameter validation and object instantiation', sub {
  plan tests => 10;

  my $dbh = DBI->connect('DBI:SQLite:dbname=:memory:', '', '', { RaiseError => 1 });

  can_ok( 'CMS::Drupal::Modules::MembershipEntity', 'new' );

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
};

__END__

