#!/usr/bin/env perl

##############################################################################
#
# This is t/MembershipEntity02.t It tests the 
# CMS::Drupal::Modules::MembershipEntity module against a real Drupal
# database. It looks in your environment to see if you have provided
# connection information.
#
# So if you want to test against your Drupal DB, you must set the variable
#
# DRUPAL_TEST_CREDS
#
# in your environment, exactly as follows:
#
# required fields are 
#   database - name of your DB
#   driver   - your dbi:driver ... mysql, Pg or SQLite
#
# optional fields are
#   user     - your DB user name
#   password - your DB password
#   host     - your DB server hostname
#   port     - which port to connect on
#   prefix   - your database table schema prefix, if any
#
# All these fields and values must be joined together in one string with no
# spaces, and separated with commas.
#
# Examples:
#
# database,foo,driver,SQLite
# database,foo,driver,Pg
# database,foo,driver,mysql,user,bar,password,baz,host,localhost,port,3306,prefix,My_
#
# You can set an environment variable in many ways. To make it semi permanent,
# put it in your .bashrc or .bash_profile or whatever you have.
#
# If you just want to run this test once, you can just do this from your
# command prompt:
#
# $ DRUPAL_TEST_CREDS=database,foo,driver,SQLite
# $ perl ./MembershipEntity_02.t
#
# If you report a bug or ask for support for this module, the first thing I 
# will ask for is the output from these tests, so make sure and do this, 'k?
#
# You really should want to know if your setup is working, anyway.
#
#############################################################################

use strict;
use warnings;
use 5.010;

use Cwd qw/ abs_path /;
my $me = abs_path($0);

use Test::More tests => 10;

# CMS::Drupal::Modules::MembershipEntity
# test 02 - database readiness

BEGIN {
  use_ok( 'CMS::Drupal',
    'use() CMS::Drupal' ) or die;

  use_ok( 'CMS::Drupal::Modules::MembershipEntity',
    'use() CMS::Drupal::Modules::MembershipEntity' ) or die;
}


my %params;
my $skip = 0;

if ( exists $ENV{'DRUPAL_TEST_CREDS'} ) { 
  %params = ( split ',', $ENV{'DRUPAL_TEST_CREDS'} );
} else {
  say qq{ 

   No database credentials found in ENV. 
   Skipping Drupal database tests.

   If you want to run these tests in the future,
   set the value of DRUPAL_TEST_CREDS in your ENV as
   documented in the source of this file,
   $me

  };
                    
  $skip++;
}


SKIP: {
  skip "No database credentials supplied", 8, if $skip;

  ###########

  my $drupal = CMS::Drupal->new;
  isa_ok( $drupal, 'CMS::Drupal');

  ###########

  my $dbh = $drupal->dbh( %params );
  isa_ok( $dbh, 'DBI::db',
    'Get a dbh from CMS::Drupal::dbh() with the credentials.' );

  ###########

  my $sth = $dbh->column_info( undef, $dbh->{ 'Name' }, 'membership_entity', '%' );
  my @cols = map { $_->[3] } @{ $sth->fetchall_arrayref };
  my @wanted_cols = qw/ mid
                        member_id
                        type
                        uid
                        status
                        created
                        changed /;

  is_deeply( [ sort @cols ], [ sort @wanted_cols ],
    'Get correct column names from membership_entity table.');

  ###########

  $sth = $dbh->column_info( undef, $dbh->{ 'Name' }, 'membership_entity_term', '%' );
  @cols = map { $_->[3] } @{ $sth->fetchall_arrayref };
  @wanted_cols = qw/ id
                     mid
                     status
                     term
                     modifiers
                     start
                     end /;

  is_deeply( [ sort @cols ], [ sort @wanted_cols ],
    'Get correct column names from membership_entity_terms table.');

  ############
 
  $sth = $dbh->column_info( undef, $dbh->{ 'Name' }, 'membership_entity_type', '%' );
  @cols = map { $_->[3] } @{ $sth->fetchall_arrayref };
  @wanted_cols = qw/ id
                     type
                     label
                     weight
                     description
                     data
                     status
                     module /;

  is_deeply( [ sort @cols ], [ sort @wanted_cols ],
    'Get correct column names from membership_entity_type table.');

  ############

  $sth = $dbh->column_info( undef, $dbh->{ 'Name' }, 'membership_entity_secondary_member', '%' );
  @cols = map { $_->[3] } @{ $sth->fetchall_arrayref };
  @wanted_cols = qw/ mid
                     uid
                     weight /;

  is_deeply( [ sort @cols ], [ sort @wanted_cols ],
    'Get correct column names from membership_entity_secondary_member table.' );

  ############

  # We know there is at least one Membership type in a working installation
  
  my $sql = qq|
    SELECT COUNT(id) AS count
    FROM membership_entity_type
  |;

  $sth = $dbh->prepare( $sql );

  ok( $sth->execute(),
    'Execute a SELECT on the membership_entity_type table.' );

  ok( $sth->fetchrow_hashref->{'count'} > 0,
    'SELECT COUNT(id) FROM membership_entity_type > 0' );

  # But we can't assume anything else, even that there is a single row in the
  # membership_entity or membership_entity_term tables, so we can't really 
  # test anything else ...
  #
  # We'll test the functionality with DBD::Mock in the next test
  
  ##############

} # end SKIP block

say "-" x 78;

__END__
