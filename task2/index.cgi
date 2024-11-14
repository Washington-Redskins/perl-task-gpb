#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use JSON;
use lib '.';
use Model;
use View;

# Создать объект CGI-обработчика
my $cgi = CGI->new;

#заголовк для json
print $cgi->header('application/json');

eval {
    my $recipient = $cgi->param('recipient');
    die "Missing parameter" unless defined $recipient;

#получить объект Model через  реализацию singleton
    my $model = Model->get_instance();
    my $view = View->new;

    my $results = $model->search_logs($recipient);

    my $output = $view->render_results($results);

    print $output;

    $model->disconnect;
};

if ($@) {
    my $error_response = { error => "An error occurred: $@" };
    print encode_json($error_response);
}
