#!/usr/bin/perl
use lib "/home/rusek/lib/";
use DBI;
use locale;
use CommonPgC;
use Mkrec;
use Data::Dumper;

$basedir = "/home/rusek/dokumenty/pdf-output/";
#$tempdir = "/home/rusek/dokumenty/pdf-output/temp/";
$tempdir = "/home/rusek/dokumenty/pdf-output/tmp/";
#$dataname = $dir."data_pozv.tex";

   sub writeDocument {
      print TEXFILE "
\\begin{document}
\\sf
\\def\\done{\\body}
\\input{$dataname}
\\end{document}";
   }
#
# vypis jedne vety - popis jedne akce ve sborniku
#
   sub PisVetuPozv {
	   my ($id_kurz,$sk_rok,$pololeti,$id_akce,$id_akredit,$nazev,$popis,$poplatek,$id_garant,$lektor,$urceni,$spojeni,$pozn,$zruseno,$cyklus,$notiu,$notig,$last,$rozsah,$id_urceni,$id_garant2,$id_druh_studia,$tit,$prijm,$jmeno,$id_pracoviste,$pracoviste,$ulice,$mesto,$psc,$spojeni_prac,$ico,$email,$web,$fax,$telefon,$akreditace,$urceni_popis,@term)=@_;
#	print "id_akce -> $id_akce ($prijm $jmeno)\n";
      $adresa = "pracovi¹tì $pracoviste, $ulice, $mesto, $psc";
      $urceni_all = UrceniText($id_urceni,$urceni_popis,$urceni);
      if($akreditace =~ /nezadáno/) {$akreditace = ""};
   	$popis = OpravChyby($popis);
   	$pozn = OpravChyby($pozn);
   	$lektor = OpravChyby($lektor);
   	$nazev = OpravChyby($nazev);
   	$urceni = OpravChyby($urceni);
   	$spojeni = OpravChyby($spojeni);
   	$garant = "$tit $jmeno $prijm";
   	$garant =~ s/^\s*//;

   	print DATA "\\z{%\n";
     	print DATA "\\adresa{$adresa}\n";
		print DATA "\\tel{$telefon}\n";
      print DATA "\\fax{$fax}\n";
      print DATA "\\ico{$ico}\n";
      print DATA "\\mail{$email}\n";
      print DATA "\\web{$web}\n";

   	print DATA "\\akce{".idAkce($id_akce,$sk_rok)."}\n";
   	print DATA "\\nazev{$nazev}\n";
   	if($popis eq ""){$popis="*";}
   	print DATA "\\popis{$popis}\n";
   	print DATA "\\urceno{$urceni_all}\n";
      @terminy = &TerminFmt(@term);
      @uzav = &UzaverFmt(@term);
      @ttab = &TTabFmt(@term);
      print "***************** Kontrolni tisky ***********************\n";
      print Dumper(@term);
      print Dumper(@terminy);
      print Dumper (@uzav);
      print Dumper (@ttab);
      print "############## end #################\n";
      print DATA "\\termin{".join("\\\\ ",@terminy)."}\n";
      print DATA "\\termintab{".join(" ",@ttab)."}\n";
   	print DATA "\\lektor{$lektor}\n";
   	print DATA "\\garant{$garant}\n";
 #  	if($poplatek eq ""){$poplatek="*";}
  	if($poplatek =~ /^\D*$/){$poplatek="*";}
   	print DATA "\\poplatek{$poplatek}\n";
      $uzaverka = join(", ",@uzav);
      if($uzaverka eq "0000-00-00") {$uzaverka="*";}
#      print "uzaverka -> $uzaverka\n";
      print DATA "\\uzaverka{$uzaverka}\n";
	#
	# akreditace - zmena 30.7.08 ###
	#
	if($akreditace =~ /^\d/ || $akreditace =~ /^MSMT/) {
		$akreditace = "Program je akreditován M©MT ÈR - è.j. ".$akreditace;
	}
      print DATA "\\akreditace{$akreditace}\n";
      if($spojeni eq ""){$spojeni="*";}
      print DATA "\\spojeni{$spojeni}\n";
   	if($pozn eq ""){$pozn="*";}
   	print DATA "\\poznamka{$pozn}\n";
   	print DATA "\\vs{".vs($id_akce,$sk_rok)."}\n";
	print DATA "\\logoline{".logoline($id_kurz,0)."}\n";
   	print DATA "}\n";
}
#
# hlavni program
#
#&getops("g");
#$garant = $opt_g;
   $id_a = $ARGV[0];
   $id_t = $ARGV[1];
   print "Hello, I'm generating LaTex source!\n";
      $db = DBI->connect("$db_host_port;$mysql_sock",$user,$passw) or die "Nelze otevøít databázi: ".DBI->errstr."\n";
   #
      $q_rec = $db->prepare("SELECT kurz.*,zam.titul,zam.prijmeni,zam.jmeno,pracoviste.*,akreditace.akredit,urceni.popis FROM kurz,zam,pracoviste,akreditace,urceni WHERE kurz.id_garant=zam.rc_zam AND SUBSTRING(id_akce,1,1)=pracoviste.id_pracoviste AND kurz.id_akredit=akreditace.id_akredit AND kurz.id_urceni=urceni.id_urceni AND kurz.id_kurz=?");
   $q_rec->execute($id_a);
   if($q_rec->rows>0){
      #
      # vytvoreni datoveho souboru
      #
      @pol = $q_rec->fetchrow_array;
      $id_kurz = $pol[0];
      $cyklus = $pol[14];
      $dataname = $tempdir.$id_kurz."_data.tex";
      $texfile  = $tempdir.$id_kurz.".tex";
      $pdffile  = $id_kurz.".pdf";
      open(DATA,">$dataname") or die "Nelze zalo¾it soubor: '$dataname'\n";
      if ($cyklus) { $id_t = "0"; }    
      @term = &GetTermin($id_kurz, $id_t);
		  &PisVetuPozv(@pol,@term);
      close(DATA);
      #
      # priprava souboru tex s pozvankou ##
      #
      system("cp ".$basedir."pozvanka.templ.tex ".$texfile);
      open(TEXFILE,">>$texfile") or die "Nelze zalo¾it soubor '$texfile'\n";
      writeDocument();
      close(TEXFILE);
      # projedeme programem 'vlna'
#      print "... running 'vlna' for '$dataname'\n";
      system("vlna -r -s $dataname");
#or die "Nelze spustit program 'vlna'\n";
      system("cd $tempdir; pdfcslatex $texfile; cp $tempdir$pdffile $pdfdir");
# or die "Nelze spustit program '$texfile'\n";
   }      
   $db->disconnect;
