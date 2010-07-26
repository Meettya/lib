package Store::Local;

use strict;
use warnings;
use utf8;

our $VERSION = 0.0.1;

use autouse 'Carp' => qw(carp croak);

use Object::Botox qw(new);

use DBI;

# yes! we are have properies
our $object_prototype = {
						'dbh_ro' 	=> undef, 	# dbh object
						'database_ro' 	=> undef,	# database prop
						'table_ro'		=> undef,	# table for urls
						};

my %err = ( 
		db_name => 'Need database (name) for init Store::Local',
		table_name => 'Need table (name) for init Store::Local'
		);

=pod
Method: init
	инициализирует коннект к базе и добавлет его к своему свойству (объекта).
Parameter:
	database && table as $self prop
Returns:

=cut
sub init{
	my $self = shift;
	
	croak $err{db_name} unless ( defined $self->database );
	croak $err{table_name} unless ( defined $self->table );
	
	my $dbh = DBI->connect_cached("dbi:SQLite(sqlite_unicode=>1):dbname=".$self->database,"","",
							{AutoCommit => 0, PrintError => 1}) or die $DBI::errstr;
	$self->dbh($dbh);
	
	my $sql = 'CREATE TABLE IF NOT EXISTS '.$self->table.'
				(url text NOT NULL,
				cdate TEXT  DEFAULT (CURRENT_TIMESTAMP));';

	$dbh->do( $sql ) or croak $dbh->errstr;
	$dbh->commit() or croak $dbh->errstr;
	
	return 1;
}

=pod
Method: saveList
	сохраняет в базе новые ссылки
Parameter:
   $urls - ссылки для проверки ( arrayref )
Returns:
    1 - успешно, undef - неуспешно
=cut			
sub saveList($$){

	my ( $self, $urls ) = @_;
	
	my $dbh = $self->dbh;
	my $sql = "INSERT INTO ".$self->table."(url) values (?);";
	
	my $sth = $dbh->prepare_cached($sql);
	# теоретически это самый быстрый способ инсерта
  	my $tuples = $sth->execute_array(
      				{ ArrayTupleStatus => \my @tuple_status }, $urls );
  	if ( $tuples ) {
		$dbh->commit();
	}
	else {
		  for my $tuple (0..$#{$urls}) {
			  my $status = $tuple_status[$tuple];
			  $status = [0, "Skipped"] unless defined $status;
			  next unless ref $status;
			  printf "Failed to insert (%s): %s\n",
				  $urls->[$tuple], $status->[1];
		  }
		  return undef;
	 }	
	return 1;	
}


=pod
Method: getUniqueList
	возвращет ссылки, являюшиеся уникальными
Parameter:
    $urls - ссылки для проверки ( arrayref )
Returns:
	undef при пустом входящем или отсутствии уникальных
		ИЛИ
	$result - уникальные ссылки ( arrayref )
=cut
sub getUniqueList($$){
	
	my ( $result, $self, $urls ) = ( undef, @_ );
	
	return undef if ( $#{$urls} == -1 );
	
	my $placeholder = join (', ', split ('', ( '?' x ( $#{$urls} + 1 ) ) ));	
	my $sql = "SELECT DISTINCT url FROM ".$self->table." WHERE url IN ( $placeholder );";

	my $dbh = $self->dbh;
	my $exist_urls = $dbh->selectall_hashref( $sql, 'url', {}, @{$urls} );
	
	# фильтруем данные, благо у нас есть хеш записей.
	do { push @$result, $_ unless $exist_urls->{$_} } for @{$urls};
	
	return $result;
}

1;