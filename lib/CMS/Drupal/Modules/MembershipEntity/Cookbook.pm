package CMS::Drupal::Modules::MembershipEntity::Cookbook;

# ABSTRACT: Guide and tutorials for using the Perl-Drupal Membership Entity interface

=head1 SYNOPSIS

This manual contains a collection of tutorials and tips for using
the CMS::Drupal::Modules::MembershipEntity distribution.

=head1 DESCRIPTION

The individual packages in the CMS::Drupal::Modules::MembershipEntity
distribution each have their own POD of course, but the author hopes
that this documentation will help a new user put it all together.
Maybe you are a non-programmer or a non-Perl user and you are here
because you use Drupal's MembershipEntity modules and you need the
additional tools this distribution provides.

=head2 Code examples

In the interests of brevity and readability I have omitted the standard
opening lines from the code samples below. If you are copy-pasting the
examples and trying them out on your system, you should prepend the
following to each snippet:

  #!perl -w
  use strict;
  use feature 'say';

The examples also skip the "use Foo::Bar"" lines, except for those
examples in each section that specifically describe how to "use"
them. You'll need to include those lines in your code too!

Note that these examples use the feature "say" which became available in
Perl v5.10 ... you can of course replace with "print" if you like: I
prefer "say" in examples (and in my code!) because you can omit the
newlines and their quotation marks.

=head1 INSTALLATION AND TESTING

=head1 DATA ANALYSIS

The creation of this distribution was originally motivated by the lack of
tools for doing even rudimentary data analysis in Drupal's MembershipEntity
modules. This section explains the various ways it can help you with that.

=head1 Stats.pm

The main tool for analyzing your Membership base is the module
L<CMS::Drupal::Modules::MembershipEntity::Stats|Stats>.

=head2 Usage and Importing Methods

Start out by using Stats.pm in your program after you have loaded
the MembershipEntity modules as decribed above.

Notice that because Stats.pm exports all its useful methods, you can
import them into MembershipEntity.pm and thus make them available in
your $ME object:

  #! perl -w
  use strict;
  use CMS::Drupal;
  use CMS::Drupal::Modules::MembershipEntity;
  use CMS::Drupal::Modules::MembershipEntity::Stats
       { into => 'CMS::Drupal::Modules::MembershipEntity' };
  
  my $drupal = CMS::Drupal->new;
  my $dbh    = $drupal->dbh;
  my $ME = CMS::Drupal::Modules::MembershipEntity->new( dbh => $dbh );
  $ME->fetch_memberships('all');

  my $active = $ME->count_active_memberships;
  say "We have $active active Memberships";

=head2 Types of methods

The methods in Stats.pm can be grouped into three basic categories,
which are signalled through the prefix of the methods' names:

=for :list
* count_
These methods may be called with or without a set of Memberships. If
called without a set (see below), they will operate on all your
Memberships.
* count_set_
These methods B<must> be called with a set of Memberships.
* count_daily_
These methods B<must> be called with a range of dates (see below), and
may be called with a set of Memberships (see below).

=head2 Working with a set of Memberships

Methods whose names begine with the prefix 'count_set_' must be called
with a set of Memberships, even if you want all Memberships included.
The set of Memberships is already contained in your MembershipEntity
object if you called fetch_memberships() on your MembershipEntity object
as described above:

  my @mids = ( 123, 456, 665, 667 );
  $ME->fetch_memberships( @mids );

or

  $ME->fetch_memberships('all');

If you do not call fetch_memberships() first, calling a method whose
name begins with the prefix 'count_set_' will cause your program to
die.

On the other hand, if you want to limit the statistics returned by
a 'count_' method or 'count_daily_' method to a subset of your 
Memberships, you can do so by first calling fetch_memberships() with
a list of mids.

=head2 Performance

For reasons of performance, and especially if you have a lot of 
Memberships, you should use Stats.pm B<without> first calling
fetch_memberships(), if you do not need to use any of the 
count_set_*() methods. This is because it will get its counts
by querying the database directly rather than by instantiating several
objects for each Membership.

If you are working with stats for your entire Membership base, you
should therefore not call fetch_memberships(). If you want to use
the count_set_*() methods on all your Memberships, you will have to 
call fetch_memberships('all') first, but you can then remove the set
and go back to the fast methods as shown below

  my $all = $ME->count_all_memberships; # fast
  
  # load the Memberships into a hashref
  $ME->fetch_memberships('all');
 
  # get a count that calls methods on the objects
  my $num = $ME->count_set_were_renewal_memberships();
  
  delete $ME->{'_hashref'};

  my $active = $ME->count_active_memberships; # back to the fast way

