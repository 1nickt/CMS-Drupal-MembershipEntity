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
# add type = 'ay'
my %ay = (
  id          => '1', # we're going to check the insert_row_id
  type        => 'membership',
  label       => 'Membership',
  weight      => '0',
  description => 'Description text.',
  data        => 'a:10:{s:16:"member_id_format";s:35:"membership_entity_numeric_member_id";s:18:"member_id_settings";a:1:{s:6:"length";s:1:"5";}s:11:"cardinality";s:1:"1";s:12:"primary_role";s:1:"4";s:14:"secondary_role";s:1:"4";s:15:"show_on_profile";i:1;s:8:"all_edit";i:0;s:6:"bundle";s:22:"membership_entity_type";s:31:"additional_settings__active_tab";s:18:"edit-user-settings";s:22:"available_term_lengths";a:2:{i:-10;s:7:"3 years";i:-9;s:6:"1 year";}}',
  status      => '1',
  module      => 'foo'
);

my $ay = qq/
  INSERT INTO membership_entity_type (type, label, weight, description, data, status, module)
  VALUES (?, ?, ?, ?, ?, ?, ?)
/;

my $ay_rv = $dbh->do( $ay, {}, $ay{'type'}, $ay{'label'}, $ay{'weight'}, $ay{'description'}, $ay{'data'}, $ay{'status'}, $ay{'module'} );
cmp_ok( $ay_rv, '>', 0, 'Added a default type with no DB errors' );

my $ay_last_insert_id = $dbh->last_insert_id( undef, undef, 'membership_entity_type', 'id' );
cmp_ok( $ay_last_insert_id, '>', 0, 'last_insert_id > 0' );

## now select it back and compare with %at
my $fetch_ay = qq/
  SELECT id, type, label, weight, description, data, status, module
  FROM membership_entity_type
  LIMIT 1
  /;

my $ay_rows = $dbh->selectall_hashref( $fetch_ay, 'id' );
cmp_ok( scalar keys $ay_rows, '==', 1, 'Just one row in membership_entity_type' );
is_deeply( $ay_rows->{ $ay_last_insert_id }, \%ay, 'Got back the same data we inserted in membership_entity_type' );

##########

# prepare for adding memberships
# and their terms

# add membership = 'am'; add term = 'at'

my %am = (
  mid       => 1,
  member_id => 1,
  type      => 'membership',
  uid       => 1,
  status    => 1,
  created   => 1,
  changed   => 1
);

my $am = qq/
  INSERT INTO membership_entity (created, changed)
  VALUES (?, ?)
  /;

my $am2 = qq/
  UPDATE membership_entity
  SET member_id = mid, uid = mid
  WHERE mid = ?
  /;

my $fetch_am = qq/
  SELECT mid, member_id, type, uid, status, created, changed
  FROM membership_entity
  WHERE mid = ?
  /;

sub add_membership {
  my $now = time; $am{'created'} = $am{'changed'} = $now;

  my $am_rv = $dbh->do( $am, {}, $now, $now );
  cmp_ok( $am_rv, '>', 0, 'Added a Membership (part 1/2) with no DB errors' );
  
  my $am_last_insert_id = $dbh->last_insert_id( undef, undef, 'membership_entity', 'mid' );
  cmp_ok( $am_last_insert_id, '>', 0, 'last_insert_id > 0' );
  $am{'mid'} = $am{'member_id'} = $am{'uid'} = $am_last_insert_id;

  my $am2_rv = $dbh->do( $am2, {}, $am_last_insert_id );
  cmp_ok( $am2_rv, '>', 0, 'Added a Membership (part 2/2) with no DB errors' );

  my $am_rows = $dbh->selectall_hashref( $fetch_am, 'mid', {}, $am_last_insert_id );
  cmp_ok( scalar keys $am_rows, '==', 1, 'Just one row in membership_entity_type' );
  is_deeply( $am_rows->{ $am_last_insert_id }, \%am, 'Got back the same data we inserted in membership_entity' );
}

add_membership();



say "+" x 78;

done_testing();

