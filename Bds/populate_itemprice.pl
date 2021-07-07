#!/usr/bin/perl
use strict;
use warnings;

use C4::Context;
use C4::Biblio qw( GetMarcBiblio );
use MARC::Record;

my $dummy = 0;
my $dbh = C4::Context->dbh;

my $sql1 = 'select distinct biblionumber from items where replacementprice is null or replacementprice = 0';

my $sql2 = 'update items set replacementprice = ?, price = ? where biblionumber = ? and (replacementprice is null or replacementprice = 0) ';
my $update = $dbh->prepare($sql2);

my $bib_arrref = $dbh->selectcol_arrayref($sql1);


foreach my $biblionumber ( @{$bib_arrref}) {

    my $price = get_price($biblionumber);
    if ($price) {
        if ($dummy) {
            print "BIBLIO:$biblionumber PRICE:$price\n";
        }
        else {
            $update->execute($price, $price, $biblionumber);
        }
    }
    else {
        if ($dummy) {
            print "No price for $biblionumber\n";
        }
    }
}

sub get_price {
    my $biblionumber = shift;

    my $marcrecord = GetMarcBiblio($biblionumber);

    my @tags = $marcrecord->field( '365');
    foreach my $t (@tags) {
        my $a = $t->subfield('a');
        if ($a && $a=~m/(\d+\.\d\d)/) {
            return $1;
        }
        my $b = $t->subfield('b');
        if ($b && $b=~m/(\d+\.\d\d)/) {
            return $1;
        }
    }
    @tags = $marcrecord->field('020');
    foreach my $i (@tags) {
        my $c = $i->subfield('c');
        if ($c && $c=~m/(\d+\.\d\d)/) {
            return $1;
        }
    }
    return;
}
