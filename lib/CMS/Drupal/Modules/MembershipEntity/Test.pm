package CMS::Drupal::Modules::MembershipEntity::Test;


# ABSTRACT: Exports some helper routines for testing

use 5.010;
use base "Exporter::Tiny";
our @EXPORT = qw/ build_test_db
                  build_and_validate_test_db
                  build_test_data /;

use Data::Dumper;
use Carp qw/ croak confess /;
use Test::More;
use Test::Group;
use File::Slurp::Tiny qw/ read_file read_lines /;
use FindBin;
use Time::Local;

sub build_and_validate_test_db {

  ## Reads the test data from .dat files and
  ## builds an in-memory SQLite database

  ## This package expects to be used in a program
  ## running in the test directory ...
  
  my $drupal = shift;
  my $dbh;

  subtest 'Built the test database' => sub {
    
    plan tests => 5;
    $dbh = $drupal->dbh( database => ':memory:',
                         driver   => 'SQLite' );

    isa_ok( $dbh, 'DBI::db', 'Got a valid $dbh' );

    subtest 'Created the test database tables.' => sub {
      plan tests => 4;
      for (split( /\n{2,}/, read_file("$FindBin::Bin/data/test_db.sql") )) {
        my $rv = $dbh->do($_);
        isnt( $rv, undef, 'Added a table to the test database' );
      }   
    };  

    #########
    # Populate the test database
  
    # First we have to have a default type
    my $add_type = qq/
      INSERT INTO membership_entity_type (type, label, weight, description, data, status, module)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    /;
  
    my @fields = split(',', read_file("$FindBin::Bin/data/test_types.dat")) or croak; # This file must have only ONE line
  
    my $add_type_rv = $dbh->do( $add_type, {}, @fields, undef );
    cmp_ok( $add_type_rv, '>', 0, 'Populate the membership_entity_type table with a default type' );
  
    ## Now add Memberships from the data file
    my $add_mem = qq/
      INSERT INTO membership_entity (mid, member_id, type, uid, status, created, changed)
      VALUES ( ?, ?, ?, ?, ?, ?, ?)
      /;
  
    test 'Populate the membership_entity table with test data' => sub {
      for ( read_lines("$FindBin::Bin/data/test_memberships.dat",  chomp => 1 ) ) {
        my @fields = split(',');
        my $add_mem_rv = $dbh->do( $add_mem, {}, @fields );
        cmp_ok( $add_mem_rv, '>', 0, "Added a Membership for mid $fields[0]" );
      }
    };
  
    ## Now add Membership Terms from the data file
    my $add_term = qq/
      INSERT INTO membership_entity_term(id, mid, status, term, modifiers, start, end )
      VALUES (?, ?, ?, ?, ?, ?, ?)
      /;
  
    test 'Populate the membership_entity_term table with test data' => sub {
      for ( read_lines("$FindBin::Bin/data/test_terms.dat",  chomp => 1 ) ) {
        my @fields = split(',');
        my $add_term_rv = $dbh->do( $add_term, {}, @fields );
        cmp_ok( $add_term_rv, '>', 0, "Added a Term for $fields[0]" );
      }
    };
  }; # done building the test DB

  $dbh->sqlite_backup_to_file("$FindBin::Bin/data/.test_db.sqlite");

  return $dbh;
}

sub build_test_db {

  ## No testing here!

  ## Reads the test data from .dat files and
  ## builds an in-memory SQLite database


  my $drupal = shift;
  my $dbh = $drupal->dbh( database => ':memory:',
                          driver   => 'SQLite' );

  for (split( /\n{2,}/, read_file("$FindBin::Bin/data/test_db.sql") )) {
    my $rv = $dbh->do($_);
  }

  # First we have to have a default type
  my $add_type = qq/
    INSERT INTO membership_entity_type (type, label, weight, description, data, status, module)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  /;

  my @fields = split(',', read_file("$FindBin::Bin/data/test_types.dat")) or croak; # This file must have only ONE line

  my $add_type_rv = $dbh->do( $add_type, {}, @fields, undef );

  ## Now add Memberships from the data file
  my $add_mem = qq/
    INSERT INTO membership_entity (mid, member_id, type, uid, status, created, changed)
    VALUES ( ?, ?, ?, ?, ?, ?, ?)
    /;

  for ( read_lines("$FindBin::Bin/data/test_memberships.dat",  chomp => 1 ) ) {
    my @fields = split(',');
    my $add_mem_rv = $dbh->do( $add_mem, {}, @fields );
  }

  ## Now add Membership Terms from the data file
  my $add_term = qq/
    INSERT INTO membership_entity_term(id, mid, status, term, modifiers, start, end )
    VALUES (?, ?, ?, ?, ?, ?, ?)
    /;

  for ( read_lines("$FindBin::Bin/data/test_terms.dat",  chomp => 1 ) ) {
    my @fields = split(',');
    my $add_term_rv = $dbh->do( $add_term, {}, @fields );
  }

  return $dbh;
} 

############################

