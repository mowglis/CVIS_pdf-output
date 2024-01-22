#!/usr/bin/perl
#
# osvedceni v PDF
#
use lib "/home/rusek/lib/";
use DBI;
use locale;
use CommonPgC;
use Mkrec;
use Getopt::Std;
use Data::Dumper;

$basedir = "/home/rusek/dokumenty/pdf-output/";
#$tempdir = "/home/rusek/dokumenty/pdf-output/temp/";
$tempdir = "/home/rusek/dokumenty/pdf-output/tmp/";
$template = "osvedceni_templ.tex";
$prefix = "osv_";

  sub skol_rok
  {
    my($sk_rok)=@_;
	 $s = $sk_rok+1;
	 return $sk_rok."/".$s;
  }

  sub writeVARS
  {
#    print Dumper(@_);
    my($id_kurz,$id_akce,$sk_rok,$pololeti,$nazev,$rozsah,$den_od,$den_do,$misto,$akreditace,$druh,$osvedceni,$potvrzeni)=@_;
    $termin = ParseDatum($den_od,$den_do,2);
    $nazev = OpravChyby($nazev);
#    $datum = "V Hradci Králové dne x.x.xxx";
    print VARS "\\def\\cisloAkce{".idAkce($id_akce,$sk_rok)."}\n";
    print VARS "\\def\\skRok{".skol_rok($sk_rok)."}\n";
    print VARS "\\def\\pololeti{$pololeti}\n";
    print VARS "\\def\\mistoAkce{$misto}\n";
#    print VARS "\\def\\datumAkce{$termin}\n";
#    print VARS "\\def\\nazevAkce{$nazev}\n";
#    print VARS "\\def\\rozsahAkce{$rozsah}\n";
#    print VARS "\\def\\datumVystaveni{$datum}\n";
#    if($akreditace =~ /nezadáno/) {$akreditace = "*"};
    if($akreditace =~ /^\d/ || $akreditace =~ /^MSMT/  ) {
      $akreditace = "Vzdìlávací program byl akreditován M©MT v rámci DVPP pod è.j. $akreditace.";
    } else { $akreditace = "*";}
    if ($druh eq "") {
      $druh = "*";
    } else {
      $druh .= " dle zákona è.~563/2004~Sb. a \\S~1~vyhlá¹ky~è.~317/2005~Sb."; 
    }
    if ($doklad_typ == 2) { $osvedceni = $potvrzeni; }
    print VARS "\\def\\akreditace{$akreditace}\n";
    print VARS "\\def\\druh{$druh}\n";
    print VARS "\\def\\osvedceniText{$osvedceni}\n";
    print VARS "\\def\\logoline{".logoline($id_kurz,0)."}\n";
  }
#
# vypis jednoho ucastnika
#
  sub writeUcastnik
  {
    my ($titul,$prijmeni,$jmeno,$rc,$cislo_osvedceni,$misto_nar,$id_akce,$sk_rok,$druh_studia) = @_;
    $ucastnik = "$titul $jmeno $prijmeni";
    $ucastnik =~ s/^\s*//;
	 $rc = rc2datum($rc,2);
	 $cislo_osvedceni = idAkce($id_akce,$sk_rok)."/".$sk_rok."/".$cislo_osvedceni;
	 $cislo_osvedceni =~ s/\-//g;
	 $misto = "";
	 if ($druh_studia > 1) {$misto = ", $misto_nar";}
	 if (!$ucastnik) 
	 {
	   $ucastnik = "\\parbox[b][1cm]{10cm}{\\hrulefill}";
  	   $rc = "\\makebox[5cm]{\\hrulefill}";
     }
  print TEXFILE "\\osvedceni{$ucastnik}{$rc}{$cislo_osvedceni}{$misto}\n";
  }

###################
#  hlavni program
###################

   getopts('k:y:p:t:d:f');
   $skrok = $opt_y;
 #  $polo = $opt_p;
   $kurz = $opt_k;
   $termin = $opt_t;
   $fill = $opt_f;
   $doklad_typ = $opt_d;
   print "Hello, I'm generating LaTex source!\n";
   $db = DBI->connect("$db_host_port;$mysql_sock",$user,$passw) or die "Nelze otevøít databázi: ".DBI->errstr."\n";
   $sql_akce = "SELECT kurz.id_akce,kurz.sk_rok,kurz.pololeti,kurz.nazev,kurz.rozsah,kurz_termin.den_od,kurz_termin.den_do,kurz_termin.misto,akredit,druh,osvedceni,potvrzeni,id_druh_studia FROM kurz,kurz_termin,akreditace,druh_studia WHERE kurz.id_kurz=kurz_termin.id_kurz AND kurz.id_akredit=akreditace.id_akredit AND id_druh_studia=druh_studia.id AND kurz.id_kurz=$kurz AND kurz_termin.id_termin=$termin";

   $sql_ucastnik = "SELECT ucastnik.titul,ucastnik.prijmeni,ucastnik.jmeno,ucastnik.rc_ucastnik,cislo_prihlasky,ucastnik.misto_nar FROM ucast_kurz,ucastnik WHERE ucastnik.rc_ucastnik=ucast_kurz.rc_ucastnik AND ucast_kurz.id_kurz=$kurz AND ucast_kurz.id_termin=$termin AND ucast_kurz.sk_rok=$skrok ORDER BY ucastnik.prijmeni, ucastnik.jmeno";

  print "SQL-AKCE: $sql_akce\n";
  print "SQL-UCAST: $sql_ucastnik\n";
  $q_rec_akce  = $db->prepare($sql_akce); 
  $q_rec_ucast = $db->prepare($sql_ucastnik); 
  $q_rec_akce->execute();
  $q_rec_ucast->execute();
  print "poèet øádkù - akce : ".$q_rec_akce->rows."\n";
  print "poèet øádkù - ucast: ".$q_rec_ucast->rows."\n";
  if($q_rec_akce->rows > 0)
  {
    #
    # vytvoreni TeXovho zdroje
    #
    $texfile  = $tempdir.$prefix.$kurz.".tex";
    $varsname = $prefix."vars_".$kurz.".tex";
    $sed_cmd = "sed -e \"s/VARS/$varsname/g\" ".$basedir.$template." > $texfile";
    print "$sed_cmd\n";
    system($sed_cmd);
    $varsname = $tempdir.$varsname;
    $pdffile  =          $prefix.$kurz.".pdf";
#    system("cp ".$basedir.$template $texfile);
    open(TEXFILE,">>$texfile") or die "Nelze zalo¾it soubor: '$texfile'\n";
    open(VARS,">>$varsname") or die "Nelze zalo¾it soubor: '$varsname'\n";
    @pol_head = $q_rec_akce->fetchrow_array;
    writeVARS($kurz,@pol_head);
    close(VARS);
    if ($fill) {
      # vyplnene osvedceni
      while(@items = $q_rec_ucast->fetchrow_array) 
      {  
        writeUcastnik(@items,$pol_head[0],$pol_head[1],$pol_head[11]);
      }     
    } else {
      # prazdne osvedceni
      writeUcastnik();
    }
    print TEXFILE "\\end{document}";
    close(TEXFILE);
    system("vlna -r -s $texfile $varsname");
    # generovani PDFka
    system("(cd $tempdir; pdfcslatex $texfile; cp $tempdir$pdffile $pdfdir)");
  }      
#  $db->disconnect;
