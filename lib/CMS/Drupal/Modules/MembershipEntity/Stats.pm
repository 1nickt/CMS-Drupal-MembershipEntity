package CMS::Drupal::Modules::MembershipEntity::Stats;

# ABSTRACT: Generate statistics about MembershipEntity memberships on a Drupal site. 

use Moo;
use Types::Standard qw/ :all /;
use base 'Exporter::Tiny'; 
our @EXPORT = qw/
  count_all_memberships
  count_expired_memberships
  count_active_memberships
  count_cancelled_memberships
  count_pending_memberships
  count_set_were_renewal_memberships
  count_daily_term_expirations
  count_daily_term_activations
  count_daily_new_memberships
  count_daily_new_terms
  count_daily_active_memberships
  build_date_range
/;
use Time::Local;
use Time::Piece;

use CMS::Drupal::Modules::MembershipEntity::Membership;

use Data::Dumper;
use Carp qw/ carp croak /;
# use feature qw/ say /;

has dbh    => ( is => 'ro', isa => InstanceOf['DBI::db'], required => 1 );
has prefix => ( is => 'ro', isa => Maybe[Str] );

=method count_all_memberships()

Returns the number of Memberships in the set.

=cut

sub count_all_memberships {
  my $self = shift;
  if ($self->{'_memberships'}) {
    $self->{'stats'}->{'_count_all_memberships'} = scalar keys %{$self->{'_memberships'}};
  } else {
    my $sql = q{ SELECT COUNT(mid) FROM membership_entity };
    $self->{'stats'}->{'_count_all_memberships'} = $self->{'dbh'}->selectrow_array($sql);
  }
  return $self->{'stats'}->{'_count_all_memberships'};
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

=method count_set_were_renewal_memberships()

Returns the number of Memberships from the set whose current Term was a renewal.

Dies if $ME->{'_memberships'} is not defined.

=cut

sub count_set_were_renewal_memberships {
  my %fake;
  my $self = shift;
  if ($self->{'_memberships'}) {
    $self->{'_count_were_renewal_memberships'} = 0;
    while ( my ($mid, $mem) = each %{$self->{'_memberships'}} ) {
      if ( $mem->current_was_renewal ) {
        $fake{$mem->{mid}} = 1;
        $self->{'_count_were_renewal_memberships'}++;
      }
    }
  } else {
    croak qq/
      Died.
      count_were_renewal_memberships() must be called with a set of
      Memberships. You probably forgot to call fetch_memberships()
      on your MembershipEntity object before calling this method.
    /;
  }
  return \%fake;
  #return $self->{'_count_were_renewal_memberships'};
}

=method count_daily_term_expirations( @list_of_dates )

Returns the number of Membership Terms belonging to Members
in the set that expired in the 24-hour period beginning with
the date supplied. Takes dates in ISO-ish format.

Returns a scalar when called with one date, or a hashref of counts
indexed by dates, if called with an array of date-times.

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

Returns the number of Membership Terms belonging to Members in the
set that began in the 24-hour period beginning with the date
supplied. Takes dates in ISO-ish format.

Returns a scalar value when called with one date, or a hashref of
counts indexed by dates, if called with an array of date-times.

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

Returns the number of Memberships in the set that were created in the
24-hour period beginning with the date supplied. Takes dates in ISO-ish
format.

Returns a scalar value when called with one date, or a hashref of
counts indexed by dates, if called with an array of date-times.

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

Returns the number of Terms (belonging to Memberships in the set)
that were created in the 24-hour period beginning with the date
supplied.

Returns a scalar value when called with one date, or a hashref of
counts indexed by dates, if called with an array of date-times.

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


=method count_daily_active_memberships( @list_of_dates )

Returns the number of Memberships within the set with status of
'active' on a given date, or range of dates. Takes a date-time
or a range of date-times in ISO-ish format.

Returns a scalar value when called with one date, or a hashref of
counts indexed by dates, if called with an array of date-times.

Note that this report may not be 100% accurate, as data in the DB
may have changed since a given date,particularly the status
of Terms.

=cut

sub count_daily_active_memberships {
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

=method build_date_range

Builds a range of dates in ISO 8601 format. Takes dates in YYYY-MM-DD
format. First date is the earliest date in the range. Second date is
the latest date in the range: if omitted, this defaults to today's
date. Returns and array of datetime strings.

=cut

sub build_date_range {

  my $self  = shift;
  my $start = shift;
  my $end   = shift;
  
  my @start = reverse (split /-/, $start);
  $start[1]--;
  unshift @start, 00, 00, 00; 
  
  my @end;
  if ($end) {
    @end = reverse (split /-/, $end);
    $end[1]--;
    unshift @end, 00, 00, 00; 
  } else {
    my $t = localtime;
    @end = ('00', '00', '00', $t->mday, $t->_mon, $t->year);
  }
  
  my $now = timelocal( @end );
  my $then = timelocal( @start );

  my @dates;

  while ($then <= $now) {
    my $t   = localtime( $then );

    #    if ( $t->isdst ) { 
    #  $t -= 3600;
    #}   

    push @dates, $t->datetime;

    $then += 86400;
  }

  return @dates;

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

See L<CMS::Drupal::Modules::MembershipEntity::Cookbook|the Cookbook>
for more information and examples of usage.

