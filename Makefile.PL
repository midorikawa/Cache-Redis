use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Cache::Redis',
    'VERSION_FROM' => 'lib/Cache/Redis.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
	Test::RedisServer => 0.01,
	Redis => 0.01,
	Storable => 0.01,
	Data::MessagePack => 0.01,
	JSON => 0.01,
    },
);
