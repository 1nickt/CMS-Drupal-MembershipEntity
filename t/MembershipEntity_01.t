#!/usr/bin/env perl

##############################################################################
#
# This is t/MembershipEntity01.t It tests the 
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
# $ perl ./MembershipEntity_01.t
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

use Test::More tests => 7;
use Data::Dumper;
use Carp qw/ croak confess /;


say '+' x 70;

say "CMS::Drupal::Modules::MembershipEntity test 01 - object and parameter validation.";

use_ok( 'CMS::Drupal',
  'use() the parent CMS::Drupal module.' );

use_ok( 'CMS::Drupal::Modules::MembershipEntity',
  'use() this module.' );

my $drupal = CMS::Drupal->new;
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
  documented in the source of this file, $me

  };

  $skip++;
}

SKIP: {
  skip "No database credentials supplied", 4, if $skip;

  ###########

  ok( my $dbh = $drupal->dbh( %params ),
    'Get a dbh with the credentials.' );

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
    'Get correct column names from membership_entity_secondary_member table.');

  ############


 say "+" x 70;

} # end SKIP block

__END__
