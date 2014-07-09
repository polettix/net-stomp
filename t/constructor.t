#!perl
use strict;
use warnings;
use Test::More;
use Test::Deep;
use Net::Stomp;
use Net::Stomp::StupidLogger;

{no warnings 'redefine';
 sub Net::Stomp::_get_connection {}
}

sub mkstomp {
    return Net::Stomp->new({
        logger => Net::Stomp::StupidLogger->new({
            warn => 0, error => 0, fatal => 0,
        }),
        hosts => [ {hostname=>'localhost',port=>61613} ],
        @_,
    })
}

subtest 'reconnect on fork' => sub {
    my $s = mkstomp();
    is($s->reconnect_on_fork,1,'defaults to true');
    $s = mkstomp(reconnect_on_fork => 0);
    is($s->reconnect_on_fork,0,'can be turned off');
};

subtest 'hosts' => sub {
    my $s = mkstomp(hosts=>[{foo=>'bar'}]);
    cmp_deeply($s->hosts,[{foo=>'bar'}],'one host ok');

    $s = mkstomp(hosts=>[{foo=>'bar'},{one=>'two'}]);
    cmp_deeply($s->hosts,[{foo=>'bar'},{one=>'two'}],'two hosts ok');
};

subtest 'failover' => sub {
    my %cases = (
        'failover:tcp://one:1234' => [
            {hostname=>'one',port=>1234},
        ],
        'failover:(tcp://one:1234)?opts' => [
            {hostname=>'one',port=>1234},
        ],
        'failover:tcp://one:1234,tcp://two:3456' => [
            {hostname=>'one',port=>1234},
            {hostname=>'two',port=>3456},
        ],
        'failover:(tcp://one:1234,tcp://two:3456)?opts' => [
            {hostname=>'one',port=>1234},
            {hostname=>'two',port=>3456},
        ],
    );

    for my $case (sort keys %cases) {
        my $s = mkstomp(
            failover=>$case,
        );
        cmp_deeply($s->hosts,$cases{$case},"$case parsed ok");
    }
};

done_testing;