sub build_test_data {

  my $mids = shift;
  my %include;
  for( @$mids ) {
    $include{ $_ }++;
  }
 
  my %membs;
  my %terms;

  for ( read_lines("$FindBin::Bin/data/test_memberships.dat", chomp => 1) ) {
    my @fields = split(',');
    if (scalar @$mids > 0) { next unless exists $include{ $fields[0] }; }
    $membs{ $fields[0] } = { mid       => $fields[0],
                             member_id => $fields[1],
                             type      => $fields[2],
                             uid       => $fields[3],
                             status    => $fields[4],
                             created   => $fields[5],
                             changed   => $fields[6] };
  }

  my %term_count;

  for ( read_lines("$FindBin::Bin/data/test_terms.dat", chomp => 1) ) {
    my @fields = split(',');
    if (scalar @$mids > 0) { next unless exists $include{ $fields[1] } };
    $term_count{ $fields[1] }++;
    for (5..6) {
      my @datetime = reverse (split /[-| |:]/, $fields[ $_ ]);
      $datetime[4]--;
      $fields[ $_ ] = timelocal( @datetime );
    }
    $terms{ $fields[0] } = bless(
                          { tid            => $fields[0],
                            mid            => $fields[1],
                            status         => $fields[2],
                            term           => $fields[3],
                            modifiers      => $fields[4],
                            start          => $fields[5],
                            end            => $fields[6],
                            array_position => $term_count{ $fields[1] } },
                          'CMS::Drupal::Modules::MembershipEntity::Term' );
  }

  while ( my ($tid, $term) = each %terms ) {
    $membs{ $term->{'mid'} }->{'terms'}->{ $tid } = $term;
  }

  foreach my $mem ( keys %membs ) {
    $membs{ $mem } = bless( $membs{ $mem }, 'CMS::Drupal::Modules::MembershipEntity::Membership' );
  }

  return \%membs;
}

1; # End package

=pod

=head1 SYNOPSIS

 use Test::More;
 use CMS::Drupal;
 use CMS::Drupal::Modules::MembershipEntity::Test qw/ build_test_db build_test_data/;

 my $drupal = CMS::Drupal->new;

 my $dbh = build_test_db( $drupal );

 my $ME = CMS::Drupal::Modules::MembershipEntity->new( dbh => $dbh );

 my $hashref = $ME->fetch_memberships;
 my $cmp_data = build_test_data;

 # or:
 
 my $hashref = $ME->fetch_memberships([ 1234, 5678 ]);
 my $cmp_data = build_test_data([ 1234, 5678 ]);

 is_deeply($hashref, $cmp_data, 'Data matches'); 

=head1 DESCRIPTION

Use this module when testing the CMS::Drupal::Modules::MembershipEntity modules.

=head2 Methods

=head3 build_test_db

This method returns a database handle ($dbh) that is connected to an in-memory SQLite database.
The database is built by this method using data files that must be contained in the same directory that
the calling script lives in.

The method takes one argument, which must be a $drupal object. This is because it calls $drupal->dbh()
to generate its database handle, which, because we are using SQLite, contains the database inside the 
very handle itself.

The files are:

=over 4

=item test_db.sql

=item test_types.dat

=item test_memberships.dat

=item test_terms.dat

=back

Note that this method uses Test::More and Test::Group itself to report success/failures in building
the test database. So in your scipt that calls this method you should add one additional test to
your plan.

=head3 build_test_data

This method returns a data structure containing the Memberships as they would be returned by
CMS::Drupal::Modules::MembershipEntity::fetch_memberships(). It creates the data structure
by parsing the same files that were used to build in test database.

The method takes an optional single argument, which is an arrayref containing a list of B<mid>s.
Only the Memberships associated with the B<mid>s provided will; be included in the data
returned.

 $cmp_data = build_test_data( [ 1234, 5678 ] );

The data structure is a hashref of hashrefs (Membership objects, indexed by mid, containing
among their attributes an array of hashrefs (Membership Term objects) ...

 '4086' => bless( {
                   'created' => '1354086000',
                   'mid' => '4086',
                   'changed' => '1400604379',
                   'uid' => '12305',
                   'status' => '1',
                   'member_id' => '01252',
                   'terms' => {
                               '4088' => bless( {
                                                 'mid' => '4086',
                                                 'array_position' => 2,
                                                 'status' => '1',
                                                 'modifiers' => 'a:0:{}',
                                                 'end' => 1448611200,
                                                 'start' => 1354089600,
                                                 'term' => 'import',
                                                 'tid' => '4088'
                                                }, 'CMS::Drupal::Modules::MembershipEntity::Term' ),
                               '3920' => bless( {
                                                 'mid' => '4086',
                                                 'array_position' => 1,
                                                 'status' => '0',
                                                 'modifiers' => 'a:0:{}',
                                                 'end' => 1403247600,
                                                 'start' => 1308639600,
                                                 'term' => 'import',
                                                 'tid' => '3920'
                                                }, 'CMS::Drupal::Modules::MembershipEntity::Term' )
                              },
                   'type' => 'membership'
                  }, 'CMS::Drupal::Modules::MembershipEntity::Membership' ),
 

=cut


