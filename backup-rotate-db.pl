#!/usr/bin/perl

use strict;

#################################
# Config
#################################

my $dump_dir = "/tmp";

my $db_host = "localhost";
my $db_port = "";
my $db_user = "";
my $db_pass = "";
my $db_name = "";
my $dump_file="${dump_dir}/${db_name}.dump";

my $dumps_to_keep=3;
my $gzip=1;

my $DEBUG = 0;

my $suffix=".gz" if $gzip;

#################################
# Main script
#################################

my ($mv_return, $oldfile, $move_to_num, $newfile, $gzip_return, $dump_return);

$dump_return = system("mysqldump -h $db_host -P $db_port --user=$db_user --password=$db_pass $db_name > ${dump_file}.tmp");
if ($dump_return == 0) {

    for ($dumps_to_keep--; $dumps_to_keep >= 0; $dumps_to_keep--) {
        my $oldfile = "${dump_file}.${dumps_to_keep}${suffix}";
        if ( -e $oldfile ) {
            print "$oldfile exists\n" if $DEBUG;
            $move_to_num = $dumps_to_keep+1;
            $newfile = "${dump_file}.${move_to_num}${suffix}";
            $mv_return = system("mv $oldfile $newfile");
            print "Could not move $oldfile -> $newfile\n" && 
                exit 1 if ($mv_return != 0);
        }
    }


    if ( -e $dump_file ) {
        $mv_return = system("mv $dump_file ${dump_file}.1");
        print "Could not move $dump_file to ${dump_file}.1\n" &&
            exit 1 if ($mv_return != 0);
    }

    if ( -e "${dump_file}.tmp" ) {
        $mv_return = system("mv ${dump_file}.tmp $dump_file");
        print "Could not move ${dump_file}.tmp to ${dump_file}\n" &&
            exit 1 if ($mv_return != 0);
    }

    $gzip_return = system("gzip ${dump_file}.1") if $gzip == 1;
    print "I'm going to gzip ${dump_file}.1\n" if $DEBUG;
    print "Could not gzip ${dump_file}.1: $!\n" if $gzip_return != 0;
    

} else {
    print "Mysql dump failed: $!\n";
    exit 1;
}
exit 0;
