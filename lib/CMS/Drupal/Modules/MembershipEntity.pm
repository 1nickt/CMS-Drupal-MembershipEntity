package CMS::Drupal::Modules::MembershipEntity;


# ABSTRACT: Perl interface to Drupal MembershipEntity entities

use Moo;
use Types::Standard qw/ :all /;
use Time::Local;
use CMS::Drupal::Modules::MembershipEntity::Membership;
use CMS::Drupal::Modules::MembershipEntity::Term;
use Data::Dumper;
use Carp qw/ carp croak confess /;
use 5.010;

has dbh    => ( is => 'ro', isa => InstanceOf['DBI::db'], required => 1 );
has prefix => ( is => 'ro', isa => Maybe[StrMatch[ qr/ \w+_ /x ]] );

sub fetch_memberships {

  my $self = shift;
  my $prefix = $self->{'prefix'} || '';

  ## We accept an arrayref of mids as an optional parameter

  my $mids = shift;
  my $WHERE = ' ';
  if ( $mids ) {
    confess "FATAL: Empty list of mids." if scalar @{ $mids } < 1;

    for (@$mids) {
      # Let's be real strict about what we try to pass in to the DBMS
      confess "FATAL: Invalid 'mid' (must be all ASCII digits)."
        unless /^\d+$/a;
      
      $WHERE = 'WHERE ';
      $WHERE .= "mid = '$_' OR " for @$mids;
      $WHERE =~ s/ OR $//;
    }
  }
  
  my $temp;
  my $memberships;

  ## Get the Membership info
  my $sql = qq|
    SELECT mid, member_id, type, uid, status, created, changed
    FROM ${prefix}membership_entity
    $WHERE
  |;
  
  my $sth = $self->{'dbh'}->prepare( $sql );
  $sth->execute;
  
  my $results = $sth->fetchall_hashref('mid');
  foreach my $mid (keys( %$results )) {
    $temp->{ $mid } = $results->{ $mid };
  }
  
  ## Get the Membership Term info
  #  Use the $WHERE clause from the optional mids parameter
  my $sql2 = qq|
    SELECT id as tid, mid, status, term, modifiers, start, end
    FROM ${prefix}membership_entity_term
    $WHERE
    ORDER BY start
  |;
  
  my $sth2 = $self->{'dbh'}->prepare( $sql2 );
  $sth2->execute;

  my %term_count; # used to track array position of Terms

  while( my $row = $sth2->fetchrow_hashref ) {
    ## Shouldn't be, but is, possible to have a Term with no start or end
    if ( not defined $row->{'start'} or not defined $row->{'end'} ) {
      carp "MISSING DATE: tid< $row->{'tid'} > " .
           "(uid< $temp->{ $row->{'mid'} }->{'uid'} >) has no start " .
           "or end date defined. Skipping ...";
      next;
    }

    ## convert the start and end to unixtime
    for (qw/ start end /) {
      my @datetime = reverse (split /[-| |:]/, $row->{ $_ });
      $datetime[4]--;
      $row->{ $_ } = timelocal( @datetime );
    } 

    ## Track which of the Membership's Terms this is
    $term_count{ $row->{'mid'} }++;
    $row->{'array_position'} = $term_count{ $row->{'mid'} };
    
    ## Instantiate a MembershipEntity::Term object for each
    ## Term now that we have the data
    my $term = CMS::Drupal::Modules::MembershipEntity::Term->new( $row );
    $temp->{ $row->{'mid'} }->{ 'terms' }->{ $row->{'tid'} } = $term;
  }

  ## Instantiate a MembershipEntity::Membership object for each
  ## Membership now that we have the data
  foreach my $mid( keys( %$temp )) {
    
    ## Shouldn't be, but is, possible to have a Membership with no Term
    if (not defined $temp->{ $mid }->{'terms'}) {
      carp "MISSING TERM: mid< $mid > (uid< $temp->{ $mid }->{'uid'} >) " .
           "has no Membership Terms. Skipping ...";
      next;
    }
    
    $memberships->{ $mid } =
    CMS::Drupal::Modules::MembershipEntity::Membership->new( $temp->{ $mid } );
  }
  
  return $memberships;
}

