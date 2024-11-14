use strict;
use warnings;


package LogModel {

    sub new {
        my ($class, $dbh) = @_;
        return bless { dbh => $dbh }, $class;
    }


    sub insert {
        my ($self, $table, %data) = @_;
        #Извлчь ключи и значения из хэша
        my @fields = keys %data;
        my @values = values %data;
        #Создать строку для подстановки
        my $field_str = join(", ", @fields);
        #вернет знак "?" по кол-ву элементов в списке
        my $placeholders = join(", ", ("?") x @fields);


        my $query = "INSERT INTO $table ($field_str) VALUES ($placeholders)";


        my $sth = $self->{dbh}->prepare($query);
        if ($sth) {
            if ($sth->execute(@values)) {
              return 1;
            } else {
                Custom_exception::print_warn("Failed to execute statement: " . $sth->errstr);
                die;
            }
        } else {
            Custom_exception::print_warn("Failed to prepare statement: " . $self->{dbh}->errstr);
            die;
        }
    }

}




package LogController {
    use DBI;

    #кодирвание
    use HTML::Entities;

    sub new {
        my ($class, $model) = @_;
        return bless {
            model => $model
        }, $class;
    }

    sub process_log_file {
        my ($self, $log_file) = @_;

        open(my $fh, '<', $log_file) or die Custom_exception::print_warn("File 'out' have not found");

        while (<$fh>) {
            # для удаления символа новой строки
            chomp;
            #разбить строку, где использовать в каестве разделителя пробел (максимуму частей - 6)
            my ($date, $time, $int_id, $flag, $address, @rest) = split /\s+/, $_, 6;
            if ($date =~ /^\d{4}-\d{2}-\d{2}$/ && $time =~ /^\d{2}:\d{2}:\d{2}/) {
                my $created = "$date $time";
                my $str = join(' ', @rest);

                #экранирование
                $str = encode_entities($str);

                if ($int_id && $created) {
                    if ($flag eq "<="  && $str) {
                        my $id = get_id($str);
                        if ($id) {
                             $self->{model}->insert(
                                'message',
                                created => $created,
                                id => $id,
                                int_id =>
                                $int_id,
                                str => $str
                            );
                        } else {
                            Custom_exception::print_warn("Failed to extract ID from: $str");
                        }
                    } else {
                            $self->{model}->insert(
                                'log',
                                created => $created,
                                int_id => $int_id,
                                str => $str,
                                address => $address
                            );
                    }
                }
                # если НЕ ($int_id && $created)
                else {
                    Custom_exception::print_warn("Incomplete or invalid log entry: $_");
                    die;
                }
            }
            # неправильная дата и время
            else {
                Custom_exception::print_warn("Invalid log entry format: $_");
                die;
            }
        }

        close($fh);
    }

    sub get_id {
        my ($str) = @_;
        my ($id) = $str =~ /id=(\S+)/;
        return $id;
    }
}

package Custom_exception {
    use Email::Sender::Simple qw(sendmail);
    use Email::Sender::Transport::SMTP::TLS;

    my $RED    = "\e[1;31m";
    my $YELLOW = "\e[1;33m";
    #сбросить цвет
    my $RESET  = "\e[0m";

    sub print_warn {
        my ($message) = @_;
        print STDERR $RED . "Warning: " . $YELLOW . $message . $RESET . "\n";
    }
}



package Custom_mailer {
    use Email::Sender::Simple qw(sendmail);
    my $to =  "and_che\@mail.ru",
    my $from = "anymail\@param-param.ru",
    my $subject = 'Alert';
    my $message = 'The test script failed with an error.';

    sub mail_send {
        my $email = Email::Simple->create(
            header => [
                From => $from,
                To => $to,
                Subject => $subject,
            ],
            body => $message
        );
        sendmail($email);
    }
}


#Соединение с БД
my $db_name = 'test';
my $db_user = 'test';
my $db_pass = '324Gasdg234yhg2';
my $dbh = DBI->connect("DBI:mysql:database=$db_name", $db_user, $db_pass, {PrintError => 0, AutoCommit => 0}) or Custom_exception::print_warn("Unable to connect:$DBI::errstr");

#Создание объекта
my $model = LogModel->new($dbh);

if (!defined($model->{dbh})) {
    die;
}

my $controller = LogController->new($model);

my $log_file = 'maillog';

##инициализировать транзакцию
$dbh->begin_work;

eval {
    $controller->process_log_file($log_file);
};

if ($@) {
    #отменить транзакцию - удалить внесенные значения
    $dbh->rollback;

    #отправить оповещение о проблеме
    Custom_mailer::mail_send();
}
#сохранить состоянии тразакции
$dbh->commit;
$dbh->disconnect();
