#! perl
use strict;
use warnings;

BEGIN {
  ## Make sure we don't connect to our real DB if we
  ## have given the credentials for it
  $ENV{'DRUPAL_IGNORE_TEST_CREDS'} = 1;
}

use Test::More tests => 12;

use CMS::Drupal;
use CMS::Drupal::Modules::MembershipEntity;
use CMS::Drupal::Modules::MembershipEntity::Test;

my $drupal = CMS::Drupal->new;
my $dbh    = build_test_db( $drupal );
my $ME     = CMS::Drupal::Modules::MembershipEntity->new( dbh => $dbh );

use_ok( 'CMS::Drupal::Modules::MembershipEntity::Stats' );
can_ok( 'CMS::Drupal::Modules::MembershipEntity::Stats', 'new' );
my $Stats = CMS::Drupal::Modules::MembershipEntity::Stats->new( dbh => $dbh );
isa_ok( $Stats, 'CMS::Drupal::Modules::MembershipEntity::Stats' );

can_ok( 'CMS::Drupal::Modules::MembershipEntity::Stats', 'count_memberships');
can_ok( 'CMS::Drupal::Modules::MembershipEntity::Stats', 'count_expired_memberships');
can_ok( 'CMS::Drupal::Modules::MembershipEntity::Stats', 'count_active_memberships');
can_ok( 'CMS::Drupal::Modules::MembershipEntity::Stats', 'count_cancelled_memberships');
can_ok( 'CMS::Drupal::Modules::MembershipEntity::Stats', 'count_pending_memberships');
can_ok( 'CMS::Drupal::Modules::MembershipEntity::Stats', 'count_were_renewal_memberships');
can_ok( 'CMS::Drupal::Modules::MembershipEntity::Stats', 'pct_active_memberships');
can_ok( 'CMS::Drupal::Modules::MembershipEntity::Stats', 'pct_expired_memberships');
can_ok( 'CMS::Drupal::Modules::MembershipEntity::Stats', 'pct_active_memberships_were_renewal');

__END__

