package MYAPP;
sub new {
bless {test => 1}, shift;
}

package main;
use Test::More tests => 2;
use Cache::Redis;
use Storable;
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


my $cr = Cache::Redis->new(
    serialize_methods => [
        sub { Storable::freeze( +shift ) },
        sub { Storable::thaw( +shift ) }
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

