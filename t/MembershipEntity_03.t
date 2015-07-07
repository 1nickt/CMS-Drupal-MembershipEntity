#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

use Test::More;
use DBI;
use FindBin;
use File::Slurp::Tiny 'read_file';
use POSIX qw/ strftime /;

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

my $now = time;

sub datetime { 
  my $time = shift;
  return strftime "%F %T", localtime($time);
}

# add membership = 'am'; i

my %am = (
  mid       => 1,
  member_id => 1,
  type      => 'membership',
  uid       => 1,
  status    => 1,
  created   => $now,
  changed   => $now
);

my $am = qq/
  INSERT INTO membership_entity (status, created, changed)
  VALUES (?, ?, ?)
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
 
  my $args = { @_ };
  croak unless defined $args->{'status'};
  $am{'status'} = $args->{'status'};

  # Add the Membership. It takes two steps because we
  # populate several fields from the returned last_insert_id

  $am{'created'} = $am{'changed'} = $now;

  my $am_rv = $dbh->do( $am, {}, $args->{'status'}, $now, $now );
  cmp_ok( $am_rv, '>', 0, 'Added a Membership (part 1/2) with no DB errors' );
  
  my $am_last_insert_id = $dbh->last_insert_id( undef, undef, 'membership_entity', 'mid' );
  cmp_ok( $am_last_insert_id, '>', 0, 'last_insert_id > 0' );
  $am{'mid'} = $am{'member_id'} = $am{'uid'} = $am_last_insert_id;

  my $am2_rv = $dbh->do( $am2, {}, $am_last_insert_id );
  cmp_ok( $am2_rv, '>', 0, 'Added a Membership (part 2/2) with no DB errors' );

  my $am_rows = $dbh->selectall_hashref( $fetch_am, 'mid', {}, $am_last_insert_id );
  cmp_ok( scalar keys $am_rows, '==', 1, 'Just one row in membership_entity' );
  is_deeply( $am_rows->{ $am_last_insert_id }, \%am, 'Got back the same data we inserted in membership_entity' );

  add_term (
    mid       => $am_rows->{ $am_last_insert_id }->{'mid'},
    status    => 1,
    term      => '1 year',
    modifiers => 'a:0:{}',
    start     => datetime( $now ),
    end       => datetime( $now + (365 * 24 * 60 * 60) )
  );

  say Dumper $am_rows;
}

my $at = qq/
  INSERT INTO membership_entity_term (mid, status, term, modifiers, start, end)
  VALUES (?, ?, ?, ?, ?, ?)
  /;

my $fetch_at = qq/ 
  SELECT id, mid, status, term, modifiers, start, end
  FROM membership_entity_term
  WHERE id = ?
  /;

my %at = ( 
  id        => 1,
  mid       => 1,
  status    => 1,
  term      => '1 month',
  modifiers => 'a:0:{}',
  start     => datetime( $now ),
  end       => datetime( $now + (31 * 24 * 60 * 60)),
);

sub add_term {
 
  my $args = { @_ };

  croak "Missing param 'mid'!" unless defined $args->{'mid'};
  croak "Missing param 'status'!" unless defined $args->{'status'};
 
  $at{'mid'}    = $args->{'mid'};
  $at{'status'} = $args->{'status'};
  $at{'term'}   = $args->{'term'};
  $at{'start'}  = $args->{'start'};
  $at{'end'}    = $args->{'end'};

  for (1..2) {
  my $at_rv = $dbh->do( $at, {}, $args->{'mid'}, $args->{'status'}, $args->{'term'}, $args->{'modifiers'}, $args->{'start'}, $args->{'end'} );
  cmp_ok( $at_rv, '>', 0, 'Added a Term with no DB errors' );
  
  my $at_last_insert_id = $dbh->last_insert_id( undef, undef, 'membership_entity_term', 'id' );
  cmp_ok( $at_last_insert_id, '>', 0, 'last_insert_id > 0' );
  $at{'id'} = $at_last_insert_id;

  my $at_rows = $dbh->selectall_hashref( $fetch_at, 'id', {}, $at_last_insert_id );
  cmp_ok( scalar keys $at_rows, '==', 1, 'Just one row in membership_entity_term' );
  is_deeply( $at_rows->{ $at_last_insert_id }, \%at, 'Got back the same data we inserted in membership_entity_term' );
 }
}

for (1..3) {
  add_membership( status => $_ );
}


say "+" x 78;

done_testing();

