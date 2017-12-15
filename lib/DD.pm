package DD;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use Carp ();
require Data::Printer;

sub import {
    my ($class, $s) = @_;
    $s //= '';

    my ($depth) = $s =~ /(\d+)/;
    my ($deparse) = $s =~ /(d)/;

    Data::Printer->import(
        alias          => '_p',
        indent         => 1,
        deparse        => $deparse,
        max_depth      => $depth // 4,
        hash_separator => ' ',
        class          => {
            expand       => $depth // 2,
            show_methods => 'none',
            parents      => 0,
            liner_isa    => 'none',
        },
        filters => {
            -class => [\&Data::Printer::__class],
        },
    );

    my $caller = caller;
    no strict 'refs';
    *{"$caller\::p"} = \&p;
}

sub p {
    my $item = shift;
    if (!ref $item && @_ == 0) {
        my $item_value = $item;
        $item = \$item_value;
    }
    # TIPS: use Carp::Always
    Carp::carp((Data::Printer::_data_printer(!!defined wantarray, $item, @_))[0]);
}

{
    package Data::Printer;
    use Package::Stash;

    sub __class {
        my ($item, $p) = @_;
        my $ref = ref $item;

        # if the user specified a method to use instead, we do that
        if ( $p->{class_method} and my $method = $item->can($p->{class_method}) ) {
            return $method->($item, $p) if ref $method eq 'CODE';
        }

        my $string = '';
        $p->{class}{_depth}++;

        $string .= colored($ref, $p->{color}->{'class'});

        if ( $p->{class}{show_reftype} ) {
            $string .= ' (' . colored(
                Scalar::Util::reftype($item),
                $p->{color}->{'class'}
            ) . ')';
        }

        if ($p->{class}{expand} eq 'all'
            or $p->{class}{expand} >= $p->{class}{_depth}
        ) {
            $string .= "  ";
#             $string .= "  {$p->{_linebreak}";
#             $p->{_current_indent} += $p->{indent};

            if ($] >= 5.010) {
                require mro;
            } else {
                require MRO::Compat;
            }

            # Package::Stash dies on blessed XS
            eval {
                my $stash = Package::Stash->new($ref);

                if ( my @superclasses = @{$stash->get_symbol('@ISA')||[]} ) {
                    if ($p->{class}{parents}) {
                        $string .= (' ' x $p->{_current_indent})
                                . 'Parents       '
                                . join(', ', map { colored($_, $p->{color}->{'class'}) }
                                            @superclasses
                                ) . ' ';
#                                 ) . $p->{_linebreak};
                    }

                    if ( $p->{class}{linear_isa} and
                        (
                            ($p->{class}{linear_isa} eq 'auto' and @superclasses > 1)
                            or
                            ($p->{class}{linear_isa} ne 'auto')
                        )
                    ) {
                        $string .= (' ' x $p->{_current_indent})
                                . 'Linear @ISA   '
                                . join(', ', map { colored( $_, $p->{color}->{'class'}) }
                                        @{mro::get_linear_isa($ref)}
                                );
#                                 ) . $p->{_linebreak};
                    }
                }
            };
            if ($@) {
                warn "*** WARNING *** Could not get superclasses for $ref: $@"
                    unless $@ =~ / is not a module name at /;
            }

            $string .= _show_methods($ref, $p)
                if $p->{class}{show_methods} and $p->{class}{show_methods} ne 'none';

            if ( $p->{'class'}->{'internals'} ) {
#                 $string .= (' ' x $p->{_current_indent})
#                         . 'internals: ';

                local $p->{_reftype} = Scalar::Util::reftype $item;
                $string .= _p($item, $p);
#                 $string .= $p->{_linebreak};
            }

#             $p->{_current_indent} -= $p->{indent};
#             $string .= (' ' x $p->{_current_indent}) . "}";
        }
        $p->{class}{_depth}--;

        return $string;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

DD - My own Data::Printer

=head1 SYNOPSIS

    use DD ''; p($stuff);
    use DD '8d'; p($stuff);

=head1 DESCRIPTION

DD is ...

=head1 LICENSE

Copyright (C) Takumi Akiyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Takumi Akiyama E<lt>t.akiym@gmail.comE<gt>

=cut

