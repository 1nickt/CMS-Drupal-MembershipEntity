package CMS::Drupal::Modules::MembershipEntity::Stats;

# ABSTRACT: Generate statistics about MembershipEntity memberships on a Drupal site. 

use Moo;
use Types::Standard qw/ :all /;
use base 'Exporter::Tiny'; 
our @EXPORT = qw/
  count_memberships
  count_expired_memberships
  count_active_memberships
  count_cancelled_memberships
  count_pending_memberships
  count_were_renewal_memberships
  pct_active_memberships
  pct_expired_memberships
  pct_active_memberships_were_renewal
/;

use CMS::Drupal::Modules::MembershipEntity::Membership;

use Data::Dumper;
use Carp qw/ carp croak confess /;

has dbh    => ( is => 'ro', isa => InstanceOf['DBI::db'], required => 1 );
has prefix => ( is => 'ro', isa => Maybe[Str] );

=method count_memberships

Returns the number of Memberships in the set.

=cut

sub count_memberships {
  my $self = shift;
  if ($self->{'_memberships'}) {
    $self->{'_count_memberships'} = scalar keys %{$self->{'_memberships'}};
  } else {
    my $sql = q{ SELECT COUNT(mid) FROM membership_entity };
    $self->{'_count_memberships'} = $self->{'dbh'}->selectrow_array($sql);
  }
  return $self->{'_count_memberships'};
}

=method count_expired_memberships

Returns the number of Memberships from the set that have status of 'expired'.

=cut

sub count_expired_memberships {
  my $self = shift;
  if ($self->{'_memberships'}) {
    my $count = 0;
    while ( my ($mid, $mem) = each %{$self->{'_memberships'}} ) {
      $count++ if $mem->is_expired;
    }
    $self->{'_count_expired_memberships'} = $count;
  } else {
    my $sql = q{ select count(mid) from membership_entity where status = 0 };
    $self->{'_count_expired_memberships'} = $self->{'dbh'}->selectrow_array($sql);
  }
  return $self->{'_count_expired_memberships'};
}

=method count_active_memberships

Returns the number of Memberships from the set that have status of 'active'.

=cut

sub count_active_memberships {
  my $self = shift;
  if ($self->{'_memberships'}) {
    my $count = 0;
    while ( my ($mid, $mem) = each %{$self->{'_memberships'}} ) {
      $count++ if $mem->is_active;
    }
    $self->{'_count_active_memberships'} = $count;
  } else {
    my $sql = q{ SELECT COUNT(mid) FROM membership_entity WHERE status = 1 };
    $self->{'_count_active_memberships'} = $self->{'dbh'}->selectrow_array($sql);
  }
  return $self->{'_count_active_memberships'};
}

=method count_cancelled_memberships

Returns the number of Memberships from the set that have status of 'cancelled'.

=cut

sub count_cancelled_memberships {
  my $self = shift;
  if ($self->{'_memberships'}) {
    my $count = 0;
    while ( my ($mid, $mem) = each %{$self->{'_memberships'}} ) {
      $count++ if $mem->is_cancelled;
    }
    $self->{'_count_cancelled_memberships'} = $count;
  } else {
    my $sql = q{ SELECT COUNT(mid) FROM membership_entity WHERE status = 2 };
    $self->{'_count_cancelled_memberships'} = $self->{'dbh'}->selectrow_array($sql);
  }
  return $self->{'_count_cancelled_memberships'};
}

=method count_pending_memberships

Returns the number of Memberships from the set that have status of 'pending'.

=cut

sub count_pending_memberships {
  my $self = shift;
  if ($self->{'_memberships'}) {
    my $count = 0;
    while ( my ($mid, $mem) = each %{$self->{'_memberships'}} ) {
      $count++ if $mem->is_pending;
    }
    $self->{'_count_pending_memberships'} = $count;
  } else {
    my $sql = q{ select count(mid) from membership_entity where status = 3 };
    $self->{'_count_pending_memberships'} = $self->{'dbh'}->selectrow_array($sql);
  }
  return $self->{'_count_pending_memberships'};
}

=method count_were_renewal_memberships

Returns the number of Memberships from the set whose current Term was a renewal.

=cut

sub count_were_renewal_memberships {
  my $self = shift;
  if ($self->{'_memberships'}) {
    $self->{'_count_were_renewal_memberships'} = ();
    while ( my ($mid, $mem) = each %{$self->{'_memberships'}} ) {
      if ( $mem->current_was_renewal ) {
        $self->{'_count_were_renewal_memberships'}++;
      }
    }
  }
  return $self->{'_count_were_renewal_memberships'};
}

=method pct_active_memberships

Returns the percentage of all Memberships that currently have status of
'active'.

Accepts an integer value representing floating point precision as the single
parameter; this parameter is optional and defaults to 2.

  $ME->pct_active_memberships(4); # returns like 99.9999
  $ME->pct_active_memberships;    # returns like 99.99

=cut

sub pct_active_memberships {
  my $self = shift;
  my $precision = shift || 2;
  $self->{'_pct_active_memberships'} =
    sprintf("%.${precision}f", (100 *
    ($self->count_active_memberships / $self->count_memberships)));
  return $self->{'_pct_active_memberships'};
}

=method pct_expired_memberships

Returns the percentage of all Memberships that currently have status of
'expired'.

Accepts an integer value representing floating point precision as the single
parameter; this parameter is optional and defaults to 2.

  $ME->pct_expired_memberships(4); # returns like 99.9999
  $ME->pct_expired_memberships;    # returns like 99.99

=cut

sub pct_expired_memberships {
  my $self = shift;
  my $precision = shift || 2;
  $self->{'_pct_expired_memberships'} =
    sprintf("%.${precision}f", (100 *
    ($self->count_expired_memberships / $self->count_memberships)));
  return $self->{'_pct_expired_memberships'};
}

=method pct_active_memberships_were_renewal

Returns the percentage of active Memberships for which the current Term was
not the first Term in the Membership.

Accepts an integer value representing floating point precision as the single
parameter; this parameter is optional and defaults to 2.

  $ME->pct_active_memberships_were_renewal(4); # returns like 99.9999
  $ME->pct_active_memberships_were_renewal;    # returns like 99.99

=cut

sub pct_active_memberships_were_renewal {
  my $self = shift;
  my $precision = shift || 2;
  
  $self->{'_pct_active_memberships_were_renewal'} =
    sprintf("%.${precision}f", (100 *
    ($self->count_were_renewal_memberships / $self->count_active_memberships)));

  return $self->{'_pct_active_memberships_were_renewal'};
}

1; ## return true to end package CMS::Drupal::Modules::MembershipEntity
__END__

=head1 SYNOPSIS

  use CMS::Drupal::Modules::MembershipEntity;
  use CMS::Drupal::Modules::MembershipEntity::Stats { into => 'CMS::Drupal::Modules::MembershipEntity' };
  
  my $ME = CMS::Drupal::Modules::MembershipEntity->new( dbh => $dbh ); 
  $ME->fetch_memberships();
  
  print $ME->count_active_memberships;
  print $ME->pct_active_memberships_were_renewal; 
 
  ...



