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
  count_daily_term_expirations
  count_daily_term_activations
  count_daily_new_memberships
  count_daily_new_terms
  historical_active_memberships
/;
use Time::Local;
use Time::Piece;

use CMS::Drupal::Modules::MembershipEntity::Membership;

use Data::Dumper;
use Carp qw/ carp croak confess /;
# use feature qw/ say /;

has dbh    => ( is => 'ro', isa => InstanceOf['DBI::db'], required => 1 );
has prefix => ( is => 'ro', isa => Maybe[Str] );

=method count_memberships()

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

=method count_expired_memberships()

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

=method count_active_memberships()

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

=method count_cancelled_memberships()

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

=method count_pending_memberships()

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

=method count_were_renewal_memberships()

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

=method pct_active_memberships([$precision])

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

=method pct_active_memberships_were_renewal([$precision])

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

=method count_daily_term_expirations( @list_of_dates )

Returns the number of Membership Terms belonging to Members
in the set that expired in the 24-hour period beginning with
the date supplied. Takes dates in ISO-ish format.

Returns a scalar when called with one date.

Can also be called with an array of date-times, in which case it will return a
reference to a hash indexed by the same date-time string, using the count for
the values.

=cut

sub count_daily_term_expirations {
  my $self = shift;
  my @dates = @_;
  my %counts;

  my $sql = qq/
    SELECT COUNT(DISTINCT mid)
    FROM membership_entity_term
    WHERE end >= ?
    AND end < ?
    AND status NOT IN (2,3)
  /;
  
  my $sth = $self->{'dbh'}->prepare( $sql );

  foreach my $datetime (@dates) {

    my @dateparts = reverse (split /[-| |T|:]/, $datetime); 
    $dateparts[4]--;
    my $time = timelocal( @dateparts );
    $time += (24*3600);
    my $plus_one = localtime($time);

    $sth->execute( $datetime, $plus_one->datetime );
    $counts{ $datetime } = $sth->fetchrow_array;
  } 

  return (scalar keys %counts == 1) ?
              $counts{ $dates[0] } :
              \%counts;
  
} # end sub

=method count_daily_term_activations( @list_of_dates )

Returns the number of Membership Terms belonging to Members
in the set that began in the 24-hour period beginning with
the date supplied. Takes dates in ISO-ish format.

Returns a scalar when called with one date.

Can also be called with an array of date-times, in which case it will return a
reference to a hash indexed by the same date-time string, using the count for
the values.

=cut

sub count_daily_term_activations {
  my $self = shift;
  my @dates = @_; 
  my %counts;

  my $sql = qq/ 
    SELECT COUNT(DISTINCT mid)
    FROM membership_entity_term
    WHERE start >= ?
    AND start < ?
    AND status NOT IN (2,3)
  /;
  
  my $sth = $self->{'dbh'}->prepare( $sql );

  foreach my $datetime (@dates) {

    my @dateparts = reverse (split /[-| |T|:]/, $datetime); 
    $dateparts[4]--;
    my $time = timelocal( @dateparts );
    $time += (24*3600);
    my $plus_one = localtime($time);

    $sth->execute( $datetime, $plus_one->datetime );
    $counts{ $datetime } = $sth->fetchrow_array;
  }   

  return (scalar keys %counts == 1) ?
              $counts{ $dates[0] } : 
              \%counts;
  
} # end sub

=method count_daily_new_memberships( @list_of_dates )

Returns the number of Memberships in the set that were
created in the 24-hour period beginning with
the date supplied. Takes dates in ISO-ish format.

Returns a scalar when called with one date.

Can also be called with an array of date-times, in which case it will return a
reference to a hash indexed by the same date-time string, using the count for
the values.

=cut

sub count_daily_new_memberships {
  my $self = shift;
  my @dates = @_;
  my %counts;

  my $sql = qq/ 
    SELECT COUNT(DISTINCT mid)
    FROM membership_entity
    WHERE created >= ?
    AND created < ?
    AND status NOT IN (3)
  /;

  my $sth = $self->{'dbh'}->prepare( $sql );

  foreach my $datetime (@dates) {

    my @dateparts = reverse (split /[-| |T|:]/, $datetime);
    $dateparts[4]--;
    my $time = timelocal( @dateparts );
    my $plus_one = ($time + (24*3600));
    $sth->execute( $time, $plus_one );
    $counts{ $datetime } = $sth->fetchrow_array;
  }

  return (scalar keys %counts == 1) ?
              $counts{ $dates[0] } :
              \%counts;

} # end sub

=method count_daily_new_terms( @list_of_dates )

Returns the number of Terms (belonging to Memberships
in the set) that were created in the 24-hour 
period beginning with the date supplied. Takes dates
in ISO-ish format.

Returns a scalar when called with one date.

Can also be called with an array of date-times, in which case it will return a
reference to a hash indexed by the same date-time string, using the count for
the values.

=cut

sub count_daily_new_terms {
  my $self = shift;
  my @dates = @_;
  my %counts;

  my $sql = qq/ 
    SELECT COUNT(DISTINCT mid)
    FROM membership_entity_term
    WHERE created >= ?
    AND created < ?
    AND status NOT IN (3)
  /;

  my $sth = $self->{'dbh'}->prepare( $sql );

  foreach my $datetime (@dates) {

    my @dateparts = reverse (split /[-| |T|:]/, $datetime);
    $dateparts[4]--;
    my $time = timelocal( @dateparts );
    my $plus_one = ($time + (24*3600));
    $sth->execute( $time, $plus_one );
    $counts{ $datetime } = $sth->fetchrow_array;
  }

  return (scalar keys %counts == 1) ?
              $counts{ $dates[0] } :
              \%counts;

} # end sub


=method historical_active_memberships( @list_of_dates )

Returns the number of Memberships within the set with status of 'active' on a
given date in history, by comparing the date with the start and end dates
of the Membership's Terms.

Takes a date-time or a range of date-times in the ISO-ish format
yyyy-dd-mmThh:mm:ss, such as 2001-01-01T12:00:00  

Returns a scalar value when called with one date.

Can also be called with an array of date-times, in which case it will return a 
reference to a hash indexed by the same date-time string, using the count for
the values.

If you are forensically building a record of your Memberships, you should probably
set the time element of your date(s) to 00:00:00, since the search looks for Terms
with a start date <= and an end date > the date given and this strategy will give
a daily report that is closest to the historical truth.

Note that this report may not be 100% accurate, as data in the DB may have changed
since a given date, particularly the status of Terms. 

=cut

sub historical_active_memberships {
  my $self = shift;
  my @dates = @_;
  my %counts;

  my $sql = qq/
    SELECT COUNT(DISTINCT mid)
    FROM membership_entity_term
    WHERE start <= ? AND end > ?
    AND status NOT IN (2,3)
  /;

  my $sth = $self->{'dbh'}->prepare( $sql );

  foreach my $date (@dates) {
    $sth->execute( $date, $date );
    $counts{ $date } = $sth->fetchrow_array;
  }

  return (scalar keys %counts == 1) ?
           $counts{ $dates[0] } :
           \%counts;

} # end sub


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

=head1 DESCRIPTION

This module provides some basic statistical analysis about your Drupal
site Memberships. It operates on the set of Memberships contained in 
$ME->{'_memberships'} in other words whichever ones you fetched with
your call to $ME->fetch_memberships().

It has some methods for doing retroactive reporting on the DB records
so you can initialize a reporting system with some statistical
baselines. 
