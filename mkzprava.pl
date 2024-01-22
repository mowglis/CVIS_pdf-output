#!/usr/bin/perl
#--------------------------------------------------
#	
#	Vytvori data pro zpravu vzdelavaci akce
#	
#	options:
#
#	-k		id_kurz
#	-t		id_termin
#	-d		datum tisku
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
#$tempdir = "/home/rusek/dokumenty/pdf-output/temp/";
$tempdir = "/home/rusek/dokumenty/pdf-output/tmp/";

	sub termFmt {
		my($den_od,$den_do)=@_;
		@den1 = split(/-/,$den_od);
		@den2 = split(/-/,$den_do);
		$datum = "$den1[2].$den1[1].$den1[0]";
		if($den_do ne "0000-00-00") {
			$datum .= "--$den2[2].$den2[1].$den2[0]";
		}			
		return $datum;
	}	
	sub defMacro {
		my($name,$value)=@_;
#		print "name: $name value: $value\n";
		if($value eq "") {$value = "\\mbox{}";}	

		print DATA "\\def\\".$name."{$value}\n";
		return;
	}	
	sub upravCislo {
		my($cislo)=@_;
		$cislo =~ s/^0.00$//g;
		return $cislo
	}

   sub ucastnici {
	my ($id_kurz,$id_termin,$sk_rok,$id_akce) = @_;
	$q_rec_ucastnici->execute($id_kurz,$id_termin,$sk_rok);
	$i=0;
	$tbl_ucastniku = "
\\def\\THead{%
\\hline
\\hi{Pøíjmení a jméno} & \\hi{èíslo osvìdèení} & \\hi{Pøíjmení a jméno} & \\hi{èíslo osvìdèení} \\\\
\\hline
}
\\tablefirsthead{\\THead}
\\tablehead{\\THead}
\\tabletail{%
\\hline
\\multicolumn{4}{|r|}{\\small\\sl \\dots pokraèování na dal¹í stranì}\\\\
\\hline}
\\tablelasttail{\\hline}

\\begin{supertabular}{||l|l||l|l||}
\n";
	while (($prijmeni,$jmeno,$titul,$c_prihlasky) = $q_rec_ucastnici->fetchrow_array) {
		$i++;
		$c_osvedceni = "$id_akce/$sk_rok/$c_prihlasky";
		if ($i % 2 == 0) {
			$tbl_ucastniku .= "$titul $prijmeni $jmeno & $c_osvedceni \\\\\n";
		} else {
			$tbl_ucastniku .= "$titul $prijmeni $jmeno & $c_osvedceni & ";
		}
	}
	if ($i % 2 == 1) {
		$tbl_ucastniku .= " & \\\\\n";
	}
	$tbl_ucastniku .= "\\hline
\\end{supertabular}\n";
#	print "tbl_ucastniku: $tbl_ucastniku\n";
	return $tbl_ucastniku;
   }

   sub writeRec {
	   my ($sk_rok,$pololeti,$titul,$jmeno,$prijmeni,$nazev,$id_akce,$den_od,$den_do,$misto,$lektor,
		$id_kurz,
		$id_t,
		$obsah,
		$prubeh,
		$dni,
		$hodin,
		$ucast,
		$poplatek,
		$hodnoceni,
		$doporuceni,
		$poznamka,
		$pozn_small,
		$naklady,
		$vynosy,
		$zisk,
		$obsah_50117,
		$obsah_51210,
		$obsah_51810,
		$obsah_51811,
		$obsah_54910,
		$obsah_52112,
		$obsah_0,
		$obsah_1,
		$kc_50117,
		$kc_51210,
		$kc_51810,
		$kc_51811,
		$kc_54910,
		$kc_52112,
		$kc_0,
		$kc_1,
		$prijem_vlozne,
		$prijem_jine,$pozn_eko,$t_ucastniku)=@_;

#		print Dumper(@_);
#		print $obsah_0,$obsah_1."\n";
#		print $kc_x,$kc_1."\n";
		$skrok2 = $sk_rok*1 + 1;
		$sk_rok .= "/".$skrok2;
		defMacro("skrok",$sk_rok);
		defMacro("pololeti",$pololeti);
		defMacro("dtisk",$dtisk);
		defMacro("garant","$titul $jmeno $prijmeni");
		defMacro("idAkce",idAkce($id_akce,$sk_rok));
		defMacro("nazev",OpravChyby($nazev));
	#	defMacro("nazev",$nazev);
		defMacro("termin",ParseDatum($den_od,$den_do));
		defMacro("misto",$misto);
		defMacro("obsah",OpravChyby($obsah));
		defMacro("lektor",OpravChyby($lektor));
		defMacro("prubeh",OpravChyby($prubeh));
		defMacro("dni",$dni);
		defMacro("hodin",$hodin);
		defMacro("ucast",$ucast);
		defMacro("poplatek",$poplatek);
		defMacro("hodnoceni",OpravChyby($hodnoceni));
		defMacro("doporuceni",OpravChyby($doporuceni));
		defMacro("poznamka",OpravChyby($poznamka));
#		defMacro("poznamkaEko",OpravChyby(""));
		defMacro("poznamkaEko",OpravChyby($pozn_eko));

		defMacro("obsahA",OpravChyby($obsah_50117));
		defMacro("obsahB",OpravChyby($obsah_51210));
		defMacro("obsahC",OpravChyby($obsah_51810));
		defMacro("obsahD",OpravChyby($obsah_51811));
		defMacro("obsahE",OpravChyby($obsah_54910));
		defMacro("obsahF",OpravChyby($obsah_52112));
		defMacro("obsahG",OpravChyby($obsah_0));
		defMacro("obsahH",OpravChyby($obsah_1));

		defMacro("kcA",upravCislo($kc_50117));
		defMacro("kcB",upravCislo($kc_51210));
		defMacro("kcC",upravCislo($kc_51810));
		defMacro("kcD",upravCislo($kc_51811));
		defMacro("kcE",upravCislo($kc_54910));
		defMacro("kcF",upravCislo($kc_52112));
		defMacro("kcG",upravCislo($kc_0));
		defMacro("kcH",upravCislo($kc_1));

#		print "!!!!! ".upravCislo($kc_0),upravCislo($kc_1)."\n";
		defMacro("prijemVlozne",upravCislo($prijem_vlozne));
		defMacro("prijemJine",upravCislo($prijem_jine));
	
		defMacro("naklady",$naklady);
		defMacro("vynosy",$vynosy);
		defMacro("zisk",$zisk);
		defMacro("logoline",logoline($id_kurz,0));
		# tabulka ucastniku
#		defMacro("ucastnici",$t_ucastniku);
		
	}