=head2 Working with dates

The methods in Stats.pm whose names begin with the prefix count_daily_
return counts for a date or range of dates. They can be optionally
limited to search on a set of Memberships if the fetch_memberships()
method is called in advance. These methods take dates in ISOish
format, i.e. something like:

  2001-01-01T12:00:00

(called ISO-ish because there is no time zone, as the ISO 8601 format
specifies).

You can use these methods to look at a date in the past:

  my $num =
    $ME->count_daily_expired_memberships('2015-06-15T00:00:00');

or at a range of dates:

  my $counts =
    $ME->count_daily_expired_memberships('2015-06-15T00:00:00',
                                         '2015-07-15T00:00:00',
                                         '2015-08-15T00:00:00');
  
  while (my ($date, $count) = each %{ $counts }) {
    $quarterly_total += $count;
    ...
  }

=head3 What time to use?

If you are forensically building a record of your Memberships, you
should probably set the time element of your date(s) to 00:00:00,
since the searchlooks for Terms with a start date <= and an end
date > the date given, and this strategy will give a daily report
that is closest to the historical truth if you store your statistics
indexed by a date.

=head3 Building a range of dates

Working with dates can be cumbersome, and typing them manually is
prone to errors. The Stats.pm module provides a method to build an
array of datetime strings that you can pass to its other methods.a

You call it with either one or two dates: the first is required
and is the start date in the range. The second argument, if provided,
is used for the end date in the range. If no end date is provided,
the module will use today's date. Times are set to 00:00:00 and 
daylight savings time adjustments are clobbered, for now.

  my @dates = $ME->build_date_range('2014-01-01','2014-12-31');
  # one year's worth of dates

  my @dates = $ME->build_date_range('2001-01-01);
  # Every date in the millenium so far

=head3 An example

Here's an example of a simple program that reports the previous
week's statistics.

   1 #! perl -w
   2 use strict;
   3 use Time::Local;
   4 use Time::Piece;
   5 
   6 use CMS::Drupal;
   7 use CMS::Drupal::Modules::MembershipEntity;
   8 use CMS::Drupal::Modules::MembershipEntity::Stats
   9       { into => 'CMS::Drupal::Modules::MembershipEntity' };
  10       
  11 my $drupal = CMS::Drupal->new;
  12 my $dbh    = $drupal->dbh;
  13 my $ME = CMS::Drupal::Modules::MembershipEntity->new({dbh => $dbh});
  14         
  15 my $now  = localtime;
  16 my $day  = $now - (86400*7);
  17 my @days = $ME->build_date_range(join '-', 
  18                                   $day->year,
  19                                   $day->mon,
  20                                   $day->mday );
  21                                   
  22 my $report = <<EOT;
  23 MembershipEntity Report
  24 ---------------------------
  25 Date        Exp New Active
  26 ---------------------------
  27 EOT
  28 
  29 my $exp = $ME->count_daily_term_expirations( @days );
  30 my $new = $ME->count_daily_new_terms( @days );
  31 my $act = $ME->count_daily_active_memberships( @days );
  32 
  33 foreach my $date ( @days ) {
  34   my @line = substr $date, 0, 10;
  35   for ( $exp, $new, $act ) {
  36     push @line, $_->{ $date };
  37   } 
  38   $report .= (join ' | ', @line) . "\n";
  39 } 
  40 $report .= '-' x 25 . "\n";
  41 
  42 print $report;
  43 
  44 __END__
 
This program outputs something like:

  MembershipEntity Report
  ---------------------------
  Date        Exp New Active
  ---------------------------
  2015-07-09 | 0 | 0 | 580
  2015-07-10 | 0 | 0 | 580
  2015-07-11 | 0 | 1 | 580
  2015-07-12 | 0 | 1 | 580
  2015-07-13 | 1 | 0 | 581
  2015-07-14 | 0 | 1 | 580
  2015-07-15 | 1 | 0 | 580
  2015-07-16 | 0 | 0 | 580
  -------------------------
 

Now all you have to do is get the data for multiple weeks, sum
up the daily totals for the week, and you have the beginnings
of a useful report!

=cut




1; # return true
__END__


