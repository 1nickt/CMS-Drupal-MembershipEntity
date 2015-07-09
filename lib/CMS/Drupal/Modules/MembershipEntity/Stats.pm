package CMS::Drupal::Modules::MembershipEntity::Stats;

# ABSTRACT: Generate statistics about Drupal MembershipEntity memberships on a Drupal site. 

use Moo;
use Types::Standard qw/ :all /;
use CMS::Drupal::Modules::MembershipEntity::Membership;

has dbh    => ( is => 'ro', isa => InstanceOf['DBI::db'], required => 1 );
has prefix => ( is => 'ro', isa => Maybe[Str], required => 1 );

sub fetch_memberships {
  my $self = shift;
 
  my $memberships;

  ## Get the Membership info
  my $sql = qq|SELECT mid, created, changed, uid, status, member_id, type
               FROM $self->{'prefix'}membership_entity|;
  my $sth = $self->{'dbh'}->prepare( $sql );
  $sth->execute;
  my $results = $sth->fetchall_hashref('mid');
  foreach my $mid (keys( %$results )) {
    $memberships->{ $mid } = $results->{ $mid };
  }

  ## Get the Membership Term info
  $sql = qq|
    SELECT t.id, t.mid, t.status, t.term, t.modifiers, t.start, t.end
    FROM $self->{'prefix'}membership_entity_term t
    LEFT JOIN $self->{'prefix'}membership_entity m ON t.mid = m.mid
  |;
  $sth = $self->{'dbh'}->prepare( $sql );
  $sth->execute;
  while( my $row = $sth->fetchrow_hashref ) {
    $memberships->{ $row->{'mid'} }->{ 'terms' }->{ $row->{'id'} } = $row;
  }

  return $memberships;
}

sub fetch_all_memberships {
  my $self = shift;
  $self->{ _all_memberships } =
    $self->{dbh}->selectall_hashref( "select * from membership_entity", 'mid' );
  return $self->{ _all_memberships };
}

sub count_all_memberships {
  my $self = shift;
  my $sql = "select count(mid) from membership_entity";
  $self->{ _count_all_memberships } = $self->{dbh}->selectrow_array($sql);
  return $self->{ _count_all_memberships };
}

sub count_expired_memberships {
  my $self = shift;
  my $sql = "select count(mid) from membership_entity where status = 0";
  $self->{ _count_expired_memberships } = $self->{dbh}->selectrow_array($sql);
  return $self->{ _count_expired_memberships };
}

sub count_active_memberships {
  my $self = shift;
  my $sql = "select count(mid) from membership_entity where status = 1";
  $self->{ _count_active_memberships } = $self->{dbh}->selectrow_array($sql);
  return $self->{ _count_active_memberships };
}

sub count_cancelled_memberships {
  my $self = shift;
  my $sql = "select count(mid) from membership_entity where status = 2";
  $self->{ _count_cancelled_memberships } = $self->{dbh}->selectrow_array($sql);
  return $self->{ _count_cancelled_memberships };
}

sub count_pending_memberships {
  my $self = shift;
  my $sql = "select count(mid) from membership_entity where status = 3";
  $self->{ _count_pending_memberships } = $self->{dbh}->selectrow_array($sql);
  return $self->{ _count_pending_memberships };
}

sub percentage_active_memberships {
  my $self = shift;
  $self->{ _percentage_active_memberships } =
    sprintf("%.2f%%", (($self->count_active_memberships / $self->count_all_memberships) * 100));
  return $self->{ _percentage_active_memberships };
}

sub percentage_expired_memberships {
  my $self = shift;
  $self->{ _percentage_expired_memberships } =
    sprintf("%.2f%%", (($self->count_expired_memberships / $self->count_all_memberships) * 100));
  return $self->{ _percentage_expired_memberships };
}


1; ## return true to end package CMS::Drupal::Modules::MembershipEntity

=pod

=head1 NAME

CMS::Drupal::Modules::MembershipEntity::Stats

=head1 SYNOPSIS

 use CMS::Drupal::Modules::MembershipEntity::Stats;

=head1 USAGE

To come ...

=cut
