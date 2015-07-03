package CMS::Drupal::Modules::MembershipEntity;


# ABSTRACT Perl interface to Drupal MembershipEntity entities

use Moo;
use Types::Standard qw/ :all /;
use CMS::Drupal::Modules::MembershipEntity::Membership;
use CMS::Drupal::Modules::MembershipEntity::Term;
use Data::Dumper;
use Carp;
use feature qw/ say /;

has dbh    => ( is => 'ro', isa => InstanceOf['DBI::db'], required => 1 );
has prefix => ( is => 'ro', isa => Maybe[Str], required => 1 );

sub fetch_memberships {
  my $self = shift;
 
  my $temp;
  my $memberships;

  ## Get the Membership info
  my $sql = qq|
    SELECT mid, created, changed, uid, status, member_id, type
    FROM $self->{'prefix'}membership_entity
  |;
  my $sth = $self->{'dbh'}->prepare( $sql );
  $sth->execute;
  my $results = $sth->fetchall_hashref('mid');
  foreach my $mid (keys( %$results )) {
    $temp->{ $mid } = $results->{ $mid };
  }

  ## Get the Membership Term info
  $sql = qq|
    SELECT t.id AS tid, t.mid AS mid, t.status AS status, t.term AS term,
           t.modifiers AS modifiers, UNIX_TIMESTAMP(t.start) as start,
           UNIX_TIMESTAMP(t.end) as end
    FROM $self->{'prefix'}membership_entity_term t
    LEFT JOIN $self->{'prefix'}membership_entity m ON t.mid = m.mid
    ORDER BY start
  |;
  $sth = $self->{'dbh'}->prepare( $sql );
  $sth->execute;

  my %term_count; # used to track array position of Terms

  while( my $row = $sth->fetchrow_hashref ) {

    ## Shouldn't be but is possible to have a Term with no start or end
    if ( not defined $row->{'start'} or not defined $row->{'end'} ) {
      carp "MISSING DATE: tid< $row->{'tid'} > " .
           "(uid< $temp->{ $row->{'mid'} }->{'uid'} >) has no start " .
           "or end date defined. Skipping ...";
      next;
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
    
    ## Shouldn't be but is possible to have a Membership with no Term
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
