#!/usr/bin/perl
use strict;
use warnings;
use feature qw( say );
use Digest::MD5;
use Carp;
use Config::General;

my $conf = Config::General->new(
            -ConfigFile => 'options.cfg',
            -InterPolateVars => 1
        );

my %config = $conf->getall;


my @filenames = get_filenames();

foreach my $f (@filenames) {
    if (not_in_archive($f)) {
        say "$f is a NEW file";
    }
    else {
        say $f;
    }

}

sub get_filenames {
    my $local_dir = 'Source';
  opendir( my $dh, $local_dir ) || croak "can't opendir $local_dir: $!";
    my @loc_files =
      grep { /^$config{'custcodeprefixsql'}.*\.mrc$/ && -f "$local_dir/$_" && -M "$local_dir/$_" < 300 }
      readdir($dh);
    closedir $dh;
    return @loc_files;
}



sub not_in_archive {
    my $filename = shift;
    my $archive_filename = "Archive/$filename";
    if (-f $archive_filename) {
       open my $fh, '<',$archive_filename or croak "Cannot open $archive_filename : $!";
       binmode $fh;
       my $archive_digest = Digest::MD5->new->addfile($fh)->hexdigest;
       close $fh;
       my $source_filename = "Source/$filename";
       open my $fh2, '<',$source_filename or croak "Cannot open $source_filename : $!";
       binmode $fh2;
       my $source_digest = Digest::MD5->new->addfile($fh2)->hexdigest;
       close $fh2;
       # if contents do not match it is a new file
       return $source_digest ne $archive_digest ? 1 : 0;
    }
    else {
        # not present in archive
        # ok to process
        return 1;
    }
    return;
}

