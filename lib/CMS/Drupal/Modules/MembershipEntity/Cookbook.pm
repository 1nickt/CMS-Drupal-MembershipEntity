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

If you do not call fetch_memberships() first, these methods will
cause your program to die.

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



=cut




1; # return true
__END__


