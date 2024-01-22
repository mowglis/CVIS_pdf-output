#!/usr/bin/perl
# vytvoreni dokladu o zaplaceni
use lib "/home/rusek/lib/";
use DBI;
use locale;
use CommonPgC;
use Mkrec;
use Data::Dumper;
use Getopt::Std;

$basedir = "/home/rusek/dokumenty/pdf-output/";
#$tempdir = "/home/rusek/dokumenty/pdf-output/temp/";
$tempdir = "/home/rusek/dokumenty/pdf-output/tmp/";
$prefix = "doklad_";

  sub slovy {
    my($c)=@_;    
    $ar = [
  ["","jedna","dva","t�i","�ty�i","p�t","�est","sedm","osm","dev�t","deset","jedn�ct","dvan�ct","t�in�ct","�trn�ct","patn�ct","�estn�ct","sedmn�ct","osmn�ct","devaten�ct"],
  ["","deset","dvacet","t�icet","�ty�icet","pades�t","�edes�t","sedmdes�t","osmdes�t","devades�t",],
  ["","jednosto","dv�st�","t�ista","�ty�ista","p�tset","�estset","sedmset","osmset","dev�tset",],
  ["","jedentis�c","dvatis�ce","t�itis�ce","�ty�itis�ce","p�ttis�c","�esttis�c","sedmtis�c","osmtis�c","dev�ttis�c", "desettis�c","jeden�cttis�c","dvan�ctis�c","t�in�scttis�c","�trn�cttis�c","patn�scttis�c","�estn�cttis�c","sedmn�cttis�c","osmn�cttis�c","devaten�cttis�c"],
  ["","desettis�c","dvacettis�c","t�icettis�c","�ty�icettis�c","pades�ttis�c","�edes�ttis�c","sedmdes�ttis�c","osmdes�ttis�c","devades�ttis�c",],
    ];
    $platba = ['\ v hotovosti.', '\ bankovn�m p�evodem.', '\ fakturou.'];
    $c =~ s/ K�//g;
    $c =~ s/ //g;
    $c =~ s/\.//g;
    $cislo = int($c);
    $i=0;
    $slovo = "";
    while($cislo != 0){
	$add = 1;
	$div = 10;
	$bit = $cislo % 10;
	if ($i == 0 || $i == 3) {
		$bit2 = $cislo % 100;
		if ($bit2 < 20) { 
			$add = 2; 
			$div = 100;
			$bit = $bit2;
		}	
	}
#	print "pripojuji --> $bit -->".$ar->[$i][$bit]."\n";
	$slovo = $ar->[$i][$bit].$slovo;
	$i += $add;
	$cislo = int($cislo/$div);				
    }
    return ($slovo);
  }
