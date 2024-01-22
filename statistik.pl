#!/usr/bin/perl
# options:
#		-y rok
#		-m mesic do
#		-d den do
# 	-s mesic od
use lib "/home/rusek/lib/";
use DBI;
use locale;
use CommonPgC;
use Mkrec;
use Data::Dumper;
use Getopt::Std;
use POSIX qw(strftime);

#	$kalrok = 2002;
	getopts("y:m:d:s:");
	$datum = strftime "%e. %b (%a) %Y, %H:%M:%S", localtime;
	if($opt_y eq undef) { die"Neni zadan kalendarni rok!!! - KONCIM\n"; }
	$kalrok = $opt_y;
	$obdobi = "YEAR(kurz_termin.den_od)=$kalrok";
	$mes_den = undef;
	##### zadano omezeni na mesic DO - nikoli den
	if($opt_m ne undef && $opt_d eq undef) {
		$obdobi .= " and MONTH(kurz_termin.den_od)<=$opt_m";
		$mes_den = "$opt_m.";
	}
	##### zadano omezeni na mesic i den - DO
	if($opt_m ne undef && $opt_d ne undef) {
		$obdobi .= " and (MONTH(kurz_termin.den_od)<$opt_m or (MONTH(kurz_termin.den_od)=$opt_m and DAYOFMONTH(kurz_termin.den_od)<=$opt_d))";
		$mes_den = "$opt_d.$opt_m.";
	}
	##### chceme pocitat ne od pocatku roku, ale od urc. mesice - OD - vcetne
	if($opt_s ne undef) {
		$obdobi .= " and MONTH(kurz_termin.den_od)>=$opt_s";
		$mes_den = "$opt_s. - ".$mes_den;
	}
	if($mes_den ne undef) {
		$mes_den = "(".$mes_den.")";
	}
		
	$Data::Dumper::Indent = 3;
	$tab = (); $tab2 = (); 
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
		
		$delim = "</hodnota><hodnota>";
		$delim_num = "</hodnota_num><hodnota_num>";
		$delim_text_num = "</hodnota><hodnota_num>";
		$row_begin = "<radek><hodnota>";
		$row_end = "</hodnota></radek>";
		$row_end_num = "</hodnota_num></radek>";
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
		$tab2[$r][4] += ($ucast * $hodin);
	}
	
	sub vystupTab {

		print $xml_head;
		print "<data>\n";
		print "<nadpis>Statistika vzdìlávacích akcí - rok $kalrok $mes_den</nadpis>\n";
		print "<datum>$datum</datum>\n";
		print "<tabulka>\n";
		print "<nazev>Tabulka è. 1:</nazev>\n";
		foreach $row ( 0..7 ) {
			print $row_begin.$tabText->[$row].$delim_text_num.$tab[$row].$row_end_num."\n";
		}
		print "</tabulka>\n";
#		print "Kontrolní souèet".$delim.$suma."\n\n";
		print "<tabulka>\n";
		print "<nazev>Tabulka è. 2:</nazev>\n";
		print "<radek><zahlavi></zahlavi><zahlavi>Celkový poèet vzd. akcí</zahlavi><zahlavi>Celkový poèet hodin</zahlavi><zahlavi>Celkový poèet úèastníkù</zahlavi><zahlavi>Celkový poèet osobohodin</zahlavi></radek>\n";
		foreach $row ( 0..5 ) {
			print $row_begin.$tab2Text->[$row].$delim_text_num.$tab2[$row][1].$delim_num.$tab2[$row][2].$delim_num.$tab2[$row][3].$delim_num.$tab2[$row][4].$row_end_num."\n";
		}
		# rozdeleni podle oboru
#		print "\nRozdeleni podle oboru:\n";
		foreach $row ( 6..16 ) {
			print $row_begin.$tab2Text->[$row].$delim_text_num.$tab2[$row][1].$delim_num.$tab2[$row][2].$delim_num.$tab2[$row][3].$delim_num.$tab2[$row][4].$row_end_num."\n";
		}
		print "</tabulka>\n</data>";
	}

	sub parseTermin {
		my ($id_kurz,$id_akce,$id_termin,$nazev,$cyklus,$dni,$hodin,$ucast,$pocet_ms,$pocet_zs,$pocet_ss,$pocet_sps,$pocet_ost,$den_od,$prijmeni) = @_;
		# uprava 31.03.2003 - vynechat vystavy - 'ov'
		if(oborFromID($id_akce) eq "0v" || oborFromID($id_akce) eq "0V") {return;}
		# 12.3. - zaokrouhleni hodin
		$hodin = round($hodin);
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
			$cyk = "cykl";
			if($id_termin == 1 and $dni eq "") {
				$er = "ERROR-DATA";
			}
		} else { 
			$cyk = "jedn";
			if($dni eq "") {
				$er = "ERROR-DATA";
			}
		}
		# kontrola ucastniku
		$sumUcast = $pocet_ms+$pocet_zs+$pocet_ss+$pocet_sps+$pocet_ost;
		if($ucast*1 == $sumUcast) {
			$checkSuma = "";
		} else {
			$checkSuma = "***ERROR-UCAST($ucast!=$sumUcast)";
		}
		#
		# kontrolni tisk
		#
		#print "$new_pr $cyk $id_kurz:$id_akce:$id_termin:$nazev:$cyklus:$dni:$hodin:$ucast=$pocet_ms+$pocet_zs+$pocet_ss+$pocet_sps+$pocet_ost...$er$checkSuma\n";
		if(index($checkSuma,'ERROR') >= 0 || index($er,'ERROR') >=0) {
			$del = "</hodnota_err><hodnota_err>";
			$r_begin = "<radek><hodnota_err>";
			$r_end = "</hodnota_err></radek>";
		} else {
			$del = "</hodnota><hodnota>";
			$r_begin = "<radek><hodnota>";
			$r_end = "</hodnota></radek>";
		}
		print STDERR $r_begin.$new_pr.$del.$cyk.$del.$id_akce.$del.$den_od.$del.$nazev.$del.$dni.$del.$hodin.$del.$ucast.$del.$pocet_ms.$del.$pocet_zs.$del.$pocet_ss.$del.$pocet_sps.$del.$pocet_ost.$del.$prijmeni.$del.$er.$checkSuma.$r_end."\n";
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
		if(oborFromZprava(\@obor,2))  { wrTab(11,$new,$ucast,$hodin); return; } # multikultura 
		if(oborFromID($id_akce) eq "01") { wrTab(9,$new,$ucast,$hodin); return; } # psychologie, pedag.
		if(oborFromZprava(\@obor,1))  { wrTab(10,$new,$ucast,$hodin); return; }
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
	# kontrolni tisky
		print STDERR $xml_head;
		print STDERR "<data>\n";
		print STDERR "<nadpis>Statistika vzdìlávacích akcí - rok $kalrok $mes_den</nadpis>\n";
		print STDERR "<datum>$datum</datum>\n";
		# legenda
		print STDERR "<tabulka>\n";
		print STDERR "<nazev>Legenda</nazev>\n";
		print STDERR "<radek><zahlavi>sloupec</zahlavi><zahlavi>popis</zahlavi></radek>\n";
		print STDERR "<radek><hodnota_num>A</hodnota_num><hodnota>nová akce (NEW) - pokraèování (CONT)</hodnota></radek>\n";
		print STDERR "<radek><hodnota_num>B</hodnota_num><hodnota>jednotlivá akce (jedn) - cyklus (cykl)</hodnota></radek>\n";
		print STDERR "<radek><hodnota_num>C</hodnota_num><hodnota>èíslo akce</hodnota></radek>\n";
		print STDERR "<radek><hodnota_num>D</hodnota_num><hodnota>datum (RRRR-MM-DD)</hodnota></radek>\n";
		print STDERR "<radek><hodnota_num>E</hodnota_num><hodnota>název akce</hodnota></radek>\n";
		print STDERR "<radek><hodnota_num>F</hodnota_num><hodnota>poèet dní</hodnota></radek>\n";
		print STDERR "<radek><hodnota_num>G</hodnota_num><hodnota>poèet hodin</hodnota></radek>\n";
		print STDERR "<radek><hodnota_num>H</hodnota_num><hodnota>úèast</hodnota></radek>\n";
		print STDERR "<radek><hodnota_num>I</hodnota_num><hodnota>poèet z M©</hodnota></radek>\n";
		print STDERR "<radek><hodnota_num>J</hodnota_num><hodnota>poèet ze Z©</hodnota></radek>\n";
		print STDERR "<radek><hodnota_num>K</hodnota_num><hodnota>poèet ze S©</hodnota></radek>\n";
		print STDERR "<radek><hodnota_num>L</hodnota_num><hodnota>poèet ze SP©</hodnota></radek>\n";
		print STDERR "<radek><hodnota_num>M</hodnota_num><hodnota>ostatní</hodnota></radek>\n";
		print STDERR "<radek><hodnota_num>N</hodnota_num><hodnota>garant akce</hodnota></radek>\n";
		print STDERR "<radek><hodnota_num>O</hodnota_num><hodnota>poznámka (ERROR = chyba)</hodnota></radek>\n";
		print STDERR "</tabulka>\n";
		# data 
		print STDERR "<tabulka>\n";
		print STDERR "<nazev>Výpis akcí</nazev>\n";
		print STDERR "<radek><zahlavi>A</zahlavi><zahlavi>B</zahlavi><zahlavi>C</zahlavi><zahlavi>D</zahlavi><zahlavi>E</zahlavi><zahlavi>F</zahlavi><zahlavi>G</zahlavi><zahlavi>H</zahlavi><zahlavi>I</zahlavi><zahlavi>J</zahlavi><zahlavi>K</zahlavi><zahlavi>L</zahlavi><zahlavi>M</zahlavi><zahlavi>N</zahlavi><zahlavi>O</zahlavi></radek>\n";
#	$count = 0;
	while (@pol = $q_rec->fetchrow_array) {
#		$count++;
		parseTermin(@pol);  
	}
		print STDERR "</tabulka>\n";
		print STDERR "</data>\n";
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
