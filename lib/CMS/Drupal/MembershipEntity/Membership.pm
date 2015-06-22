package CMS::Drupal::Modules::MembershipEntity::Membership;

use strict;
use warnings;

use vars qw($VERSION $VERSION_DATE);
$VERSION = "0.99";
$VERSION_DATE = "June, 2015";
 
use Moo;
use Types::Standard qw/ :all /;
use Data::Dumper;

has mid       => ( is => 'ro', isa => Int, required => 1 );
has created   => ( is => 'ro', isa => Int, required => 1 );
has changed   => ( is => 'ro', isa => Int, required => 1 );
has uid       => ( is => 'ro', isa => Int, required => 1 );
has status    => ( is => 'ro', isa => Enum[ qw/0 1 2 3/ ], required => 1 );
has member_id => ( is => 'ro', isa => Str, required => 1 );
has type      => ( is => 'ro', isa => Str, required => 1 );
has terms     => ( is => 'ro', isa => HashRef, required => 1 );

1; ## return true to end package MembershipEntity::Membership

=pod

=head1 NAME

CMS::Drupal::Modules::MembershipEntity::Membership

=head1 SYNOPSIS

use CMS::Drupal::Modules::MembershipEntity::Membership;

$mem = CMS::Drupal::Modules::MembershipEntity::Membership->new(
         'mid'       => '1234',
         'created'   => '1234565432',
         'changed'   => '1234567890',
         'uid'       => '5678',
         'status'    => '1',
         'member_id' => 'my_scheme_0123',
         'type'      => 'my_type',
         'terms'     => \%terms
       );

=head1 USAGE

Note: This module does not currently create or edit Memberships.

This module is not designed to be called directly, although it can be. This module is called by L<CMS::Drupal::Modules::MembershipEntity>, which has a method to retrieve all Memberships and create an object for each of them. Error checking is handled in the latter module, so if you use this module directly you will have to do your own error checking, for example, to make sure that the Membership actually has at least one Term associated with it. (Yes, I know it should be impossible not to, but it happens. This is Drupal we are dealing with.)

=head2 PARAMETERS

B<All parameters are required.> Consult the Drupal MembershipEntity documentation for more details.

B<mid> The B<mid> for the Membership. Must be an integer.

B<created> The date-and-time the Membership was created. Must be a Unix timestamp.

B<changed> The date-and-time the Membership was last changed. Must be a Unix timestamp.

B<uid> The Drupal user ID for the owner of the Membership. Must be an integer.

B<status> The status of the Membership. Must be an integer from 0 to 3.

B<member_id> The unique Member ID that Drupal assigns to the Membership. This is separate from the B<uid> and the B<mid> and can be configured by the Drupal sysadmin to take almost any string-y format.

B<type> The Membership type.

B<terms> A hashref containing a L<CMS::Drupal::Modules::MembershipEntity::Term> object for each term belonging to the Membership, keyed by the B<tid> (term ID).

=head1 AUTHOR
  
Author: Nick Tonkin (nick@websitebackendsolutions.com)
  
=head1 COPYRIGHT
  
Copyright (c) 2015 Nick Tonkin. All rights reserved.
  
=head1 LICENSE
  
You may distribute this module under the same license as Perl itself.
  
=head1 SEE ALSO
  
L<CMS::Drupal>

L<CMS::Drupal::Modules::MembershipEntity>

L<CMS::Drupal::Modules::MembershipEntity::Term>.
  
=cut

