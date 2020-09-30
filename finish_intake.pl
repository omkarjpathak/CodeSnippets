#!/usr/bin/env perl 

use File::Temp qw/ tempfile tempdir /;
use File::Copy;

use DbUtil; 
use RaptrDB; 

use Intake;
use BamIntake;

my $raptr_dbh = &DbUtil::connectUsingTdtConfig("dbconn", "raptr", {RaiseError => 1, AutoCommit => 0});
die "Could not connect to RAPTR using config" unless ($raptr_dbh);
my $raptr_db = RaptrDB->new(dbh => $raptr_dbh);

my $dir = $ARGV[0];
$dir = `readlink -f $dir`; 
chomp $dir;
my $intake;
if($dir =~ m#/intake-bam/#) {
	$intake = BamIntake->resumeExisting($raptr_db, $dir);
}
else {
	$intake = Intake->resumeExisting($raptr_db, $dir);
}
$intake->complete(); 