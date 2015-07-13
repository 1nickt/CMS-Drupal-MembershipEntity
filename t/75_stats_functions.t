#! perl
use strict;
use warnings;
use 5.010;

use Carp qw/ carp croak confess /;
use Data::Dumper;

use Test::More tests => 9;
use Test::Group;

use CMS::Drupal;
use CMS::Drupal::Modules::MembershipEntity;
use CMS::Drupal::Modules::MembershipEntity::Test;
use lib '/Users/nick/dev/perl_dev/CMS-Drupal-Modules-MembershipEntity/lib';

use CMS::Drupal::Modules::MembershipEntity::Stats { into => 'CMS::Drupal::Modules::MembershipEntity' };

my $drupal = CMS::Drupal->new;

my $dbh    = ( exists $ENV{'DRUPAL_TEST_CREDS'}) ?
               $drupal->dbh( split(',', $ENV{'DRUPAL_TEST_CREDS'}) ) :
               build_test_db( $drupal );

my $ME     = CMS::Drupal::Modules::MembershipEntity->new( dbh => $dbh );

$ME->fetch_memberships;

my %data;

$data{'count_memberships'} =
  $dbh->selectrow_array(q{SELECT COUNT(mid) FROM membership_entity});

$data{'count_expired_memberships'} =
  $dbh->selectrow_array(q{SELECT COUNT(mid) FROM membership_entity WHERE status = '0'});

$data{'count_active_memberships'} =
  $dbh->selectrow_array(q{SELECT COUNT(mid) FROM membership_entity WHERE status = '1'});

$data{'count_cancelled_memberships'} =
  $dbh->selectrow_array(q{SELECT COUNT(mid) FROM membership_entity WHERE status = '2'});

$data{'count_pending_memberships'} =
  $dbh->selectrow_array(q{SELECT COUNT(mid) FROM membership_entity WHERE status = '3'});

$data{'count_were_renewal_memberships'} = eval {

  ## Wow, this seems complicated. Gather data to compare results of
  ## was_current_renewal

  # MySQL & PostgreSQL vs. SQLite ... sigh
  my $dbms_localtime = ($dbh->{'Driver'}->{'Name'} eq 'SQLite') ?
                         q/DATETIME('now')/ : q/LOCALTIME/;
  my $sql1 = qq/
    SELECT mid, id
    FROM membership_entity_term
    WHERE start < $dbms_localtime
      AND end   > $dbms_localtime
  /;

  my %current_mids = %{ $dbh->selectall_hashref( $sql1, 'mid') };
  my %current_tids = %{ $dbh->selectall_hashref( $sql1, 'id') }; 

  my $sql2 = qq/
    SELECT id, mid, start, end
    FROM membership_entity_term
    ORDER BY start
  /;

  my %ordered_terms;
  foreach my $row ( @{ $dbh->selectall_arrayref( $sql2 ) }) {
    push @{ $ordered_terms{ $row->[1] } }, $row;
  }

  foreach my $mid ( keys %ordered_terms ) {
    # only keep it if it has a current term
    if ( ! exists $current_mids{ $mid } ) {
      delete $ordered_terms{ $mid };
      next;
    }
    
    # only keep it if it has at least two terms
    if ( scalar @{ $ordered_terms{ $mid } } < 2 ) {
      delete $ordered_terms{ $mid };
      next;
    }
  }

  # if the mem is still here, it has a current term and more than one term.
  # shift the earliest one off; the rest are renewals; is one of them current? 
  my %were_renewal_memberships;
  foreach my $mid ( keys %ordered_terms ) {
    shift @{ $ordered_terms{ $mid } };
    foreach my $term ( @{ $ordered_terms{ $mid } } ) {
      $were_renewal_memberships{ $mid }++ if exists $current_tids{ $term->[0] };
    }
  }

  return scalar keys %were_renewal_memberships;

}; # end eval block

$data{'pct_active_memberships'} = sprintf("%.2f",
  ( $data{'count_active_memberships'} / $data{'count_memberships'} ) * 100);

$data{'pct_expired_memberships'} = sprintf("%.2f",
  ( $data{'count_expired_memberships'} / $data{'count_memberships'} ) * 100);

$data{'pct_active_memberships_were_renewal'} = sprintf("%.2f",
  ( $data{'count_were_renewal_memberships'} / $data{'count_active_memberships'} ) * 100);


#######################

is( $ME->count_memberships,
    $data{'count_memberships'},
    'Count memberships' );

is( $ME->count_expired_memberships,
    $data{'count_expired_memberships'},
    'Count expired memberships' );

is( $ME->count_active_memberships,
    $data{'count_active_memberships'},
    'Count active memberships' );

is( $ME->count_cancelled_memberships,
    $data{'count_cancelled_memberships'},
    'Count cancelled memberships' );

is( $ME->count_pending_memberships,
    $data{'count_pending_memberships'},
    'Count pending memberships' );

is( $ME->count_were_renewal_memberships,
    $data{'count_were_renewal_memberships'},
    'Count "was renewal" memberships' );

is( $ME->pct_active_memberships,
    $data{'pct_active_memberships'},
    'Percentage active memberships' );

is( $ME->pct_expired_memberships,
    $data{'pct_expired_memberships'},
    'Percentage expired memberships' );

is( $ME->pct_active_memberships_were_renewal,
    $data{'pct_active_memberships_were_renewal'},
    'Percentage active memberships were renewal' );


__END__

