#!/usr/bin/perl
use strict;
use warnings;
use Business::ISBN;
use MARC::Record;
use C4::Context;
use C4::Biblio qw( ModBiblio );
use feature qw( say );

my $log_matches = 1;
my $now         = localtime;
logmessage("Run started:$now");

my $dbh = C4::Context->dbh;
my $sql = <<'ENDSQL';
select import_record_id from import_biblios
where isbn like ? or isbn like ?
order by import_record_id
ENDSQL
my $search2 = $dbh->prepare($sql);
$sql = <<'ENDSQL2';
select import_record_id from import_biblios
where isbn like ?
order by import_record_id
ENDSQL2
my $search1 = $dbh->prepare($sql);
$sql = <<'ENDSQL3';
update edifact_skeleton set status = 'upgraded' where biblionumber = ?
ENDSQL3
my $mark_matched = $dbh->prepare($sql);

my $readmarc =
  $dbh->prepare('select marc from import_records where import_record_id = ?');

my $bib_ref       = biblios_to_process();
my $bibs_searched = 0;
my $bibs_updated  = 0;

foreach my $bib ( @{$bib_ref} ) {
    logmessage("Bib:$bib->{biblionumber} Isbn:$bib->{isbn}");
    ++$bibs_searched;
    my $import_match = search_import( $bib->{isbn} );

    if ( $import_match && @{$import_match} ) {
        my $match_count = @{$import_match};
        logmessage("$match_count matches");
        update_biblio( $bib->{biblionumber}, $import_match );
    }
    else {
        logmessage("no match");
    }
}

logmessage("Bibs searched:$bibs_searched Bibs updated: $bibs_updated");

sub biblios_to_process {

    my $sql = <<'ENDSQL';
 select biblio.biblionumber, biblio.frameworkcode, biblioitems.isbn
    from biblio,  biblioitems
    where biblio.frameworkcode = 'ACQ'
    and biblioitems.biblionumber = biblio.biblionumber
ENDSQL
    my $dbh = C4::Context->dbh;

    my $biblio_arr = $dbh->selectall_arrayref( $sql, { Slice => {} } );

    return $biblio_arr;
}

sub search_import {
    my $search_key = shift;
    my $keylen     = length $search_key;
    my @keys;
    if ( $keylen == 10 ) {
        my $isbn10 = Business::ISBN->new($search_key);
        if ( $isbn10->is_valid() ) {
            my $k = $isbn10->as_string( [] );
            push @keys, "%$k%";
            my $isbn13 = $isbn10->as_isbn13();
            $k = $isbn13->as_string( [] );
            push @keys, "%$k%";
        }
    }
    elsif ( $keylen == 13 ) {
        my $isbn13 = Business::ISBN->new($search_key);
        if ( $isbn13->is_valid() ) {
            my $k = $isbn13->as_string( [] );
            my $valid10 = 0;
            if ( $k =~ m/^978/ ) {
                $valid10 = 1;
            }
            push @keys, "%$k%";
            if ($valid10) {
                my $isbn10 = $isbn13->as_isbn10();
                $k = $isbn10->as_string( [] );
                push @keys, "%$k%";
            }
        }
    }
    if ( !@keys ) {
        return;
    }
    my $rec_arr = [];
    if ( @keys == 2 ) {
        $rec_arr = $dbh->selectcol_arrayref( $search2, {}, @keys );
    }
    else {
        $rec_arr = $dbh->selectcol_arrayref( $search1, {}, @keys );
    }
    return $rec_arr;
}

sub update_biblio {
    my ( $biblionumber, $import_arr ) = @_;
    my $recid         = pop @{$import_arr};
    my $marcblob      = ( $dbh->selectrow_array( $readmarc, {}, $recid ) )[0];
    my $m             = MARC::Record->new_from_usmarc($marcblob);
    my $leader        = $m->leader();
    my $frameworkcode = get_framework( substr( $leader, 6, 2 ) );
    logmessage("Biblio:$biblionumber updated from importrec:$recid");

    ModBiblio( $m, $biblionumber, $frameworkcode );
    $mark_matched->execute($biblionumber);
    ++$bibs_updated;

    return;
}

sub get_framework {
    my $str = shift;

    # ACQ           | Acquisitions   |
    #| AR            | Models         |
    #| BKS           | Books          |
    #| CF            | Software       |
    #| FA            | Fast Add       |
    #| IR            | Binders        |
    #| KT            | Kits           |
    #| MAP           | Maps           |
    #| PLY           | Plays          |
    #| PRM           | Printed Music  |
    #| SER           | Serials        |
    #| SR            | Recorded music |
    #| SW            | Spoken Word    |
    #| VR            | DVDs           |
    if ( $str eq 'as' ) {
        return 'SER';
    }
    if ( $str =~ m/^m/ ) {
        return 'CF';
    }
    elsif ( $str =~ m/^o/ ) {
        return 'KT';
    }
    elsif ( $str =~ m/^e/ ) {
        return 'MAP';
    }
    elsif ( $str =~ m/^d/ ) {
        return 'PRM';
    }
    elsif ( $str =~ m/^j/ ) {
        return 'SR';
    }
    elsif ( $str =~ m/^i/ ) {
        return 'SW';
    }
    elsif ( $str =~ m/^g/ ) {
        return 'VR';
    }

    return 'BKS';
}

sub logmessage {
    my $msg = shift;
    if ($log_matches) {
        say $msg;
    }
    return;
}
