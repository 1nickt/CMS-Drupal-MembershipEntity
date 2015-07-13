package CMS::Drupal::Modules::MembershipEntity::Stats;

# ABSTRACT: Generate statistics about Drupal MembershipEntity memberships on a Drupal site. 

use Moo;
use Types::Standard qw/ :all /;
use CMS::Drupal::Modules::MembershipEntity::Membership;

has dbh    => ( is => 'ro', isa => InstanceOf['DBI::db'], required => 1 );
has prefix => ( is => 'ro', isa => Maybe[Str], required => 1 );

sub count_all_memberships {
  my $self = shift;
  my $sql = q{ select count(mid) from membership_entity };
  $self->{'_count_all_memberships'} = $self->{'dbh'}->selectrow_array($sql);
  return $self->{'_count_all_memberships'};
}

sub count_expired_memberships {
  my $self = shift;
  my $sql = q{ select count(mid) from membership_entity where status = 0 };
  $self->{'_count_expired_memberships'} = $self->{'dbh'}->selectrow_array($sql);
  return $self->{'_count_expired_memberships'};
}

sub count_active_memberships {
  my $self = shift;
  my $sql = q{ select count(mid) from membership_entity where status = 1 };
  $self->{'_count_active_memberships'} = $self->{'dbh'}->selectrow_array($sql);
  return $self->{'_count_active_memberships'};
}

sub count_cancelled_memberships {
  my $self = shift;
  my $sql = q{ count(mid) from membership_entity where status = 2 };
  $self->{'_count_cancelled_memberships'} = $self->{'dbh'}->selectrow_array($sql);
  return $self->{'_count_cancelled_memberships'};
}

sub count_pending_memberships {
  my $self = shift;
  my $sql = q{ select count(mid) from membership_entity where status = 3 };
  $self->{'_count_pending_memberships'} = $self->{'dbh'}->selectrow_array($sql);
  return $self->{'_count_pending_memberships'};
}

sub percentage_active_memberships {
  my $self = shift;
  $self->{'_percentage_active_memberships'} =
    sprintf("%.2f%%", (($self->count_active_memberships / $self->count_all_memberships) * 100));
  return $self->{'_percentage_active_memberships'};
}

sub percentage_expired_memberships {
  my $self = shift;
  $self->{'_percentage_expired_memberships'} =
    sprintf("%.2f%%", (($self->count_expired_memberships / $self->count_all_memberships) * 100));
  return $self->{'_percentage_expired_memberships'};
}


1; ## return true to end package CMS::Drupal::Modules::MembershipEntity
__END__

=head1 SYNOPSIS

 use CMS::Drupal::Modules::MembershipEntity::Stats;

=head1 USAGE

To come ...

