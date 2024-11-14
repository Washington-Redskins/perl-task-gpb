package View;

use strict;
use warnings;
use JSON;

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub render_results {
    my ($self, $results) = @_;

    my @formatted_results;
    my $count = 0;

    foreach my $result (@$results) {
        push @formatted_results, {
            created => $result->{created},
            str => $result->{str}
        };
        $count++;
        last if $count >= 100;  # Ограничение первых 100 значений
    }

#проверка по условию задачи
    my $output = {
        results => \@formatted_results,
        has_more => scalar(@$results) > 100 ? JSON::true : JSON::false,
    };

    return encode_json($output);
}

1;
