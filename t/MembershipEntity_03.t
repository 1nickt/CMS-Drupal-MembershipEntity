#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

use Test::More;
use Test::Group;
use DBI;
use FindBin;
use File::Slurp::Tiny qw/ read_file read_lines /;
use Time::Local;

use Data::Dumper;
use Carp qw/ croak confess /;

# CMS::Drupal::Modules::MembershipEntity
# test 03 - Test functions on a mock DB";

BEGIN {
  subtest "We have all our parts.\n" => sub {
    plan tests => 3;
    
    use_ok( 'CMS::Drupal' ) or die;
    use_ok( 'CMS::Drupal::Modules::MembershipEntity' ) or die;

    subtest 'All the data files exist.' => sub {
      plan tests => 4;

      for (qw/ test_db.sql test_types.dat test_memberships.dat test_terms.dat /) { 
        ok( -e "$FindBin::Bin/$_", "(we have $_)" );
        #ok( -e "$FindBin::Bin/test_db.sql", "we have $_" );
        #ok( -e "$FindBin::Bin/test_types.dat", 'we have $_' );
        #ok( -e "$FindBin::Bin/test_memberships.dat", 'we have $_' );
        #ok( -e "$FindBin::Bin/test_terms.dat", 'we have $_' );
      }
    };
  };
}

my $drupal;
my $dbh;

subtest "Built the in-memory SQLite test database.\n" => sub {

  plan tests => 5;

  $drupal = CMS::Drupal->new;
  isa_ok( $drupal, 'CMS::Drupal');

  # read the current ME database schema and make a test DB

  $dbh = $drupal->dbh( database => ':memory:',
                       driver   => 'SQLite' );

  test 'Created the test database tables.' => sub {
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

$dbh->sqlite_backup_to_file("$FindBin::Bin/out");


##########

my $ME;

subtest "Create a MembershipEntity object and check its methods.\n" => sub {
  plan tests => 3;
  
  can_ok( 'CMS::Drupal::Modules::MembershipEntity', 'new' );
  $ME = CMS::Drupal::Modules::MembershipEntity->new( dbh => $dbh);
  isa_ok( $ME, 'CMS::Drupal::Modules::MembershipEntity' );
  can_ok( 'CMS::Drupal::Modules::MembershipEntity', 'fetch_memberships' );
};

subtest "Functionality tests.\n", => sub {

  ## Make a structure from the data files and compare to what the 
  ## module's function returns
 
  my $wanted_memberships = build_cmp_data();

  my $got_memberships = $ME->fetch_memberships;

  is_deeply( $got_memberships, $wanted_memberships, '$ME->fetch_memberships is_deeply the content of the test data files.' );

};


sub build_cmp_data {

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

}; # end build_cmp_data()

say "+" x 78;

done_testing();

