package Filter::Url;

use strict;
use warnings;
use utf8;

our $VERSION = 0.0.1;

use autouse 'Carp' => qw(carp croak);
use DBI;

use Data::Dumper;

use Object::Botox qw(new);

# yes! we are have properies
our $object_prototype = {
						'dbh_ro' 	=> undef, 	# dbh object
						'database_ro' 	=> undef,	# database prop
						'table_ro'		=> undef,	# table for urls
						};


=pod
Method: init
	инициализирует коннект к базе и добавлет его к своему свойству(объекта).
Parameter:
    $url|($url,) - ссылки для проверки
    скаляр или список
Returns:
    $url|($url,) - уникальные ссылки для обработки
    скаляр или список
=cut
sub init{
	my $self = shift;
	
	my $dbh = DBI->connect_cached("dbi:SQLite(sqlite_unicode=>1):dbname=".$self->database,"","",
							{AutoCommit => 0, PrintError => 1}) or die $DBI::errstr;
	$self->dbh($dbh);
	return 1;
}


# по идее тут будет 2 метода - 
# 1) проверка уникальности ссылок (списка ссылок)
# 2) сохранение в базу ссылок, когда страница обработана, для проверки п.1


=pod
Method: getUniqueUrl
	возвращет ссылки, являюшиеся уникальными
Parameter:
    $url|($url,) - ссылки для проверки
    скаляр или список
Returns:
    $url|($url,) - уникальные ссылки для обработки
    скаляр или список
    ИЛИ undef при пустом входящем
=cut
sub getUniqueUrl{
	my ( $result, $self, @urls ) = ( undef, @_ );
	
	return undef if ( $#urls == -1 );
	# жмем входяший список в уникальные
	my %seen = ();
	my @unique = grep { ! $seen{$_} ++ } @urls;
	
	my $placeholder = join (', ', split ('', ( '?' x ( $#unique + 1 ) ) ));	
	my $sql = "SELECT DISTINCT url FROM ".$self->table." WHERE url IN ( $placeholder );";

	my $dbh = $self->dbh;
	my $exist_urls = $dbh->selectall_hashref( $sql, 'url', {}, @unique );
	
	# фильтруем данные, благо у нас есть хеш записей.
	do { push @$result, $_ unless $exist_urls->{$_} } for @unique;
	
	return @$result;
}


=pod
Method: saveNewUrl
	сохраняет в базе новые ссылки
Parameter:
    $url|($url,) - ссылки для проверки
    скаляр или список
Returns:
    1 - успешно, undef - неуспешно
Meditation:
	с одной стороны sql-кусок в фильтре нуждается в ДБ объекте,
	с другой стороны - а нужна ли такая глубокая абстракция?
	- возрастание накладных расходов на передачу и ветвление 
=cut
sub saveNewUrl{
	my ( $self, @urls ) = @_;
	
	my $dbh = $self->dbh;
	my $sql = "INSERT INTO ".$self->table."(url) values (?);";
	
	my $sth = $dbh->prepare_cached($sql);
	# теоретически это самый быстрый способ инсерта
  	my $tuples = $sth->execute_array(
      				{ ArrayTupleStatus => \my @tuple_status }, \@urls);
  	if ( $tuples ) {
		$dbh->commit();
	}
	else {
		  for my $tuple (0..$#urls) {
			  my $status = $tuple_status[$tuple];
			  $status = [0, "Skipped"] unless defined $status;
			  next unless ref $status;
			  printf "Failed to insert (%s): %s\n",
				  $urls[$tuple], $status->[1];
		  }
		  return undef;
	 }	
	return 1;	
}


1;