#--------------------------------------------
# 			hlavni program
#--------------------------------------------
	getopt("k:t:d:");
	$id_kurz = $opt_k;
	$id_termin = $opt_t;
	$dtisk = $opt_d;
	print "Hello, I'm generating LaTex source!\n";
	$db = DBI->connect("$db_host_port;$mysql_sock",$user,$passw) or die "Nelze otevøít databázi: ".DBI->errstr."\n";
	
	$whr = "zprava.id_kurz=kurz.id_kurz AND kurz.id_garant=zam.rc_zam AND zprava.id_kurz=kurz_termin.id_kurz AND zprava.id_termin=kurz_termin.id_termin AND zprava.id_kurz=? AND zprava.id_termin=?";
	$q_rec = $db->prepare("SELECT kurz.sk_rok,kurz.pololeti,zam.titul,zam.jmeno,zam.prijmeni,kurz.nazev,kurz.id_akce,kurz_termin.den_od,kurz_termin.den_do,kurz_termin.misto,kurz.lektor,zprava.* FROM zprava,kurz,kurz_termin,zam WHERE  $whr");
	$q_rec_ucastnici = $db->prepare("SELECT prijmeni,jmeno,titul,cislo_prihlasky FROM ucastnik,ucast_kurz WHERE ucast_kurz.rc_ucastnik=ucastnik.rc_ucastnik AND id_kurz=? AND id_termin=? AND sk_rok=? ORDER BY prijmeni,jmeno");
	$q_rec->execute($id_kurz,$id_termin);
	print "rows: ".$q_rec->rows."\n";;
	if($q_rec->rows>0){
		#
		# vytvoreni datoveho souboru
		#
		$suffix   = $id_kurz."-".$id_termin;
		$dataname = $tempdir."zpr_data_".$suffix.".tex";
		$texfile  = $tempdir."zpr_".$suffix.".tex";
		$pdffile  = "zpr_".$suffix.".pdf";
		open(DATA,">$dataname") or die "Nelze zalo¾it soubor: '$dataname'\n";
		@pol = $q_rec->fetchrow_array;
		$t_ucastniku = ucastnici($id_kurz,$id_termin,$pol[0],$pol[6]);
		print "ucastnici: $t_ucastniku\n";
		defMacro("ucastnici",$t_ucastniku);
		writeRec(@pol,$t_ucastniku);
      close DATA;
      #
      # priprava souboru tex
      #
      system("sed -e \"s/xxx/$suffix/g\" $basedir"."zpr.templ.tex > $texfile");
      system("vlna -r -s $dataname");
      system("cd $tempdir; pdfcslatex $texfile; cp $tempdir$pdffile $pdfdir");
   }      
