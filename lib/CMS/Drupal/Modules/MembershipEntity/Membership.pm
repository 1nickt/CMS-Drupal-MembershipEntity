package CMS::Drupal::Modules::MembershipEntity::Membership;

# ABSTRACT: Perl interface to a Drupal MembershipEntity membership

use strict;
use warnings;

use Moo;
use Types::Standard qw/ :all /;

has mid       => ( is => 'ro', isa => Int, required => 1 );
has created   => ( is => 'ro', isa => Int, required => 1 );
has changed   => ( is => 'ro', isa => Int, required => 1 );
has uid       => ( is => 'ro', isa => Int, required => 1 );
has status    => ( is => 'ro', isa => Enum[ qw/0 1 2 3/ ], required => 1 );
has member_id => ( is => 'ro', isa => Str, required => 1 );
has type      => ( is => 'ro', isa => Str, required => 1 );
has terms     => ( is => 'ro', isa => HashRef, required => 1 );

=method is_expired

Returns 1 if the Membership has status of 'expired'. Else returns 0.

=cut

sub is_expired {
  my $self = shift;
  $self->{'_is_expired'} = $self->{'status'} eq '0' ? 1 : 0;
  return $self->{'_is_expired'};
}

=method is_active

Returns 1 if the Membership has status of 'active'. Else returns 0.

=cut

sub is_active {
  my $self = shift;
  $self->{'_is_active'} = $self->{'status'} eq '1' ? 1 : 0;
  return $self->{'_is_active'};
}

=method is_cancelled

Returns 1 if the Membership has status of 'cancelled'. Else returns 0.

=cut

sub is_cancelled {
  my $self = shift;
  $self->{'_is_cancelled'} = $self->{'status'} eq '2' ? 1 : 0;
  return $self->{'_is_cancelled'};
}

=method is_pending

Returns 1 if the Membership has status of 'pending'. Else returns 0.

=cut

sub is_pending {
  my $self = shift;
  $self->{'_is_pending'} = $self->{'status'} eq '3' ? 1 : 0;
  return $self->{'_is_pending'};
}

=method has_renewal

Returns 1 if the Membership has a renewal Term that has not yet started. This is defined by the value of $term->is_future and $term->is_active both being true for at least one of the Membership's Terms. Else returns 0.

  print "User $mem->{'uid'} has already renewed" if $mem->has_renewal;

=cut

sub has_renewal {
  my $self = shift;
  $self->{'_has_renewal'} = 0;
  foreach my $term ( values %{ $self->{'terms'} } ) {
    $self->{'_has_renewal'}++ if ($term->is_future and $term->is_active);
  }
  return $self->{'_has_renewal'};
}

=method current_was_renewal

Returns 1 if the current Term belonging to the Membership was a renewal
(i.e. not the Membership's first ever Term). Else returns 0.

=cut

sub current_was_renewal {
  my $self = shift;
  $self->{'_current_was_renewal'} = 0;
  foreach my $term ( values %{ $self->{'terms'} } ) {
    $self->{'_current_was_renewal'}++ if ($term->is_current && $term->was_renewal);
  }
  return $self->{'_current_was_renewal'};
}


1; ## return true to end package MembershipEntity::Membership
__END__

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

This module is not designed to be called directly, although it can be. This module is called by L<CMS::Drupal::Modules::MembershipEntity|CMS::Drupal::Modules::MembershipEntity>, which has a method to retrieve Memberships and create an object for each of them. Error checking is handled in the latter module, so if you use this module directly you will have to do your own error checking, for example, to make sure that the Membership actually has at least one Term associated with it. (Yes, I know it should be impossible not to, but it happens. This is Drupal we are dealing with.)

=head2 PARAMETERS

B<All parameters are required.> Consult the Drupal MembershipEntity documentation for more details.

=for :list
* B<mid>
The B<mid> for the Membership. Must be an integer.
* B<created>
The date-and-time the Membership was created. Must be a Unix timestamp.
* B<changed>
The date-and-time the Membership was last changed. Must be a Unix timestamp.
* B<uid>
The Drupal user ID for the owner of the Membership. Must be an integer.
* B<status>
The status of the Membership. Must be an integer from 0 to 3.
* B<member_id>
The unique Member ID that Drupal assigns to the Membership. This is separate from the B<uid> and the B<mid> and can be configured by the Drupal sysadmin to take almost any string-y format.
* B<type>
The Membership type.
* B<terms>
A hashref containing a L<CMS::Drupal::Modules::MembershipEntity::Term|CMS::Drupal::Modules::MembershipEntity::Term> object for each term belonging to the Membership, keyed by the B<tid> (term ID).

=head1 SEE ALSO

=for :list
* L<CMS::Drupal|CMS::Drupal>
* L<CMS::Drupal::Modules::MembershipEntity|CMS::Drupal::Modules::MembershipEntity>
* L<CMS::Drupal::Modules::MembershipEntity::Term|CMS::Drupal::Modules::MembershipEntity::Term>

