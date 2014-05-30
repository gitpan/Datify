#! /usr/bin/env perl

use v5.14;

use lib '../lib';

use Data::Dumper ();
use Datify       ();
use Perl::Tidy   ();
use Scalar::Util qw(reftype);

=head1 NAME

comparison.pl - A script to show the differences between Datify
and Data::Dumper

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

sub beautify {
    my $source = shift;

    my ($dest, $stderr);
    Perl::Tidy::perltidy(
        argv => [ qw(
            --noprofile
            --nostandard-output
            --standard-error-output
            --nopass-version-line
            --maximum-line-length=70
        ) ],
        source      => \$source,
        destination => \$dest,
        stderr      => \$stderr,
        errorfile   => \$stderr,
    ) && die 'ERROR: ', $stderr;

    return $dest;
}

=head1

=cut

sub dumper {
    my ( $name, $value ) = @_;

    my $ref = ref $value && reftype $value;
    return "Cannot handle $ref" if 'IO' eq $ref;

    # Confiugre Data::Dumper to be as much like Datify as possible
    my $source
        = Data::Dumper->new( [$value], [ '*' . $name ] )
            ->Indent(0)
            ->Pad(' ')
            ->Purity(0)
            ->Quotekeys(0)
            ->Sortkeys(1)
            ->Useqq(1)
            ->Dump;

    return $source;
}

=head1

=cut

sub datify {
    my ( $name, $value ) = @_;

    # Setting quote to '"' is the equivalent of $Data::Dumper::Useqq = 1
    #my $source = Datify->new( quote => '"' )->varify( $name => $value );
    my $source = Datify->new->varify( $name => $value );

    return $source;
}

=head1

=cut

foreach my $name
    ( sort { length $a <=> length $b or $a cmp $b } grep !/^_</, keys %main:: )
{
    next if $name eq 'main::'; # Avoid unnecessary recursion

    my ( @types, @values );
    foreach my $type (
        qw(ARRAY CODE FORMAT GLOB HASH IO LVALUE REF Regexp SCALAR VSTRING))
    {
        no strict 'refs';
        if ( my $ref = ref( my $value = *{$name}{$type} ) ) {
            say "$name : $type => $ref" if $ref ne $type;
            $value = $$value if $type eq 'SCALAR';
            push @types, $type;
            push @values, $value;
        }
    }
    print "$name = ", join( ', ', @types ), "\n";
    foreach my $value (@values) {
        print 'Datify: ', beautify( datify( $name => $value ) );
        print 'Dumper: ', beautify( dumper( $name => $value ) );
    }
    print "\n";
}

