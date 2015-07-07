#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

use Test::More;
use Test::Group;
use DBI;
use FindBin;
use File::Slurp::Tiny qw/ read_file read_lines /;
use POSIX qw/ strftime /;

use Data::Dumper;
use Carp qw/ croak confess /;

# CMS::Drupal::Modules::MembershipEntity
# test 03 - Test functions on a mock DB";

BEGIN {
  use_ok( 'CMS::Drupal' ) or die;
  use_ok( 'CMS::Drupal::Modules::MembershipEntity' ) or die;
}

# read the current ME database schema and make a test DB
my $drupal = CMS::Drupal->new;
isa_ok( $drupal, 'CMS::Drupal');

my $dbh = $drupal->dbh( database => ':memory:',
                        driver   => 'SQLite' );

test 'Build the SQLite in-memory test database' => sub {
  for (split( /\n{2,}/, read_file("$FindBin::Bin/test_db.sql") )) {
    my $rv = $dbh->do($_);
    isnt( $rv, undef, 'Added a table to the test database' );
  }
};

#########

# Populate the test database

# First we have to have a default type

my $add_type = qq/
  INSERT INTO membership_entity_type (type, label, weight, description, data, status, module)
  VALUES (?, ?, ?, ?, ?, ?, ?)
/;

my @fields = split(',', read_file("$FindBin::Bin/test_types.dat")) or croak; # This file must have only ONE line

my $add_type_rv = $dbh->do( $add_type, {}, @fields, undef );
cmp_ok( $add_type_rv, '>', 0, 'Added a default type with no DB errors' );

## Now add Memberships from the data file

my $add_mem = qq/
  INSERT INTO membership_entity (mid, member_id, type, uid, status, created, changed)
  VALUES ( ?, ?, ?, ?, ?, ?, ?)
  /;

test 'Populate the membership_entity table with test data' => sub {
  for ( read_lines("$FindBin::Bin/test_memberships.dat",  chomp => 1 ) ) {
    my @fields = split(',');
    my $add_mem_rv = $dbh->do( $add_mem, {}, @fields );
    cmp_ok( $add_mem_rv, '>', 0, "Added a Membership for mid $fields[0]" );
  }
};

## Now add Membership Terms from the data file

my $add_term = qq/
  INSERT INTO membership_entity_term(id, mid, status, term, modifiers, start, end )
  VALUES (?, ?, ?, ?, ?, ?, ?)
  /;

test 'Populate the membership_entity_term table with test data' => sub {
  for ( read_lines("$FindBin::Bin/test_terms.dat",  chomp => 1 ) ) {
    my @fields = split(',');
    my $add_term_rv = $dbh->do( $add_term, {}, @fields );
    cmp_ok( $add_term_rv, '>', 0, "Added a Term for $fields[0]" );
  }
};

# done building the test DB

$dbh->sqlite_backup_to_file("$FindBin::Bin/out");

__END__

##########

can_ok( 'CMS::Drupal::Modules::MembershipEntity', 'new' );
my $ME = CMS::Drupal::Modules::MembershipEntity->new( dbh => $dbh);
isa_ok( $ME, 'CMS::Drupal::Modules::MembershipEntity' );

##########

can_ok( 'CMS::Drupal::Modules::MembershipEntity', 'fetch_memberships' );

$ME->fetch_memberships;

say "+" x 78;

done_testing();

