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
	$tabText = [
	  "Poèet akredit. akcí platných",
	  "Poèet akredit. akcí, které byly nabízeny",
	  " z toho poèet neuskuteènìných akcí",
	  "Celkový poèet úèastníkù akcí",
	  " z toho uèitelù M©",
	  " z toho uèitelù Z©",
	  " z toho uèitelù S©",
	  " z toho ostatní"
	  ];
	$tab2Text = [
		"Jednorázové vzdìlávací akce",
		"Cyklické vzdìlávací akce",
		" z toho do 10 vyuèovacích hodin",
		" z toho do 20 vyuèovacích hodin",
		" z toho nad 20 vyuèovacích hodin",
		"Celkem",
		"akce pro vedoucí pracovníky",
		"akce z oblasti výuky cizích jazykù",
		"akce z oblasti výpoèetní techniky, informatiky",
		"akce z oblasti psychologie",
		"akce z oblasti environmentální výchovy",
		"akce z oblasti multikulturní výchovy",
		"akce z oblasti humanitních oborù",
		"akce z oblasti pøírodních vìd",
		"akce z oblasti výchov",
		"akce z oblasti pøed¹kolní výchovy",
		"akce z ostatních oblastí"];
  	
	sub readOborZprava {
		my ($id_kurz,$id_termin) = @_;	
		@retPole =();
		$q_rec2 = $db->prepare("SELECT id_obor FROM l_zprava_obor WHERE id_kurz=$id_kurz AND id_termin=$id_termin");
		$q_rec2->execute();
		while (@pol = $q_rec2->fetchrow_array) { push (@retPole,$pol["0"]*1); }
#		print Dumper(@retPole);
		return @retPole;
	}

	sub oborFromZprava {
		my ($pole,$obor) = @_;
#		print "sub->".Dumper($pole,$obor);
		foreach $h (@$pole) {
			if($h == $obor) { return 1;}
		}
		return 0;
	}

	sub oborFromID {
		return substr($_[0],1,2);
	}

	sub wrTab {
		my ($r,$new,$ucast,$hodin) = @_;
		if($new) { $tab2[$r][1] += 1; }
		$tab2[$r][2] += $hodin;
		$tab2[$r][3] += $ucast;
		$tab2[$r][4] += $ucast * $hodin;
	}
	
	sub vystupTab {
		$delim = "</hodnota><hodnota>";
		$row_begin = "<radek><hodnota>";
		$row_end = "</hodnota></radek>";
		$xml_head = "<?xml version=\"1.0\" encoding=\"iso-8859-2\" ?>\n<?xml-stylesheet href=\"msmt.xsl\" type=\"text/xsl\" ?>\n";

		print $xml_head;
		print "<data>\n";
		print "<nadpis>Statistika vzdìlávacích akcí</nadpis>\n";
		print "<tabulka>\n";
		print "<nazev>Tabulka è. 1:</nazev>\n";
		foreach $row ( 0..7 ) {
			print $row_begin.$tabText->[$row].$delim.$tab[$row].$row_end."\n";
		}
		print "</tabulka>\n";
#		print "Kontrolní souèet".$delim.$suma."\n\n";
		print "<tabulka>\n";
	  print "<nazev>Tabulka è. 2:</nazev>\n";
		foreach $row ( 0..5 ) {
			print $row_begin.$tab2Text->[$row].$delim.$tab2[$row][1].$delim.$tab2[$row][2].$delim.$tab2[$row][3].$delim.$tab2[$row][4].$row_end."\n";
		}
		# rozdeleni podle oboru
#		print "\nRozdeleni podle oboru:\n";
		foreach $row ( 6..16 ) {
			print $row_begin.$tab2Text->[$row].$delim.$tab2[$row][1].$delim.$tab2[$row][2].$delim.$tab2[$row][3].$delim.$tab2[$row][4].$row_end."\n";
		}
		print "</tabulka>\n</data>";
	}

	sub parseTermin {
		my ($id_kurz,$id_akce,$id_termin,$nazev,$cyklus,$dni,$hodin,$ucast,$pocet_ms,$pocet_zs,$pocet_ss,$pocet_sps,$pocet_ost,$den_od,$prijmeni) = @_;
		if ($id_kurz != $id_kurz_pred) {
			$new_pr = "NEW";
			$new = 1;
			$id_kurz_pred = $id_kurz;
		} else { 
			$new_pr = "CON";
			$new = 0;
		}
		# 
		# BEGIN - kontroly
		#
		$er = "OK";
		if($cyklus) {
			$cyk = "<C>";
			if($id_termin == 1 and $dni eq "") {
				$er = "ERROR-DATA";
			}
		} else { 
			$cyk = "<->";
			if($dni eq "") {
				$er = "ERROR-DATA";
			}
		}
		# kontrola ucastniku
		$sumUcast = $pocet_ms+$pocet_zs+$pocet_ss+$pocet_sps+$pocet_ost;
		if($ucast*1 == $sumUcast) {
			$checkSuma = "";
		} else {
			$checkSuma = "***ERROR-UCAST($ucast<>$sumUcast)";
		}
		#
		# kontrolni tisk
		#
#		print "$new_pr $cyk $id_kurz:$id_akce:$id_termin:$nazev:$cyklus:$dni:$hodin:$ucast=$pocet_ms+$pocet_zs+$pocet_ss+$pocet_sps+$pocet_ost...$er$checkSuma\n";
		print STDERR "$id_akce;$den_od;$nazev;$dni;$hodin;$ucast;$pocet_ms;$pocet_zs;$pocet_ss;$pocet_sps;$pocet_ost;$prijmeni;$er$checkSuma\n";
		#
		# END - kontroly
		#
		$tab[4] += $pocet_ms;
		$tab[5] += $pocet_zs;
		$tab[6] += $pocet_ss;
		$tab[7] += $pocet_sps;
		$tab[7] += $pocet_ost;		
		if($cyklus) {
			#
			# cykly
			#
			wrTab(1,$new,$ucast,$hodin);
			if($hodin < 10)                 { wrTab(2,$new,$ucast,$hodin); }
			if($hodin < 20 && $hodin >= 10) { wrTab(3,$new,$ucast,$hodin); }
			if($hodin >= 20)                { wrTab(4,$new,$ucast,$hodin); }
		} else {
			#
			# jednorazove akce
			#
			wrTab(0,$new,$ucast,$hodin);
		}
		#
		# podle urceni akce - id_akce
		#
		if(oborFromID($id_akce) eq "00") { wrTab(6,$new,$ucast,$hodin); return; }
		if(oborFromID($id_akce) eq "04") { wrTab(7,$new,$ucast,$hodin); return; }
		if(oborFromID($id_akce) eq "12") { wrTab(8,$new,$ucast,$hodin); return; }
		if(oborFromID($id_akce) eq "01") { wrTab(9,$new,$ucast,$hodin); return; }
		if(oborFromID($id_akce) eq "03") { wrTab(12,$new,$ucast,$hodin); return; }
		if(oborFromID($id_akce) eq "06") { wrTab(13,$new,$ucast,$hodin); return; }
		if(oborFromID($id_akce) eq "08") { wrTab(14,$new,$ucast,$hodin); return; }
		if(oborFromID($id_akce) eq "10") { wrTab(14,$new,$ucast,$hodin); return; }
		# 
		# podle urceni ve zprave
		#
		@obor = readOborZprava($id_kurz,$id_termin);
#		print "$id_akce...trying from zprava\n";
#		print "main->".Dumper(@obor);
		if(oborFromZprava(\@obor,1))  { wrTab(10,$new,$ucast,$hodin); return; }
		if(oborFromZprava(\@obor,2))  { wrTab(11,$new,$ucast,$hodin); return; }
		if(oborFromZprava(\@obor,8))  { wrTab(12,$new,$ucast,$hodin); return; }
		if(oborFromZprava(\@obor,12)) { wrTab(13,$new,$ucast,$hodin); return; }
		if(oborFromZprava(\@obor,13)) { wrTab(13,$new,$ucast,$hodin); return; }
		if(oborFromZprava(\@obor,6))  { wrTab(15,$new,$ucast,$hodin); return; }
		# ostatni
		wrTab(16,$new,$ucast,$hodin);  
		return;
	}
   
	#############
	#  M A I N  #
	#############
	
	$db = DBI->connect("$db_host_port;$mysql_sock",$user,$passw) or die "Nelze otevøít databázi: ".DBI->errstr."\n";
  	$from_tbls = "kurz LEFT JOIN kurz_termin USING (id_kurz)";
	#
	# akce: akredit., vsechny nezrusene, jednoznac. nazev -> tab[0]
	#
	$q_rec = $db->prepare("SELECT COUNT(DISTINCT nazev) FROM $from_tbls WHERE $obdobi AND kurz.id_akredit<>'0' AND kurz.zruseno<>1");
	$q_rec->execute();
	@pol = $q_rec->fetchrow_array;
	$tab[0] = $pol["0"];
	#
  	# akce: akredit., vsechny, jednoznacne nazvy, -> tab[1]
	#
 	$q_rec = $db->prepare("SELECT COUNT(DISTINCT nazev) FROM $from_tbls WHERE $obdobi AND kurz.id_akredit<>'0'");
	$q_rec->execute();
	@pol = $q_rec->fetchrow_array;
	$tab[1] = $pol["0"];
	#
	# akce: neuskutecnene akce -> tab[2]
	#
	$q_rec = $db->prepare("SELECT COUNT(DISTINCT nazev) FROM $from_tbls WHERE $obdobi AND kurz.id_akredit<>'0' AND kurz.zruseno=1");
	$q_rec->execute();
	@pol = $q_rec->fetchrow_array;
	$tab[2] = $pol["0"];
	#
	# detailni zpracovani akci
	#
	$tab2 = ();
	$id_kurz_pred = 0;
 	$q_rec = $db->prepare("SELECT kurz.id_kurz,kurz.id_akce,kurz_termin.id_termin,kurz.nazev,kurz.cyklus,zprava.dni,zprava.hodin,zprava.ucast,zprava.pocet_ms,zprava.pocet_zs,zprava.pocet_ss,zprava.pocet_sps,zprava.pocet_ost,kurz_termin.den_od,zam.prijmeni FROM $from_tbls LEFT JOIN zprava USING (id_kurz,id_termin), zam WHERE $obdobi AND kurz.zruseno=0 AND kurz.id_garant=zam.rc_zam ORDER BY kurz.id_kurz, kurz_termin.id_termin");
	$q_rec->execute();
	while (@pol = $q_rec->fetchrow_array) {
		parseTermin(@pol);  
	}
	#
	# celkem
	#
	$tab2[5][1] = $tab2[0][1] + $tab2[1][1];
	$tab2[5][2] = $tab2[0][2] + $tab2[1][2];
	$tab2[5][3] = $tab2[0][3] + $tab2[1][3];
	$tab2[5][4] = $tab2[0][4] + $tab2[1][4];
	$tab[3] = $tab2[5][3];
	$suma = $tab[4]+$tab[5]+$tab[6]+$tab[7];
	vystupTab;
#  $db->disconnect;
