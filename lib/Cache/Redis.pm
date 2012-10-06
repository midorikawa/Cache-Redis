package Cache::Redis;

use strict;
use vars qw($VERSION);
$VERSION = '0.01';
use Carp qw(croak);
use Redis;
my ( $packer, $unpacker );

sub new {
    my ( $class, %params ) = @_;

    my $server = $ENV{REDIS_SERVER}
      || ( $params{host} || '127.0.0.1' ) . ":" . ( $params{port} || 6379 );
    if ( $params{serialize_methods} ) {
        if ( ref $params{serialize_methods} ne 'ARRAY' ) {
            croak "serialize_methods is coderef onry";
        }
        croak "serialize_methods is coderef only"
          if ( ref $params{serialize_methods}->[0] ne 'CODE'
            || ref $params{serialize_methods}->[1] ne 'CODE' );

        $unpacker = $params{serialize_methods}->[1];
        $packer   = $params{serialize_methods}->[0];
    }
    my $self = {
        prefix => $params{prefix} || 'session',
        redis  => Redis->new( server => $server, encoding => $params{encodind}||undef ),
        server => $server,
        expires => $params{expires} || undef,
        serialize_methods => $params{serialize_methods}
    };

    bless $self, $class;
}

sub get {
    my ( $self, $key ) = @_;
    my $ret = $self->{redis}->get($key);
    $self->{expires} && $self->expire($key);
    $unpacker && $ret ? $unpacker->($ret) : $ret;
}

sub set {
    my ( $self, $key, $val ) = @_;
    $self->{redis}->set( $key, $packer && $val ? $packer->($val) : $val );
    $self->{expires} && $self->expire($key);
}

sub expire {
    my ( $self, $key ) = @_;
    $self->{redis}->expire( $key, $self->{expires} );
}

sub remove {
    my ( $self, $key ) = @_;
    $self->{redis}->del($key);
}

1;
__END__

=head1 NAME

Cache::Redis -

=head1 SYNOPSIS

  use Cache::Redis;

use Data::MessagePack;
my $cr = Cache::Redis->new(
    serialize_methods => [
        sub { Data::MessagePack->pack( +shift ) },
        sub { Data::MessagePack->unpack( +shift ) }
    ],
);
	or

use JSON;
my $cr = Cache::Redis->new(
	 serialize_methods => [
	sub {  encode_json(+shift)  },
	sub {  decode_json(+shift)  }
	],
);


my $key = "KEY1";
my $val = +{ "keyval" => "VAL1" };

$cr->set( $key, $val);

my $ret = $cr->get($key);

$cr->remove($key);

=head1 DESCRIPTION

Cache::Redis is

=head1 AUTHOR

tooru E<lt>tooru@omakase.org<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<>

=cut