1; ## return true to end package CMS::Drupal::Modules::MembershipEntity

=pod

=head1 NAME

CMS::Drupal::Modules::MembershipEntity

=head1 SYNOPSIS

 use CMS::Drupal::Modules::MembershipEntity;

 my $ME = CMS::Drupal::Modules::MembershipEntity->new( dbh => $dbh );

 my $hashref = $ME->fetch_memberships;
 # or:
 my $hashref = $ME->fetch_memberships([ 123, 456, 789 ]);
 # or:
 my $hashref = $ME->fetch_memberships([ 123 ]);
 # or:
 my $hashref = $ME->fetch_memberships( \@list );
 
 foreach my $mid ( sort keys %{$hashref} ) {
   my $mem = $hashref->{ $mid };
   
   print $mem->{'type'};
   &send_newsletter( $mem->{'uid'} ) if $mem->active;
   
   # etc ...
 }

=head1 USAGE

This package returns a hashref containing one element for each Membership that
was requested. The hashref is indexed by B<mid> and the element is a Membership
object, which contains at least one Term object, so you have access to all the
methods you can use on your Membership.

For this reason the methods actually provided by the submodules are documented
here.

=head2 METHODS

=head2 fetch_memberships

This method returns a hashref containing Membership objects indexed by B<mid>.

When called with no arguments, the hashref contains all Memberships in the 
Drupal database, which might be too much for your memory if you have lots
of them.

When called with an arrayref containing B<mid>s, the hashref will contain an 
object for each mid in the arrayref.

 # Fetch a single Membership
 my $hashref = $ME->fetch_memberships([ 1234 ]); 

 # Fetch a set of Memberships
 my $hashref = $ME->fetch_memberships([ 1234, 5678 ]);

 # Fetch a set of Memberships using a list you prepared elsewhere
 my $hashref = $ME->fetch_memberships( $array_ref );

 # Fetch all your Memberships
 my $hashref = $ME->fetch_memberships;

=head2 Memberships

This module uses CMS::Drupal::Modules::MembershipEntity::Membership so you
don't have to. The methods described below are actually in the latter 
module.

 my $hashref = $ME->fetch_memberships([ 1234 ]);
 my $mem = $hashref->{'1234'};

=head3 Attributes

You can directly access all the Membership's attributes as follows:

 $mem->{ attr_name }

Where attr_name is one of:

 mid           
 member_id
 type
 uid
 status
 created
 changed

There is also another attribute `terms`, which contains an hashref of Term
objects, indexed by B<tid>. Each Term can be accessed by the methods described
in the Membership Terms section below.

=head3 is_active

Returns true if the Membership status is active, else returns false.

  say "User $mem->{'uid'} is in good standing" if $mem->is_active;

=head3 has_renewal

Returns true if the Membership has at least one Term for which
is_future returns true.

 say "User $mem->{'uid'} has already renewed" if $mem->has_renewal;

=head2 Membership Terms

This module uses CMS::Drupal::Modules::MembershipEntity::Term so you
don't have to. The methods described below are actually in the latter
module.

 while ( my ($tid, $term) = each %{$mem->{'terms'}} ) {
  # do something ...
 }

=head3 Attributes

You can directly access all the Term's attributes as follows:

 $term->{ attr_name }

Where attr_name is one of:

 tid
 mid
 status
 term
 modifiers
 start
 end

There is also another attribute, `array_position`, which is used to determine if
the Term is a renewal, etc.

=head3 is_active

Returns true if the Term status is active, else returns false.
(Note that 'active' does not necessarily mean 'current', see below.)

 say "$term->{'tid'} is active" if $term->is_active;

=head3 is_current

Returns true if the Term is current, meaning that the datetime now
falls between the start and end of the Term.
(Note that the Term may be 'current' but not 'active', eg 'pending'.)

 say "This is a live one" if $term->is_current;

=head3 is_future

Returns true if the `start` of the Term is in the future compared to now.

 say "$mem->{'uid'} has a prepaid renewal" if $term->is_future;

=head3 was_renewal

Returns true if the Term was a renewal when it was created (as determined
simply by the fact that there was an earlier one).

 say "$mem->{'uid'} is a repeat customer" if $term->was_renewal;


=head1 SEE ALSO


=cut
