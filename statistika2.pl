#!/usr/bin/perl
use lib "/home/rusek/lib/";
use DBI;
use locale;
use CommonPgC;
use Mkrec;
use Data::Dumper;
use Getopt::Std;

	$kalrok = 2002;
	$obdobi = "YEAR(kurz_termin.den_od)=$kalrok";
	$Data::Dumper::Indent = 3;
		
		$delim = "</hodnota><hodnota>";
		$row_begin = "<radek><hodnota>";
		$row_end = "</hodnota></radek>";
		$xml_head = "<?xml version=\"1.0\" encoding=\"iso-8859-2\" ?>\n<?xml-stylesheet href=\"msmt.xsl\" type=\"text/xsl\" ?>\n";

	sub round {
		my ($c) = @_;
		if(int(($c - int($c))*10) < 5) {
			$c = int($c);
		} else {
			$c = int($c)+1;
		}
		return $c;
	}

	sub parseTerminPS {
		my ($id_akce,$nazev,$urceni_cis,$urceni,$sum_hodin,$pocet,$id_urceni) = @_;
		# oprava nesmyslu
		$nazev =~ s/\<//g;
		$urceni =~ s/\<//g;
		$nazev =~ s/\r//g;
		$urceni =~ s/\r//g;
#		$nazev="a";
#		$urceni="b";
#		$id_akce="aa";
#		$sum_hodin="bb";
#		$pocet="xx";
	if($id_urceni != 0) {
			$urc = $urceni_cis;
			if($urceni ne "") { $urc .= ", ".$urceni;}
		} else {
			$urc = $urceni;
		}
#		$urc="c";
		print $row_begin.$id_akce.$delim.$nazev.$delim.round($sum_hodin).$delim.$urc.$delim.$pocet.$row_end."\n";
		return;
	}
   
	#############
	#  M A I N  #
	#############
	
	$db = DBI->connect("$db_host_port;$mysql_sock",$user,$passw) or die "Nelze otevøít databázi: ".DBI->errstr."\n";
  	$from_tbls = "kurz LEFT JOIN kurz_termin USING (id_kurz)";

	########################
	#    tabulka pro PS    #
	########################
	print $xml_head;
	print "<data>\n";
	# akreditovane akce
	$akredit = "kurz.id_akredit<>0";
	$q_rec = $db->prepare("SELECT kurz.id_akce, kurz.nazev, urceni.popis, kurz.urceni, SUM(zprava.hodin), COUNT(*), kurz.id_urceni FROM $from_tbls LEFT JOIN zprava USING (id_kurz,id_termin), urceni WHERE $obdobi AND $akredit AND kurz.id_urceni=urceni.id_urceni GROUP BY TRIM(kurz.nazev) HAVING SUM(zprava.hodin) != 0 ORDER BY kurz.nazev, kurz.id_kurz, kurz_termin.id_termin ");
	
	$q_rec->execute();
	print "<nadpis>Statistika pro PS, rok $kalrok</nadpis>\n";
	print "<tabulka>\n";
	print "<nazev>Tabulka pro PS - akreditované akce, rok $kalrok</nazev>\n";
	$tbl_head = $row_begin."èíslo akce".$delim."název".$delim."hod.dotace".$delim."cílová skupina".$delim."opakování".$row_end;
	print $tbl_head;
	while (@pol = $q_rec->fetchrow_array) {
			parseTerminPS(@pol);  
	}
	print "</tabulka>\n";

	# neakreditovane akce
	$akredit = "kurz.id_akredit=0";
	$q_rec = $db->prepare("SELECT kurz.id_akce, kurz.nazev, urceni.popis, kurz.urceni, SUM(zprava.hodin), COUNT(*), kurz.id_urceni FROM $from_tbls LEFT JOIN zprava USING (id_kurz,id_termin), urceni WHERE $obdobi AND $akredit AND kurz.id_urceni=urceni.id_urceni GROUP BY kurz.nazev ORDER BY kurz.nazev, kurz.id_kurz, kurz_termin.id_termin");
	
	$q_rec->execute();
	print "<tabulka>\n";
	print "<nazev>Tabulka pro PS - neakreditované akce, rok $kalrok</nazev>\n";
	print $tbl_head;
	while (@pol = $q_rec->fetchrow_array) {
		parseTerminPS(@pol);  
	}
	print "</tabulka>\n";

	print "</data>\n";

#  $db->disconnect;
