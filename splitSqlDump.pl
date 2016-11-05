#!/usr/bin/perl
# split MySQL dump into each tables.

use strict;
use warnings;
use utf8;
use Encode;

my $charsetConsole = 'CP932';
my $charsetFile    = 'UTF-8';

binmode( STDIN,  ":encoding($charsetConsole)" );
binmode( STDOUT, ":encoding($charsetConsole)" );
binmode( STDERR, ":encoding($charsetConsole)" );

@ARGV = map { decode( $charsetConsole, $_ ); } @ARGV;

my $infile         = $ARGV[0] or die("usage: splitSqlDump.pl <dump.sql>\n");
my $dirSqls        = './sqls/';
my $structuresfile = $dirSqls . '_structures.sql';

mkdir($dirSqls);
unlink <"${dirSqls}*">;

my $regSkip = qr{^\s*(
    LOCK\sTABLES\s`[^`]+`\sWRITE|
    /\*!40000\sALTER\sTABLE\s`[^`]+`\sDISABLE\sKEYS\s\*/|
    /\*!40000\sALTER\sTABLE\s`[^`]+`\sENABLE\sKEYS\s\*/|
    UNLOCK\sTABLES
);}x;
my $regInsert = qr{^\s*INSERT\sINTO\s`(?<table>[^`]+)`\sVALUES\s\([\s\S]+\);};
my $regBreak  = qr{(VALUES\s|\),)(\()};

open( my $fhIn, "<:raw", encode( $charsetConsole, $infile ) )
    or die("$infile: $!");
open( my $fhStructures, ">:raw", encode( $charsetConsole, $structuresfile ) )
    or die("$structuresfile: $!");
my $prevTable = '';
my $fhTable   = undef;
while ( defined( my $line = <$fhIn> ) ) {
    if ( $line =~ $regSkip ) {
        next;
    } elsif ( $line !~ $regInsert ) {
        print $fhStructures $line;
    } else {
        renewTable($1);
        $line =~ s/$regBreak/$1\n\t$2/g;
        print $fhTable $line;
    }
}
close($fhIn);
close($fhStructures);
renewTable('');

sub renewTable {
    my $newTable = shift;
    if ( $prevTable eq $newTable ) {
        return;
    }
    if ($fhTable) {
        print $fhTable "/*!40000 ALTER TABLE `${prevTable}` ENABLE KEYS */;\n";
        print $fhTable "UNLOCK TABLES;\n";
        close($fhTable);
    }
    if ( !$newTable ) {
        return;
    }
    my $tableFile = $dirSqls . $newTable . '.sql';
    open( $fhTable, ">:raw", encode( $charsetConsole, $tableFile ) )
        or die("$tableFile: $!");
    print $fhTable "LOCK TABLES `${newTable}` WRITE;\n";
    print $fhTable "/*!40000 ALTER TABLE `${newTable}` DISABLE KEYS */;\n";
    $prevTable = $newTable;
}

# EOF
