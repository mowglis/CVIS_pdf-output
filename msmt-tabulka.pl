#!/usr/bin/perl
use lib "/home/rusek/lib/";
use DBI;
use locale;
use CommonPgC;
use Mkrec;
use Data::Dumper;
use Getopt::Std;

  $skrok0 = 2000;
  $polo0 = 2;
  $skrok1 = 2001;
  $polo1 = 1;
  $obdobi = "((kurz.sk_rok=$skrok0 AND kurz.pololeti=$polo0) OR (kurz.sk_rok=$skrok1 AND kurz.pololeti=$polo1))";

   sub upravHodiny {
      my ($h) = @_;
      $h =~ s/^\W*//;
      @pom = split(/\s/,$h);
      $pom[0] =~ s/\D/0/g;
      return int($pom[0]);
   }

   sub podleOboru {
      my ($obor) = @_;
      @sl = ();
      $q_rec = $db->prepare("SELECT id_kurz,rozsah FROM kurz WHERE $obdobi AND kurz.zruseno=0 AND SUBSTRING(id_akce,2,1)= ? ");
      $q_rec->execute($obor);
      $sl[3] = 0;
      while (@pol = $q_rec->fetchrow_array) {
         $id_kurz = $pol[0];
         # pocet lidi
         $q_lidi = $db->prepare("SELECT count(*) FROM ucast_kurz WHERE id_kurz=$id_kurz");
         $q_lidi->execute();
         @lidi = $q_lidi->fetchrow_array;
         $sl[0] += 1; # celkem akci
         $hodin = upravHodiny($pol[1]); # celkem hodin
         $sl[1] += $hodin;
         $sl[2] += $lidi[0]; # celkem lidi
         $sl[3] += $hodin*$lidi[0]; # osobohodiny
      }
      return @sl;
   }      

  $db = DBI->connect("$db_host_port;$mysql_sock",$user,$passw) or die "Nelze otevøít databázi: ".DBI->errstr."\n";
  #
  # akredit. akce celkem, nezruseno
  $q_rec = $db->prepare("SELECT COUNT(*) FROM kurz WHERE ((sk_rok=$skrok0 AND pololeti=$polo0) OR (sk_rok=$skrok1 AND pololeti=$polo1)) AND id_akredit<>'0' AND zruseno=0;");
  $q_rec->execute();
  @pol = $q_rec->fetchrow_array;
  $tab[0] = $pol["0"];
  # akredit. akce celkem, nezruseno - pouze jednoznacne nazvy
  $q_rec = $db->prepare("SELECT COUNT(DISTINCT nazev) FROM kurz WHERE ((sk_rok=$skrok0 AND pololeti=$polo0) OR (sk_rok=$skrok1 AND pololeti=$polo1)) AND id_akredit<>'0'");
  $q_rec->execute();
  @pol = $q_rec->fetchrow_array;
  $tab[65] = $pol["0"];
  # akce - pouze akreditovane - vsechny
  $q_rec = $db->prepare("SELECT COUNT(*) FROM kurz WHERE ((sk_rok=$skrok0 AND pololeti=$polo0) OR (sk_rok=$skrok1 AND pololeti=$polo1)) AND id_akredit<>'0'");
  $q_rec->execute();
  @pol = $q_rec->fetchrow_array;
  $tab[1] = $pol["0"];
  # akce - pouze akreditovane - vsechny, zrusene
  $q_rec = $db->prepare("SELECT COUNT(*) FROM kurz WHERE ((sk_rok=$skrok0 AND pololeti=$polo0) OR (sk_rok=$skrok1 AND pololeti=$polo1)) AND id_akredit<>'0' AND zruseno=1");
  $q_rec->execute();
  @pol = $q_rec->fetchrow_array;
  $tab[2] = $pol[0];
   # akce - pouze akreditovane - vsechny, zrusene
  $q_rec = $db->prepare("SELECT COUNT(DISTINCT nazev) FROM kurz WHERE ((sk_rok=$skrok0 AND pololeti=$polo0) OR (sk_rok=$skrok1 AND pololeti=$polo1)) AND id_akredit<>'0' AND zruseno=1");
  $q_rec->execute();
  @pol = $q_rec->fetchrow_array;
  $tab[66] = $pol[0];
 # ucastnici -  all, nezrusene akce, pouze akreditovane
  $q_rec = $db->prepare("SELECT COUNT(*) FROM kurz,ucast_kurz WHERE ((kurz.sk_rok=$skrok0 AND kurz.pololeti=$polo0) OR (kurz.sk_rok=$skrok1 AND kurz.pololeti=$polo1)) AND kurz.id_akredit<>'0' AND kurz.zruseno=0 AND kurz.id_kurz=ucast_kurz.id_kurz");
  $q_rec->execute();
  @pol = $q_rec->fetchrow_array;
  $tab[3] = $pol[0];
  # ucastnici -  podle skoly
  $q_rec = $db->prepare("SELECT ucast_kurz.izo,skola.typ_skoly FROM kurz,ucast_kurz,skola WHERE ((kurz.sk_rok=$skrok0 AND kurz.pololeti=$polo0) OR (kurz.sk_rok=$skrok1 AND kurz.pololeti=$polo1)) AND kurz.id_akredit<>'0' AND kurz.zruseno=0 AND kurz.id_kurz=ucast_kurz.id_kurz AND ucast_kurz.izo=skola.izo");
  $q_rec->execute();
  while (@pol = $q_rec->fetchrow_array) {
    $izo = $pol[0];
    $typ = $pol[1];
    $set = 0;
    if($typ eq "MS"){
      $tab[4]+=1; 
      $set=1;
    }
    if($typ eq "SS"){
      $tab[6]+=1; 
      $set=1;
    }
    if(($typ eq "ZS1-5") or ($typ eq "ZS1-9")){
      $tab[5]+=1; 
      $set=1;
    }
    if($set eq "0"){
      $tab[7]+=1;
    }
  }
  # jednorazove vzdelavaci akce
  $q_rec = $db->prepare("SELECT count(*) FROM kurz,kurz_termin WHERE $obdobi AND kurz.zruseno=0 AND kurz.id_kurz=kurz_termin.id_kurz AND kurz.cyklus=0");
  $q_rec->execute();
  @pol = $q_rec->fetchrow_array;
  $tab[8] = $pol[0];
  # jednorazove vzdelavaci akce - pocet hodin
  $q_rec = $db->prepare("SELECT rozsah,id_kurz FROM kurz WHERE $obdobi AND kurz.zruseno=0 AND kurz.cyklus=0");
  $q_rec->execute();
  $sumhodin=0;
  $sumlidi;
  while (@pol = $q_rec->fetchrow_array) {
      $hodin = upravHodiny($pol[0]);
      $id_kurz = $pol[1];
      # ucastnici na akci
      $q_rec2 = $db->prepare("SELECT count(*) FROM kurz,ucast_kurz WHERE $obdobi AND kurz.zruseno=0 AND kurz.id_kurz=ucast_kurz.id_kurz AND kurz.cyklus=0 AND kurz.id_kurz=$id_kurz");
      $q_rec2->execute();
      @pol2 = $q_rec2->fetchrow_array;
      $lidi = $pol2[0];
      $sumhodin += $hodin;   
      $sumlidi += $lidi;
      $sumohod += $lidi*$hodin;
  }
  $tab[9] = $sumhodin;
  $tab[10] = $sumlidi;
  $tab[11] = $sumohod;
  # jednorazove vzdelavaci akce - pocet ucstniku
