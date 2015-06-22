package CMS::Drupal::Modules::MembershipEntity::Term;

use strict;
use warnings;

use vars qw($VERSION $VERSION_DATE);
$VERSION = "0.99";
$VERSION_DATE = "June, 2015";
 
use Moo;
use Types::Standard qw/ :all /;
use Data::Dumper;

has tid            => ( is => 'ro', isa => Int, required => 1 );
has mid            => ( is => 'ro', isa => Int, required => 1 );
has status         => ( is => 'ro', isa => Int, required => 1 );
has term           => ( is => 'ro', isa => Str, required => 1 );
has modifiers      => ( is => 'ro', isa => Str, required => 1 );
has start          => ( is => 'ro', isa => Int, required => 1 );
has end            => ( is => 'ro', isa => Int, required => 1 );
has array_position => ( is => 'ro', isa => Int, required => 1 );

sub is_active {
  my $self = shift;
  return $self->{'status'} eq '1' ? 1 : undef;
}

sub is_current {
  my $self = shift;
  my $now = time;
  return ($self->is_active && ($self->{'start'} <= $now && $now <= $self->{'end'}))
    ? 1 : undef;
}

sub is_future {
  my $self = shift;
  my $now = time;
  return ($self->is_active && ($self->{'start'} > $now)) ? 1 : undef;
}

sub was_renewal {
  my $self = shift;
  return $self->{array_position} > 1 ? 1 : undef;
}

1; ## return true to end package MembershipEntity::Term

=pod
 
=head1 NAME

CMS::Drupal::Modules::MembershipEntity::Term

=head1 SYNOPSIS

use CMS::Drupal::Modules::MembershipEntity::Term;

$term = CMS::Drupal::Modules::MembershipEntity::Term->new(
          'tid'            => '4321',
          'mid'            => '1234',
          'status'         => '1',
          'term'           => 'One year',
          'modifiers'      => 'a:0:{}',
          'start'          => '1234567890',
          'end'            => '1234568999',
          'array_position' => '2',
        );

=head1 USAGE

Note: This module does not currently create or edit Membership Terms.

This module is not designed to be called directly, although it can be. This module is called by L<CMS::Drupal::Modules::MembershipEntity>, which has a method that retrieves all Membership Terms and creates an object for each of them (which is stored inside the parent Membership object). Error checking is handled in the latter module, so if you use this module directly you will have to do your own error checking, for example, to make sure that the Term actually has a start and an end date-and-time associated with it. (Yes, I know it should be impossible not to, but it happens. This is Drupal we are dealing with.)
 
=head2 PARAMETERS

B<All parameters are required.> Consult the Drupal MembershipEntity documentation for more details.

B<tid> The B<tid> for the Term. Must be an integer.

B<mid> The B<mid> for the parent Membership. Must be an integer.

B<status> The status of the Term. Must be an integer from 0 to 3.

B<modifiers> The special string containing any modifiers to the Term length.

B<start> The start date-and-time for the Term. Must be a Unix timestamp.

B<end> The end date-and-time for the Term. Must be a Unix timestamp.

B<array_position> The position the Term holds in the array of Terms belonging to the parent Membership. The array is sorted by start date-and-time ascending, and is indexed from 1, not from zero. (This parameter is passed automatically to this module if you use L<CMS::Drupal::Modules::MembershipEntity>'s B<fetch_memberships()> method.)

=head2 METHODS

B<is_active> Returns true if the Term has a status of 'active.' Note this does not mean it is the current Term (see below). Returns undef for any other status.

B<is_current> Returns true if the Term is the current Term (i.e. the current time falls between the start date-and-time and the end date-and-time). Returns undef otherwise.

B<is_future> Returns true if the Term has not yet begun (i.e. the start date-and-time is after the current time). Memberships can be renewed before they expire, so a Term can have a status of 'active' but be held in the future.

B<was_renewal> Returns true if the Term was a renewal, as defined by the Term's B<array_position> being greater than 1 (i.e., there was an earlier Term).

=head1 AUTHOR

Author: Nick Tonkin (nick@websitebackendsolutions.com)

=head1 COPYRIGHT
   
Copyright (c) 2015 Nick Tonkin. All rights reserved.

=head1 LICENSE

You may distribute this module under the same license as Perl itself.

=head1 SEE ALSO

L<CMS::Drupal>

L<CMS::Drupal::Modules::MembershipEntity>

L<CMS::Drupal::Modules::MembershipEntity::Membership>.
 
=cut

