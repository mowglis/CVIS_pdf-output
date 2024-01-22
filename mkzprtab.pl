#!/usr/bin/perl
#--------------------------------------------------
#	
#	Vytvori data pro vyslednou tabulku ke zprave
#	
#	options:
#	-r		kalendarni rok
#	-p		pololeti (0 = obe pololeti)
#	-g		id garanta
#
#--------------------------------------------------	
use lib "/home/rusek/lib/";
use DBI;
use locale;
use CommonPgC;
use Mkrec;
use Data::Dumper;
use Getopt::Std;

$basedir = "/home/rusek/dokumenty/pdf-output/";
$tempdir = "/home/rusek/dokumenty/pdf-output/temp/";
#$dataname = $dir."data_pozv.tex";
	sub termFmt {
		my($den_od,$den_do)=@_;
  		$datum = substr(ParseDatum($den_od,$den_do,"1"),0,-5);
		return $datum;
	}		
	sub writeVars {
		open (TEXVARS,">$varsname") or die "Nelze zalo¾it soubor: '$varsname'\n";
		$q_garant = $db->prepare("SELECT titul,jmeno,prijmeni FROM zam WHERE rc_zam=?");
		$q_garant->execute($id_garant);
		@g = $q_garant->fetchrow_array;
		$gName = "$g[0] $g[1] $g[2]";
   	$gName =~ s/^\s*//;
		print TEXVARS "\\def\\garant{$gName}\n";
		print TEXVARS "\\def\\krok{$krok}\n";
		print TEXVARS "\\def\\kpolo{$kpolo}\n";
		print TEXVARS "\\def\\dtisk{$dtisk}\n";
		print TEXVARS "\\def\\sumNaklady{$sum_naklady}\n";
		print TEXVARS "\\def\\sumVynosy{$sum_vynosy}\n";
		print TEXVARS "\\def\\sumZisk{$sum_zisk}\n";
		print TEXVARS "\\def\\sumHodin{$sum_hodin}\n";
		print TEXVARS "\\def\\sumDni{$sum_dni}\n";
		print TEXVARS "\\def\\sumUcastnik{$sum_ucastnik}\n";
		close TEXVARS;
	}
   sub writeRec {
	   my ($inum,$id_kurz,$id_termin,$id_akce,$nazev,$den_od,$den_do,$dni,$hodin,$ucast,$poplatek,$naklady,$vynosy,$zisk,$cyklus,$pozn_small,$sk_rok)=@_;
		if($cyklus and $id_termin > 1) {
			$pozn_small = "pokraèování cyklu";
		}
		$termin = termFmt($den_od,$den_do);
		$nazev = OpravChyby($nazev);
		if($dni eq "") {$dni = "\\mbox{}"};
  		if($hodin eq "") {$hodin = "\\mbox{}"};
		if($ucast eq "") {$ucast = "\\mbox{}"};
		if($poplatek eq "") {$poplatek = "\\mbox{}"};
		if($naklady eq "") {$naklady = "\\mbox{}"};
 		if($vynosy eq "") {$vynosy = "\\mbox{}"};
 		if($zisk eq "") {$zisk = "\\mbox{}"};
 		if($pozn_small eq "") 
			{$pozn_small = "\\mbox{}";}
		else 
			{$pozn_small = OpravChyby($pozn_small);}
		$id_akce = idAkce($id_akce,$sk_rok);
		print DATA "$inum & $id_akce -- $nazev & $termin & $dni & $hodin & $ucast & $poplatek & $naklady & $vynosy & $zisk & \\poznftn $pozn_small \\\\\n";
		$sum_naklady += $naklady;
		$sum_vynosy += $vynosy;
		$sum_zisk += $zisk;
		$sum_hodin += $hodin;
		$sum_dni += $dni;
		$sum_ucastnik += $ucast;
	}
#--------------------------------------------
# 			hlavni program
#--------------------------------------------
	getopt("r:p:g:d:");
	$id_garant = $opt_g;
	$krok = $opt_r;
	$kpolo = $opt_p;
	$dtisk = $opt_d;
	print Dumper($opt_g);
	print Dumper($opt_r);
	print Dumper($opt_p);
	print "Hello, I'm generating LaTex source!\n";
	$db = DBI->connect("$db_host_port;$mysql_sock",$user,$passw) or die "Nelze otevøít databázi: ".DBI->errstr."\n";
	
	$whr = "kurz.id_kurz=kurz_termin.id_kurz AND kurz.zruseno=0 AND YEAR(den_od)=$krok";
	# pridano 13.1.2004 - generovani tabulky vsech akci
	if($id_garant != 999) {$whr .= " AND kurz.id_garant=$id_garant"};
	if($kpolo == 1) {
		$whr.=" AND MONTH(den_od) < 7";
	}		
	if($kpolo == 2) {
		$whr.=" AND MONTH(den_od) > 6";
	}		
	$order = "den_od";
	print Dumper($whr);
	$q_rec = $db->prepare("SELECT kurz.id_kurz,kurz_termin.id_termin,kurz.id_akce,kurz.nazev,den_od,den_do,dni,hodin,zprava.ucast,zprava.poplatek,naklady,vynosy,zisk,cyklus,pozn_small,kurz.sk_rok FROM kurz,kurz_termin LEFT JOIN zprava USING(id_kurz,id_termin) WHERE  $whr ORDER BY $order");
	$q_rec->execute();
	if($q_rec->rows>0){
		#
		# vytvoreni datoveho souboru
		#
		$dataname = $tempdir."tzpr_data_".$id_garant.".tex";
		$varsname = $tempdir."tzpr_vars_".$id_garant.".tex";
		$texfile  = $tempdir."tzpr_".$id_garant.".tex";
		$pdffile  = "tzpr_".$id_garant.".pdf";
		$inum = 0;
		$sum_naklady = 0;
		$sum_vynosy = 0;
		$sum_zisk = 0;
		$sum_hodin = 0;
		$sum_ucastnik = 0;
		$sum_dni = 0;
		open(DATA,">$dataname") or die "Nelze zalo¾it soubor: '$dataname'\n";
		while (@pol = $q_rec->fetchrow_array) {
			$id_kurz = $pol[0];
			$inum++;
			writeRec($inum,@pol);
		}			
      close DATA;
		writeVars;
      #
      # priprava souboru tex
      #
      system("sed -e \"s/xxx/$id_garant/g\" $basedir"."tzpr.templ.tex > $texfile");
      # system("vlna -r -s $dataname");
      system("cd $tempdir; pdfcslatex $texfile; cp $tempdir$pdffile $pdfdir");
   }      
