use Test::More tests => 1;
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


my $cr = Cache::Redis->new(
	 serialize_methods => [
	sub {  encode_json(+shift)  },
	sub {  decode_json(+shift)  }
	],
)
;
my $key = "KEY1";
my $val = +{ "keyval" => "VAL1" };
$cr->remove($key);
$cr->set( $key, $val );

my $ret = $cr->get($key);

is_deeply $ret, $val;

