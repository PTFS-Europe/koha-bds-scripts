#!/usr/bin/env perl
#
# Copyright 2012 PTFS Europe Ltd
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# Koha; if not, write to the Free Software Foundation, Inc., 59 Temple Place,
# Suite 330, Boston, MA  02111-1307 USA

use strict;
use warnings;
use Carp;
use Net::FTP;

my $local_dir = 'Source';
opendir( my $dh, $local_dir ) || croak "can't opendir $local_dir: $!";
my @loc_files = grep { /^ches.*\.mrc$/ && -f "$local_dir/$_" && -M "$local_dir/$_" < 300 } readdir($dh);
closedir $dh;
my %loc_fil = map { $_ => 1 } @loc_files;

my $remote   = 'ftp.bibdsl.co.uk';
my $username = q{cheshire};
my $password = q{r9GawLHW};

my $ftp = Net::FTP->new( $remote, Debug => 0 )
  or croak "Cannot connect to BDS: $@";

$ftp->login( $username, $password )
  or croak 'Cannot login to BDS ', $ftp->message;
$ftp->binary();
$ftp->cwd("receive/cheshire")
  or die "Cannot change working directory ", $ftp->message;
my @rem_files = $ftp->ls('ches*.mrc');
foreach my $rmfl (@rem_files) {

    #        print "$rmfl\n";
    my $modt = $ftp->mdtm($rmfl);

    #        print "mdtm: $modt\n";
    if ( !exists( $loc_fil{$rmfl} ) ) {

        #            print "gonna get: $rmfl\n";
        $ftp->get( $rmfl, "Source/$rmfl" );
        `touch --date=\@$modt Source/$rmfl`;
    }
}
$ftp->quit;
