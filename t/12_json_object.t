package MYAPP;
sub new {
bless {test => 1}, shift;
}
sub TO_JSON {
my $self = shift;
my %hash = map { $_ => $self->{$_} } keys %$self;
return [ ref $self , \%hash ];
}
package main;
use Test::More tests => 2;
use Cache::Redis;
use JSON;
use Test::RedisServer;

my $redis_server;
eval {
    $redis_server = Test::RedisServer->new(
        conf => {
            port      => 9999,
            databases => 16,
            save      => '900 1',
        }
    );
} or plan skip_all => 'redis-server is required to this test';

local $ENV{REDIS_SERVER} = $redis_server->connect_info;

my $json = JSON->new;
$json->convert_blessed;
my $cr = Cache::Redis->new(
    serialize_methods => [
        sub { $json->encode( +shift ) },
        sub { my $obj_dat = $json->decode( +shift ); bless $obj_dat->[1], $obj_dat->[0] }
    ],
)
;
my $key = "KEY1";
my $obj = MYAPP->new;
warn $obj->{test};
$cr->set( $key, $obj);
my $ret = $cr->get($key);
isa_ok $ret, "MYAPP";
is $ret->{test}, 1;