#  $q_rec = $db->prepare("SELECT count(*) FROM kurz,ucast_kurz WHERE $obdobi AND kurz.zruseno=0 AND kurz.id_kurz=ucast_kurz.id_kurz AND kurz.cyklus=0");
#  $q_rec->execute();
#  @pol = $q_rec->fetchrow_array;
#  $tab[10] = $pol[0];
#  $tab[11]=$tab[9]*$tab[10];

  # cyklicke vzdelavaci akce
  $cyklus = "kurz.cyklus=1";
  
  $q_rec = $db->prepare("SELECT id_kurz,rozsah FROM kurz WHERE $obdobi AND kurz.zruseno=0 AND $cyklus");
  $q_rec->execute();
  $tab[15] = 0;
  $tab[23] = 0;
   while (@pol = $q_rec->fetchrow_array) {
      $id_kurz = $pol[0];
      # pocet lidi
      $q_lidi = $db->prepare("SELECT count(*) FROM ucast_kurz WHERE id_kurz=$id_kurz");
      $q_lidi->execute();
      @lidi = $q_lidi->fetchrow_array;
      $hodin = int(upravHodiny($pol[1]));
      $tab[12] += 1;                      # celkem akci
      $tab[13] += $hodin;                 # celkem hodin
      $tab[14] += $lidi[0];               # celkem lidi
      $tab[15] += $hodin*$lidi[0];   # osobohodiny
      if($hodin < 10) {
         $tab[16] += 1;
         $tab[17] += $hodin;
         $tab[18] += $lidi[0];
          $tab[19]+=$hodin*$lidi[0]; 
       }  
      if($hodin < 20 && $hodin >= 10) {
         $tab[20] += 1;
         $tab[21] += $hodin;
         $tab[22] += $lidi[0];
          $tab[23]+=$hodin*$lidi[0]; 
       }  
      if($hodin >= 20) {
         $tab[24] += 1;
         $tab[25] += $hodin;
         $tab[26] += $lidi[0];
          $tab[27]+=$hodin*$lidi[0]; 
       }  
   }         
   
   $tab[28]=$tab[8]+$tab[12];    # celkem
   $tab[29]=$tab[9]+$tab[13];
   $tab[30]=$tab[10]+$tab[14];
   $tab[31]=$tab[11]+$tab[15];

   # podle urceni - polozka 32-59
   @pom =  podleOboru("0");
   $tab[32] = $pom[0]; $tab[33] = $pom[1]; $tab[34] = $pom[2]; $tab[35] = $pom[3];
   @pom =  podleOboru("4");
   $tab[36] = $pom[0]; $tab[37] = $pom[1]; $tab[38] = $pom[2]; $tab[39] = $pom[3];
   @pom =  podleOboru("6");
   $tab[40] = $pom[0]; $tab[41] = $pom[1]; $tab[42] = $pom[2]; $tab[43] = $pom[3];
   @pom =  podleOboru("1");
   $tab[44] = $pom[0]; $tab[45] = $pom[1]; $tab[46] = $pom[2]; $tab[47] = $pom[3];
   @pom =  podleOboru("7");
   $tab[48] = $pom[0]; $tab[49] = $pom[1]; $tab[50] = $pom[2]; $tab[51] = $pom[3];
   @pom =  podleOboru("5");
   $tab[52] = $pom[0]; $tab[53] = $pom[1]; $tab[54] = $pom[2]; $tab[55] = $pom[3];
   # ostatni
   @pom =  podleOboru("2");
   $tab[56] += $pom[0]; $tab[57] += $pom[1]; $tab[58] += $pom[2]; $tab[59] += $pom[3];
   @pom =  podleOboru("3");
   $tab[56] += $pom[0]; $tab[57] += $pom[1]; $tab[58] += $pom[2]; $tab[59] += $pom[3];
   @pom =  podleOboru("8");
   $tab[56] += $pom[0]; $tab[57] += $pom[1]; $tab[58] += $pom[2]; $tab[59] += $pom[3];
   @pom =  podleOboru("9");
   $tab[56] += $pom[0]; $tab[57] += $pom[1]; $tab[58] += $pom[2]; $tab[59] += $pom[3];
   @pom =  podleOboru("V");
   $tab[56] += $pom[0]; $tab[57] += $pom[1]; $tab[58] += $pom[2]; $tab[59] += $pom[3];
  ########### tisk  
  $i=0;
  for my $p (@tab) {
    print "polozka [$i] --> $p\n";
    $i++;
  }
#  $db->disconnect;
