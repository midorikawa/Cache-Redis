use Test::More tests => 1;
use Cache::Redis;
use Test::RedisServer;

my $redis_server;
eval {
    $redis_server = Test::RedisServer->new(
        conf => {
            port      => 6379,
            databases => 16,
            save      => '900 1',
        }
    );
} or plan skip_all => 'redis-server is required to this test';

local $ENV{REDIS_SERVER} = $redis_server->connect_info;


my $cr = Cache::Redis->new();
my $key = "KEY1";
my $val = "VAL1";

$cr->set( $key, $val );

my $ret= $cr->get( $key );

is $ret,$val; 

