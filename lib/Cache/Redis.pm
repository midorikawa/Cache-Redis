package Cache::Redis;
use strict;
use vars qw($VERSION);
$VERSION = '0.03';
use Carp qw(croak);
use Redis;
my ( $packer, $unpacker, $server, $encoding );

sub new {
    my ( $class, %params ) = @_;

    $server = $ENV{REDIS_SERVER}
      || ( $params{host} || '127.0.0.1' ) . ":" . ( $params{port} || 6379 );
	$encoding = $params{encoding} || undef;
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
        redis  => Redis->new( server => $server, encoding => $encoding ),
        server => $server,
        expires => $params{expires} || undef,
        serialize_methods => $params{serialize_methods}
    };

    bless $self, $class;
}
sub _exec {
	my ($self, $cond, @args) = @_;

	my $ret = eval {$self->{redis}->$cond(@args)};
	if ($@){
		$self->{redis} = Redis->new( server => $server, encoding => $encoding );
		$ret = $self->{redis}->$cond(@args);
	}
	if ($self->{expires} and ($cond eq 'get' or $cond eq 'set')){
		$self->{redis}->expire($args[0], $self->{expires});
	}
	$ret;
}
sub get {
    my ( $self, $key ) = @_;
    my $ret = $self->_exec('get', $key);
    $unpacker && $ret ? $unpacker->($ret) : $ret;
}

sub set {
    my ( $self, $key, $val ) = @_;
    $self->_exec('set', $key, $packer && $val ? $packer->($val) : $val );
}


sub remove {
    my ( $self, $key ) = @_;
    $self->_exec('del', $key);
}

1;
__END__

=head1 NAME

Cache::Redis -

=head1 SYNOPSIS

  use Cache::Redis;

use Data::MessagePack;
my $cr = Cache::Redis->new(
	expires => 86400,
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
