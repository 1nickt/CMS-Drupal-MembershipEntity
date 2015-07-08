#!/usr/bin/env perl -w

use strict;
use 5.010;
use Carp qw/ croak confess /;
use Data::Dumper;
use Test::More tests => 4;

use CMS::Drupal;
use CMS::Drupal::Modules::MembershipEntity;
use CMS::Drupal::Modules::MembershipEntity::Test qw/ build_test_db build_test_data/;

my $drupal = CMS::Drupal->new;
isa_ok( $drupal, 'CMS::Drupal' );

my $dbh = build_test_db( $drupal );

my $ME = CMS::Drupal::Modules::MembershipEntity->new( dbh => $dbh );
isa_ok( $ME, 'CMS::Drupal::Modules::MembershipEntity' );

my $hashref = $ME->fetch_memberships; my $cmp_data = build_test_data;
#my $hashref = $ME->fetch_memberships([ 3694, 2966 ]); my $cmp_data = build_test_data([ 2966, 3694 ]);
#my $hashref = $ME->fetch_memberships([ 3694 ]); my $cmp_data = build_test_data([ 3694 ]);

is_deeply($hashref, $cmp_data, 'Data matches');

say '  ---  ' x 7;

foreach my $mid ( sort keys %$hashref ) {
  my $mem = $hashref->{ $mid };
  #say "$mid is in good standing." if $mem->is_active;
  say "$mid has a renewal" if $mem->has_renewal;

  #&send_thankyou( $mem->{'mid'} ) if $mem->{'terms'}->[0]->is_renewal;
  #say "Term current" if $mem->{'terms'}->[0]->is_current;
}



#####################
__END__
