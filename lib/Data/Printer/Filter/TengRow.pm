package Data::Printer::Filter::TengRow;
use strict;
use warnings;
use utf8;
use Data::Printer::Filter;
use Term::ANSIColor;

filter '-class', sub {
    my ($obj, $p) = @_;
    return unless $obj->isa('Teng::Row');

    my %kv;
    $kv{$_} = $obj->{$_} for grep { !/^_/ } keys %$obj;
    delete $kv{$_} for qw/select_columns sql table table_name/;

    return ref($obj) . p(%kv);
};

1;
