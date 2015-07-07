#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

use Test::More;
use DBI;
use FindBin;
use File::Slurp::Tiny 'read_file';

use Data::Dumper;
use Carp qw/ croak confess /;

# CMS::Drupal::Modules::MembershipEntity
# test 03 - Test functions on a mock DB";

BEGIN {
  use_ok( 'CMS::Drupal::Modules::MembershipEntity' ) or die;
}

# read the current ME database schema and make a test DB
my $dbh = DBI->connect("DBI:SQLite:dbname=:memory:", '', '', { RaiseError => 1 });
$dbh->do($_) for (split( /\n{2,}/, read_file("$FindBin::Bin/test_db.sql") ));

##########

can_ok( 'CMS::Drupal::Modules::MembershipEntity', 'new' );
my $ME = CMS::Drupal::Modules::MembershipEntity->new( dbh => $dbh);
isa_ok( $ME, 'CMS::Drupal::Modules::MembershipEntity' );

##########

can_ok( 'CMS::Drupal::Modules::MembershipEntity', 'fetch_memberships' );

is( $ME->fetch_memberships, undef, 'No error but no results for fetch_memberships' ); # There aren't any yet

#########

# first we have to have a default type
# add type = 'at'
my %at = (
  id          => '1', # we're going to check the insert_row_id
  type        => 'membership',
  label       => 'Membership',
  weight      => '0',
  description => 'Description text.',
  data        => 'a:10:{s:16:"member_id_format";s:35:"membership_entity_numeric_member_id";s:18:"member_id_settings";a:1:{s:6:"length";s:1:"5";}s:11:"cardinality";s:1:"1";s:12:"primary_role";s:1:"4";s:14:"secondary_role";s:1:"4";s:15:"show_on_profile";i:1;s:8:"all_edit";i:0;s:6:"bundle";s:22:"membership_entity_type";s:31:"additional_settings__active_tab";s:18:"edit-user-settings";s:22:"available_term_lengths";a:2:{i:-10;s:7:"3 years";i:-9;s:6:"1 year";}}',
  status      => '1',
  module      => 'foo'
);

my $add_type = qq/
  INSERT INTO membership_entity_type ( type, label, weight, description, data, status, module )
  VALUES (?, ?, ?, ?, ?, ?, ?)
/;

my $add_type_rv = $dbh->do( $add_type, {}, $at{'type'}, $at{'label'}, $at{'weight'}, $at{'description'}, $at{'data'}, $at{'status'}, $at{'module'} );

cmp_ok( $add_type_rv, '>', 0, 'Added a default type with no DB errors' );

## now select it back and compare with %at
my $fetch_type = qq/
  SELECT id, type, label, weight, description, data, status, module
  FROM membership_entity_type
  LIMIT 1
  /;

my $at_rows = $dbh->selectall_hashref( $fetch_type, 'id' );

cmp_ok( scalar keys $at_rows, '==', 1, 'Just one row in membership_entity_type' );

is_deeply( $at_rows->{1}, \%at, 'Got back the same data we inserted in membership_entity_type' );

##########

# prepare for adding memberships
# and their terms
__END__
# add membership = 'am'
my %am = (
  mid       => 'mid',
  member_id => 'member_id',
  type      => 
  uid
  status
  created
  changed




my $add_mem = $dbh->prepare( qq/
  INSERT INTO membership_entity
    (created)
  VALUES ( ? )
  / );

my $add_mem2 = $dbh->prepare( qq/
  UPDATE membership_entity
  SET member_id = ?, uid = ?, changed = ?
  WHERE mid = ?
  / );

sub add_membership {
  my $args = {@_};
  my $add_mem_rv = $dbh->do( $add_mem, undef, '11234567890' );

  cmp_ok( $add_mem_rv, '>', 0, 'Added a Membership ...' );  

}

add_membership( created => '2015-07-06' );



#my $add_mem = qq/
#  INSERT INTO 
#$dbh_do( $insert );



say "+" x 78;

done_testing();

