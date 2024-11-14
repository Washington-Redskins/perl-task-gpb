package Model;

use strict;
use warnings;
use DBI;

#реализция паттерна singleton
my $instance;

sub new {
    my ($class) = @_;

    #вернуть экземпляр, если он уже был создан
    return $instance if defined $instance;
    my $self = bless {}, $class;



    my $db_name = 'test';
    my $db_user = 'test';
    my $db_pass = '324Gasdg234yhg2';
    $self->{dbh} = DBI->connect("DBI:mysql:database=$db_name", $db_user, $db_pass, { RaiseError => 1, AutoCommit => 1 }) or die "Unable to connect: $DBI::errstr\n";

    $instance = $self;

    return $self;
}



#реализция паттерна singletone
sub get_instance {
    my ($class) = @_;
    return $class->new();
}



sub search_logs {
    my ($self, $recipient) = @_;

    my $query = "SELECT message.created, message.str
                 FROM log
                 INNER JOIN message ON log.int_id = message.int_id
                 WHERE log.address = ?
                 ORDER BY message.created DESC";


    my $stmt = $self->{dbh}->prepare($query);
    $stmt->bind_param(1, "$recipient");
    $stmt->execute;

    my @results;
    while (my ($created, $str) = $stmt->fetchrow_array) {
        push @results, { created => $created, str => $str };
    }

    return \@results;
}


sub disconnect {
    my ($self) = @_;
    $self->{dbh}->disconnect if defined $self->{dbh};
}

1;