#
# vypis jedne vety - popis jedne akce ve sborniku
#
   sub pisDoklad {
      my ($id_akce,$sk_rok,$nazev,$poplatek,$akreditace,$termin,$placeni,$id_termin)=@_;

      if($akreditace =~ /nezad�no/) {$akreditace = ""};
   	$nazev = OpravChyby($nazev);
      # vars
#      print Dumper(@_);
      print VARS "\\def\\datumAkce{$termin}\n";
      print VARS "\\def\\datumPlaceni{$placeni}\n";
      print VARS "\\def\\poplatekSlovy{".slovy($poplatek)."}\n";
      print VARS "\\def\\poplatek{$poplatek}\n";
      print VARS "\\def\\nazevAkce{$nazev}\n";
      print VARS "\\def\\cisloAkce{".idAkce($id_akce,$sk_rok)."}\n";
      # oprava 29.9.08 , oprava 20.9.2012
#      if($akreditace =~ /^\d/) {
                $akreditace = "Program je akreditov�n M�MT �R - �.j. $akreditace";
#        } else { $akreditace = "";}
      print VARS "\\def\\akreditace{$akreditace}\n";
      # stranky
      print DATA "\\begin{document}\n";
      print DATA "{\\sf\\small";
      if($fill){
         # data z prihlasek
         $sql = "SELECT ucastnik.jmeno,ucastnik.prijmeni,skola.nazev,ucast_kurz.id_typ_platby FROM ucast_kurz,ucastnik,skola WHERE ucast_kurz.rc_ucastnik=ucastnik.rc_ucastnik AND ucast_kurz.id_skola=skola.id_skola AND ucast_kurz.id_kurz=? AND ucast_kurz.sk_rok=? ORDER BY ucastnik.prijmeni, ucastnik.jmeno";
	print "<br><br>kurz: $kurz, sk_rok: $sk_rok, id_termin: $id_termin<br>\n";
	print "\nsql: $sql<br><br>\n";
        $ucastnik_rec = $db->prepare("SELECT ucastnik.jmeno,ucastnik.prijmeni,skola.nazev,ucast_kurz.id_typ_platby FROM ucast_kurz,ucastnik,skola WHERE ucast_kurz.rc_ucastnik=ucastnik.rc_ucastnik AND ucast_kurz.id_skola=skola.id_skola AND ucast_kurz.id_kurz=? AND ucast_kurz.sk_rok=? AND ucast_kurz.id_termin=? AND ucast_kurz.id_typ_platby<>2 ORDER BY ucastnik.prijmeni, ucastnik.jmeno");
         $ucastnik_rec->execute($kurz, $sk_rok, $id_termin);
         if($ucastnik_rec->rows>0) {
           $ipocet=0;
           while (($jm,$pr,$skola,$zpusob_platby) = $ucastnik_rec->fetchrow_array) {
             $ipocet++;
#	     if($ipocet % 3 == 0) {print DATA "\\vfill";}
	     
             print DATA "
%%% $ipocet. potvrzeni
\\noindent
\\begin{minipage}[t]{.45\\linewidth}
\\obsah{$jm\\,$pr}{$skola}{$platba->[$zpusob_platby]}
\\end{minipage}";
             if($ipocet % 2 != 0) {
               print DATA "\\hfill";
             } else {		
	       if($ipocet % 4 == 0) {print DATA "\\newpage";}
                 else {print DATA "\\vfill";}
             }
           }
         }
      } else {
         # pouze prazdna jedna stranka
         print DATA "
%%% 1. potvrzeni
\\noindent
\\begin{minipage}[t]{.45\\linewidth}
\\obsah{\\dotfill}{\\dotfill}{\ bankovn�m p�evodem.}
\\end{minipage}
\\hfill
%%% 2. potvrzeni
\\noindent
\\begin{minipage}[t]{.45\\linewidth}
\\obsah{\\dotfill}{\\dotfill}{\ v hotovosti.}
\\end{minipage}
%%% 3. potvrzeni
\\vfill
\\begin{minipage}[t]{.45\\linewidth}
\\obsah{\\dotfill}{\\dotfill}{\ bankovn�m p�evodem.}
\\end{minipage}
\\hfill
%%% 4. potvrzeni
\\begin{minipage}[t]{.45\\linewidth}
\\obsah{\\dotfill}{\\dotfill}{\ v hotovosti.}
\\end{minipage}\n";
      }         
      print DATA "}\n\\end{document}\n";
}
#################################################
#  hlavni program
#################################################
   getopts("k:i:t:p:f");
   $fill   = $opt_f;   # vyplnit podle prihlasek?
   $kurz    = $opt_k;   # id kurzu
   $termin  = $opt_t;   # termin kurzu - textova polozka
   $placeni = $opt_p;   # termin placeni - textova polozka
   $id_termin = $opt_i;  # id_termin
   print "Hello, I'm generating LaTex source!\n";
#   print  Dumper($kurz);
#   print  Dumper($termin);
#   print  Dumper($placeni);
#   print  Dumper($id_termin);
#   print  Dumper($fill);
      $db = DBI->connect("$db_host_port;$mysql_sock",$user,$passw) or die "Nelze otev��t datab�zi: ".DBI->errstr."\n";
   #
      $q_rec = $db->prepare("SELECT kurz.id_akce,kurz.sk_rok,kurz.nazev,kurz.poplatek,akreditace.akredit FROM kurz,akreditace WHERE kurz.id_akredit=akreditace.id_akredit AND kurz.id_kurz=?");
   $q_rec->execute($kurz);
   if($q_rec->rows>0) {
      #
      # vytvoreni datoveho souboru
      #
      @pol = $q_rec->fetchrow_array;
#      print Dumper(@pol);
      $varsname = $tempdir.$prefix."vars_".$kurz.".tex";
      $tempname = $tempdir.$prefix."temp_".$kurz.".tex";
      $texfile  = $tempdir.$prefix.$kurz.".tex";
      $pdffile  =          $prefix.$kurz.".pdf";
      # vars - globalni data
      open(TEMP,">$tempname") or die "Nelze zalo�it soubor: '$tempname'\n";
      print TEMP "\\input{$varsname}\n";
      close(TEMP);
      system("cat ".$basedir."doklad_templ_1.tex $tempname ".$basedir."doklad_templ_2.tex > ".$texfile);
      open(DATA,">>$texfile") or die "Nelze zalo�it soubor: '$texfile'\n";
      open(VARS,">$varsname") or die "Nelze zalo�it soubor: '$varsname'\n";
#      @term = GetTermin($kurz,$termin);
      pisDoklad(@pol,$termin,$placeni,$id_termin);
      close(VARS);
      close(DATA);
      #
      # priprava souboru tex s pozvankou ##
      #
      system("vlna -r -s $texfile $varsname");
      system("cd $tempdir; pdfcslatex $texfile; cp $tempdir$pdffile $pdfdir");
   }      
   #$db->disconnect;
