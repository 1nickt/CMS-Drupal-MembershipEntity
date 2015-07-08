#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

use Test::More tests => 4;
use Test::Group;
use DBI;
use FindBin;
use File::Slurp::Tiny qw/ read_file read_lines /;
use Time::Local;

use Data::Dumper;
use Carp qw/ croak confess /;

# CMS::Drupal::Modules::MembershipEntity
# test 03 - Builds and validates a test DB

BEGIN {
  subtest "We have all our parts.\n" => sub {
    plan tests => 4;
    
    use_ok( 'CMS::Drupal' ) or die;
    use_ok( 'CMS::Drupal::Modules::MembershipEntity' ) or die;
    use_ok( 'CMS::Drupal::Modules::MembershipEntity::Test', qw( build_and_validate_test_db build_test_data ) );
    subtest 'All the data files exist.' => sub {
      plan tests => 4;

      for (qw/ test_db.sql test_types.dat test_memberships.dat test_terms.dat /) { 
        ok( -e "$FindBin::Bin/data/$_", "(we have $_)" );
      }
    };
  };
}

my $drupal = CMS::Drupal->new;
my $dbh    = build_and_validate_test_db( $drupal );

##########

my $ME;

subtest "Create a MembershipEntity object and check its methods.\n" => sub {
  plan tests => 3;
  
  can_ok( 'CMS::Drupal::Modules::MembershipEntity', 'new' );
  $ME = CMS::Drupal::Modules::MembershipEntity->new( dbh => $dbh);
  isa_ok( $ME, 'CMS::Drupal::Modules::MembershipEntity' );
  can_ok( 'CMS::Drupal::Modules::MembershipEntity', 'fetch_memberships' );
};

subtest "Validated data integrity.\n", => sub {
  plan tests => 1;

  ## Make a structure from the data files and compare to what the 
  ## module's function returns
  my $wanted_memberships = build_test_data();
  my $got_memberships = $ME->fetch_memberships;

  is_deeply( $got_memberships, $wanted_memberships, '$ME->fetch_memberships is_deeply the content of the test data files.' );
};

say "+" x 78;

done_testing();

