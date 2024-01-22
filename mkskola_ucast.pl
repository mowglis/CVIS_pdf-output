#!/usr/bin/perl
use lib "/home/rusek/lib/";
use DBI;
use locale;
use CommonPgC;
use Mkrec;
use Getopt::Std;
use Data::Dumper;

$basedir = "/home/rusek/dokumenty/pdf-output/";
$tempdir = "/home/rusek/dokumenty/pdf-output/temp/";
#$pdfdir = "/home/rusek/html/pgc/pdf/";
#$pdfdir = "/var/www/cvkhk/public_html/cvis/pdf/";

#$dataname = $dir."data_pozv.tex";

   sub writeHeaderSchool{
      my($skola,$ico)=@_;
      $skrok1 = $skrok+1;
      print TEXFILE "
\\noindent  
\\begin{tabbing}
\\bfseries Období: \\= \\bfseries $skrok/$skrok1, $polo. pololetí \\kill
\\bfseries ©kola: \\> $skola (IÈO: $ico)\\\\
\\bfseries Období: \\> $skrok/$skrok1, $polo. pololetí
\\end{tabbing}
{\\small
\\centering
\\begin{supertabular}{|p{4cm}|c|p{10cm}|r|}
";
   }
   sub writeFooterSchool{
      print TEXFILE "\\end{supertabular}      
}
\\newpage\n";
   }
#
# vypis jednoho radku tabulky
#
   sub PisRadek {
	   my ($id_akce,$sk_rok,$nazev,$titul,$prijmeni,$jmeno,$den_od,$den_do,$skola,$datum_prihl,$rc_ucastnik,$ico) = @_;
      
      if($oldskola ne $ico) {
         if($oldskola ne "") {writeFooterSchool();}
         writeHeaderSchool($skola,$ico);
         $oldskola = $ico;
      }
   	$ucastnik = "$titul $jmeno $prijmeni";
   	$ucastnik =~ s/^\s*//;
   	$nazev = OpravChyby($nazev);
      $termin = ParseDatum($den_od,$den_do);
		$id_akce = idAkce($id_akce,$sk_rok);
      print TEXFILE "$ucastnik & $id_akce & $nazev & $termin \\\\ \\hline\n";

#      print "***************** Kontrolni tisky ***********************\n";
#      print Dumper(@term);
#      print Dumper(@terminy);
#      print Dumper (@uzav);
#      print Dumper (@ttab);
#      print "############## end #################\n";
}
#################################################
#  hlavni program
#################################################
   getopt('ypisf');
   $skrok = $opt_y;
   $polo = $opt_p;
   $s_ico = $opt_i;
   $s_skola = $opt_s;
   $fname = $opt_f;
   
   print "Hello, I'm generating LaTex source!\n";
   $db = DBI->connect("$db_host_port;$mysql_sock",$user,$passw) or die "Nelze otevøít databázi: ".DBI->errstr."\n";
   $sql = "SELECT kurz.id_akce,kurz.sk_rok,kurz.nazev,ucastnik.titul,ucastnik.prijmeni,ucastnik.jmeno,kurz_termin.den_od,kurz_termin.den_do,skola.nazev as skola_nazev,datum_prihl,ucast_kurz.rc_ucastnik,skola.ico FROM ucast_kurz,kurz,ucastnik,kurz_termin,skola WHERE ucast_kurz.id_kurz=kurz.id_kurz AND kurz_termin.id_kurz=ucast_kurz.id_kurz AND ucast_kurz.id_termin=kurz_termin.id_termin AND ucastnik.rc_ucastnik=ucast_kurz.rc_ucastnik AND skola.id_skola=ucast_kurz.id_skola AND ucast_kurz.sk_rok='$skrok' AND kurz.pololeti=$polo";
   
   $poc=0;
	if($s_ico ne "") {
		$sql .=" AND skola.ico = '$s_ico'";
		$poc++;
	};
	if($s_skola ne "") {
		$sql .=" AND (skola.nazev LIKE '%$s_skola%')";
		$poc++;
	};

   $sql .= " ORDER BY skola.ico,ucastnik.prijmeni, ucast_kurz.rc_ucastnik, kurz.id_akce";
#   print "SQL: $sql\n";
   if($poc > 0) {
      $q_rec = $db->prepare($sql); 
      $q_rec->execute();
      if($q_rec->rows > 0){
         #
         # vytvoreni TeXovskeho zdroje
         #
          srand;
#         $fname="s".rand(10000);
         $texfile  = $tempdir.$fname.".tex";
         $pdffile  = $fname.".pdf";
         system("cp ".$basedir."ucast_skola_header.tex $texfile");
         open(TEXFILE,">>$texfile") or die "Nelze zalo¾it soubor: '$texfile'\n";
         $oldskola="";
         $oldprijmeni="";
         while(@pol = $q_rec->fetchrow_array) {
		      PisRadek(@pol);
         }      
         writeFooterSchool();
         print TEXFILE "\\end{document}";
         close(TEXFILE);
         # projedeme programem 'vlna'
         system("vlna -r -s $texfile");
         # generovani PDFka
         system("cd $tempdir; pdfcslatex $texfile; cp $tempdir$pdffile $pdfdir");
      }      
      $db->disconnect;
   }      
#### konec programu ###   
