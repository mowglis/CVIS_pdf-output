#!/usr/bin/perl
#
# prezencka v PDF
#
use lib "/home/rusek/lib/";
use DBI;
use locale;
use CommonPgC;
use Mkrec;
use Getopt::Std;
use Data::Dumper;

$basedir = "/home/rusek/dokumenty/pdf-output/";
$tempdir = "/home/rusek/dokumenty/pdf-output/tmp/";
#$pdfdir = "/var/www/cvkhk/public_html/cvis/pdf/";
$fname = "prez_";
$max_per_page = 13;
$logo_lines = 5;
$h_line_table = '[4mm]';

  sub writeHead
  {
    my($id_akce,$sk_rok,$nazev,$den_od,$den_do,$misto)=@_;
    $termin = ParseDatum($den_od,$den_do);
    $nazev = OpravChyby($nazev);
    $id_akce = idAkce($id_akce,$sk_rok);
    print TEXFILE "
\\noindent  
\\hlavicka{}
%\\vfill
\\begin{center}
\\huge\\bf Prezen�n� listina\\\\
\\end{center}
\\vfill
\\begin{tabular}{lp{13.5cm}}
\\bfseries K�d - n�zev programu:\\hspace{1cm} & $id_akce\\ \\ --\\ \\  $nazev\\\\
\\bfseries Term�n, m�sto: & $termin, $misto
\\end{tabular}
\\vfill
\\begin{flushleft}
\\footnotesize Beru na v�dom�, �e p��padn� fotodokumentace z tohoto vzd�l�vac�ho programu m��e b�t pou�ita organiz�torem k propaga�n�m ��el�m. Sv�j p��padn� nesouhlas ozn�m�m garantovi programu. Sv�m podpisem stvrzuji, �e jsem obezn�men s t�m, �e se ze vzd�l�vac�ho programu bude po�izovat audiovizu�ln� z�znam pro vlastn� pot�eby organizace.
\\end{flushleft}
{\\small
\\begin{supertabular}{|r|p{4cm}|p{8.5cm}|r|p{3cm}|}
";
  }
#
# pata prezencky
#
  sub writeFoot
  {
    my($id_kurz)=@_;
    print TEXFILE "
\\end{supertabular}
}";
    # souhrnne pocty
    print TEXFILE "
\\vfill
{\\centering
Na listu ��astn�k�: \\hrulefill\\ plat�c�ch hotov�: \\hrulefill\\ plat�c�ch BP: \\hrulefill\\ plat�c�ch FA: \\hrulefill\\ neplat�c�ch: \\hrulefill\\ celkem hotov�: \\hrulefill \\\\[5mm]
podpis garanta: \\hrulefill\\ podpis pokladn�ka: \\hrulefill }
\\vfill
";
    # logoline
    print TEXFILE logoline($id_kurz,1);
   }
#
# vypis jednoho radku tabulky
#
  sub PisRadek 
  {
    my ($_radek,$titul,$prijmeni,$jmeno,$skola,$placeno,$zkratka) = @_;
    $poradi += 1; 
    $ucastnik = "$prijmeni $jmeno $titul";
    $ucastnik =~ s/^\s*//;
    $termin = ParseDatum($den_od,$den_do);
    if ($placeno == 0) {$placeno = '';}
    if ($zkratka ne '') { $placeno = "($zkratka) $placeno"; }
    print TEXFILE "$poradi & $ucastnik & $skola & $placeno &  \\tabularnewline$_radek \\hline\n";

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

   getopts('k:y:p:t:f');
   $skrok = $opt_y;
 #  $polo = $opt_p;
   $kurz = $opt_k;
   $termin = $opt_t;
   $fill = $opt_f;
   $poradi = 0;
   print "Hello, I'm generating LaTex source!\n";
   $db = DBI->connect("$db_host_port;$mysql_sock",$user,$passw) or die "Nelze otev��t datab�zi: ".DBI->errstr."\n";
   $sql_akce = "SELECT kurz.id_akce,kurz.sk_rok,kurz.nazev,kurz_termin.den_od,kurz_termin.den_do,kurz_termin.misto FROM kurz,kurz_termin WHERE kurz.id_kurz=kurz_termin.id_kurz AND kurz.id_kurz=$kurz AND kurz_termin.id_termin=$termin";

   $sql_ucastnik = "SELECT ucastnik.titul,ucastnik.prijmeni,ucastnik.jmeno,skola.nazev as skola_nazev,placeno,typ_platby.zkratka as zkratka FROM ucast_kurz,ucastnik,skola,typ_platby WHERE ucastnik.rc_ucastnik=ucast_kurz.rc_ucastnik AND skola.id_skola=ucast_kurz.id_skola AND ucast_kurz.id_typ_platby=typ_platby.id_typ_platby AND ucast_kurz.id_kurz=$kurz AND ucast_kurz.id_termin=$termin AND sk_rok=$skrok ORDER BY ucastnik.prijmeni, ucastnik.jmeno";

#  print "SQL-AKCE: $sql_akce\n";
#  print "SQL-UCAST: $sql_ucastnik\n";
  $q_rec_akce  = $db->prepare($sql_akce); 
  $q_rec_ucast = $db->prepare($sql_ucastnik); 
  $q_rec_akce->execute();
  $q_rec_ucast->execute();
  print "po�et ��dk� - akce : ".$q_rec_akce->rows."\n";
  print "po�et ��dk� - ucast: ".$q_rec_ucast->rows."\n";
  if($q_rec_akce->rows > 0){
    #
    # vytvoreni TeXovskeho zdroje
    #
    $fname .= $kurz;
    $texfile  = $tempdir.$fname.".tex";
    $pdffile  = $fname.".pdf";
    system("cp ".$basedir."prezencka_hdr.tex $texfile");
    open(TEXFILE,">>$texfile") or die "Nelze zalo�it soubor: '$texfile'\n";
    @pol_head = $q_rec_akce->fetchrow_array;
    writeHead(@pol_head);
    if (logoline($pol_head[0])) { $max_per_page -= $logo_lines; }
    if ($fill) {
      # prezencka vyplnena
 #     $_radek='';
      $_radek=$h_line_table;
      while(@pol = $q_rec_ucast->fetchrow_array) { 
         $pocet +=1;
         if ($pocet > $max_per_page) {
           writeFoot($kurz);
           $pocet=1;
           print TEXFILE "\\newpage";
           writeHead(@pol_head);
         }          
         PisRadek($_radek,@pol); 
       } 
       # dopsani prazdnych radku
       if ($pocet < $max_per_page) {
         $zbytek = $max_per_page-$pocet;
         $_radek=$h_line_table;
         for ($i=1;$i<= $zbytek;$i++) { PisRadek($_radek); }
       }     
    } else {
      # prazdna prezencka      
      $_radek=$h_line_table;
      for ($i=1;$i<=$max_per_page;$i++) { PisRadek($_radek); }
    }
    writeFoot($kurz);
    print TEXFILE "\\end{document}";
    close(TEXFILE);
    # projedeme programem 'vlna'
    system("vlna -r -s $texfile");
    # generovani PDFka
    system("(cd $tempdir; pdfcslatex $texfile; cp $tempdir$pdffile $pdfdir)");
  }      
#  $db->disconnect;
#### konec programu ###   
