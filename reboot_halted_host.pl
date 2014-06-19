#!/usr/bin/perl
use File::Glob;
use IPC::System::Simple qw(capture);
use strict;
use warnings;
use Try::Tiny;

my $state;
my $type;
my $atempt;
my $ilo;
my $lastup;
my $lastdown;
my $line;
my $result;
my $EXITVAL;
my $host_name;

my $down_time_to_reboot = 30; #minutes
my $home_dir = "/home/nagios/host_status/";
my $log_file = "/home/nagios/rebooted_hosts.log";

open (LOGFILE, '>>'.$log_file);
opendir (DIR, $home_dir) or die $!;
while ($host_name = readdir(DIR)) {
    if ($host_name =~ /.status(?!.)/) {
        open FILE, $home_dir.$host_name or die "error opening $home_dir$host_name\n";
        while ($line=<FILE>){
            if ($line=~/^(.*?)\;  (.*?)\;  (.*?)\;  (.*?);  (.*?);  (.*?)$/){
                $state=$1;
                $type=$2;
                $atempt=$3;
                $ilo=$4;
                $lastup=$5;
                $lastdown=$6;
            }
        }
        close(FILE);
        if ($state eq "DOWN") {
            print LOGFILE "Another applicant to reboot. It's a ".$host_name."\n";
            print LOGFILE "STATE:$state; TYPE:$type; ATEMPT:$atempt; iLO:$ilo; UP:$lastup; DOWN:$lastdown; \n";
            print LOGFILE "Host is down. Let's test ssh...\n";
            try {
                $result = capture("ssh -l root -p 2222 $host_name whoami");
            }
            catch {
                warn "Error: $_";
            };
            sleep (5);
            if ($result =~ /root/) {
                print LOGFILE "Strange... Host is down but ssh is availible... won't reboot host!\n";
            }
            else {
                print LOGFILE "So... Host is DOWN + no ssh. Let's look how mutch time it in down state.\n";
                if ( time-$down_time_to_reboot*60 > $lastdown) {
                    print LOGFILE "Now is ".time." and ".$host_name." has DOWN state at ".$lastdown."\n";
                    print LOGFILE "It is about ".((time-$lastdown)/60)."min.\n";
                    print LOGFILE "Rebooting host $host_name using iLO interface at $ilo\n";
                    try {$result = capture("ssh -f -T -l test $ilo POWER off hard");}
                    catch {
                        warn "Error: $_";
                    };
                    print LOGFILE "Power off :".$result."\n";
                    sleep (15);
                    try {$result = capture("ssh -f -T -l test $ilo POWER on");}
                    catch {
                        warn "Error: $_";
                    };
                    print LOGFILE "Power on :".$result."\n";
                }
            }
        }
    } # End If $file =~ /.test/
    print LOGFILE "  \n";
}
closedir(DIR);
close (LOGFILE);
