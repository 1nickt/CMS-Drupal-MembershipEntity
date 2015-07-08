package CMS::Drupal::Modules::MembershipEntity::Test;


# ABSTRACT: Exports some helper routines for testing

use base "Exporter::Tiny";
our @EXPORT = qw/ build_test_db build_test_data /;

use Data::Dumper;
use Carp qw/ croak confess /;
use Test::More;
use Test::Group;
use File::Slurp::Tiny qw/ read_file read_lines /;
use FindBin;
use Time::Local;

sub build_test_db {

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
      for (split( /\n{2,}/, read_file("$FindBin::Bin/test_db.sql") )) {
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
  
    my @fields = split(',', read_file("$FindBin::Bin/test_types.dat")) or croak; # This file must have only ONE line
  
    my $add_type_rv = $dbh->do( $add_type, {}, @fields, undef );
    cmp_ok( $add_type_rv, '>', 0, 'Populate the membership_entity_type table with a default type' );
  
    ## Now add Memberships from the data file
    my $add_mem = qq/
      INSERT INTO membership_entity (mid, member_id, type, uid, status, created, changed)
      VALUES ( ?, ?, ?, ?, ?, ?, ?)
      /;
  
    test 'Populate the membership_entity table with test data' => sub {
      for ( read_lines("$FindBin::Bin/test_memberships.dat",  chomp => 1 ) ) {
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
      for ( read_lines("$FindBin::Bin/test_terms.dat",  chomp => 1 ) ) {
        my @fields = split(',');
        my $add_term_rv = $dbh->do( $add_term, {}, @fields );
        cmp_ok( $add_term_rv, '>', 0, "Added a Term for $fields[0]" );
      }
    };
  }; # done building the test DB

  return $dbh;
}


sub build_test_data {

  my %membs;
  my %terms;

  for ( read_lines("$FindBin::Bin/test_memberships.dat", chomp => 1) ) {
    my @fields = split(',');
    $membs{ $fields[0] } = { mid       => $fields[0],
                             member_id => $fields[1],
                             type      => $fields[2],
                             uid       => $fields[3],
                             status    => $fields[4],
                             created   => $fields[5],
                             changed   => $fields[6] };
  }

  my %term_count;

  for ( read_lines("$FindBin::Bin/test_terms.dat", chomp => 1) ) {
    my @fields = split(',');
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

