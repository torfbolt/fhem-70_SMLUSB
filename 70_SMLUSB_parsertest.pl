#!/bin/perl
use strict;
use warnings;


# New parser for 70_SMLUSB to be more flexible and intelligent
# Ready to be implemented into 70_SMLUSB
# ToDo:
# 
# 1. statusword parsing sucks. Find a good description to identify all informations (binary) out of the statusword.
#
# 2. same for unit and scaler!
#
# 3. Implement CRC16 check (for whole file and telegram/message)

my %obiscodes = (
 '77070100010800FF' => 'Zählerstand Bezug Total      ',
 '77070100020800FF' => 'Zählerstand Lieferung Total  ',
 '77070100010801FF' => 'Zählerstand Tarif 1 Bezug    ',
 '77070100020801FF' => 'Zählerstand Tarif 1 Lieferung',
 '77070100010802FF' => 'Zählerstand Tarif 2 Bezug    ',
 '77070100020802FF' => 'Zählerstand Tarif 2 Lieferung',
 '770701000F0700FF' => 'Momentanleistung',
 '77070100100700FF' => 'Momentanleistung',
 '77070100010700FF' => 'Momentanleistung Bezug - Voller');

my $smlfile;

#EHZ363WA
#$smlfile = "1B1B1B0101010176090000000003787BB362016200726301017601010900000000012828FE0B090148414700000370270101636A970076090000000003787BB4620162007263070177010B09014841470000037027070100620AFFFF7262016501D945D77777078181C78203FF01010101044841470177070100000009FF010101010B090148414700000370270177070100010800FF63028201621E52FF55058D9E020177070100010801FF0101621E52FF55020B969B0177070100010802FF0101621E52FF55038207660177070100100700FF0101621B52005300600177078181C78205FF01010101830215F0C14CCDD90D672023953F58F7E880879AC86A0CCBA59A715B783CB880969C2BC9A36E23096B10F37A777C528AA4F6010101637F370076090000000003787BB562016200726302017101636AC6001B1B1B1B1A008B02";

# ED300L
#$smlfile = "1B1B010101017607000A02792949620062007263010176010107000A01D90DC309080C2AEE2D4C4FB2010163C2CF007607000A0279294A6200620072630701770109080C2AEE2D4C4FB2070100620AFFFF7262016501D921BE7A77078181C78203FF0101010104454D480177070100000009FF0101010109080C2AEE2D4C4FB20177070100010800FF6401018201621E52FF5600018AFBB30177070100020800FF6401018201621E52FF560002B28E8C0177070100010801FF0101621E52FF5600018AFBB30177070100020801FF0101621E52FF560002B28E8C0177070100010802FF0101621E52FF5600000000000177070100020802FF0101621E52FF56000000000001770701000F0700FF0101621B52FF650000033B0177078181C78205FF017262016501D921BE01018302B129F735283A1BDE947854998A99985F91CF8C227D56885A7C54ED898B6BA534930154A11599F522F3DC0080223AC77A010101630080007607000A0279294D62006200726302017101630258000000001B1B1B1B1A038B68";

# ED300l Bezug
#my $smlfile = "1B1B1B1B010101017607000A02C72ED7620062007263010176010107000A01F30F9D09080C2AEE2D4C4FB20101639B75007607000A02C72ED86200620072630701770109080C2AEE2D4C4FB2070100620AFFFF7262016501F30CC67A77078181C78203FF0101010104454D480177070100000009FF0101010109080C2AEE2D4C4FB20177070100010800FF6401018201621E52FF56000199E5730177070100020800FF6401018201621E52FF560002E17CE40177070100010801FF0101621E52FF56000199E5730177070100020801FF0101621E52FF560002E17CE40177070100010802FF0101621E52FF5600000000000177070100020802FF0101621E52FF56000000000001770701000F0700FF0101621B52FF65000004840177078181C78205FF017262016501F30CC601018302B129F735283A1BDE947854998A99985F91CF8C227D56885A7C54ED898B6BA534930154A11599F522F3DC0080223AC77A0101016329A5007607000A02C72EDB6200620072630201710163E7D5000000001B1B1B1B1A03CEF3";

# Irgendwas
#$smlfile = "1B1B1B1B01010101760502BFBEC862006200726301017601010500EA94EE09080535342D4C92AD0101635ADE00760502BFBEC96200620072630701770109080535342D4C92AD070100620AFFFF726201650280C70E7B77078181C78203FF010101010449534B0177070100000009FF0101010109080535342D4C92AD0177070100010800FF650000018201621E52FF5900000000019EBA410177070100010801FF0101621E52FF5900000000019EBA410177070100010802FF0101621E52FF59000000000000000001770701000F0700FF0101621B5200650000008C0177070100150700FF0101621B520065000000010177070100290700FF0101621B5200650000008901770701003D0700FF0101621B520065000000010177070100600505FF0101010165000001820177078181C78205FF0101010183022A101995CE5A871E0CC67020E497B56B3CA68D4C7BA18016DE8C6EE09649AB4CDF8189F6B1AD2E29F0A4C6D2D46CCC5B010101632E3700760502BFBECA6200620072630201710163292C001B1B1B1B1A001942";

# Irgendwas anderes
#$smlfile = "1B1B1B1B010101017605000157BA6200620072630101760101050000728E0B0649534B0104CEE5A9CD010163029B007605000157BB620062007263070177010B0649534B0104CEE5A9CD070100620AFFFF72620165000073DB7A77078181C78203FF010101010449534B0177070100000009FF010101010B0649534B0104CEE5A9CD0177070100010800FF650001010001621E52FF5900000000000176FE0177070100010801FF0101621E52FF590000000000016E4F0177070100010802FF0101621E52FF5900000000000008AF0177070100020800FF650001010001621E52FF5900000000000042940177070100020801FF0101621E52FF5900000000000042940177070100020802FF0101621E52FF5900000000000000000177070100100700FF0101621B520055000000000177078181C78205FF010101018302ECFD72FEFFBD79ADF67E06E95026DFB6C6E4AB0FE76F2F108887F7294CC96C9C093F016127A6A2E6AA665F79442F2CDF01010163AE56007605000157BC6200620072630201710163BD3E001B1B1B1B1A00D258";

#Q3 von voller
$smlfile ="1B1B1B1B01010101760551EEEFCF62006200726500000101760101074553595133420B0645535901071BB1430F010163A9AC00760551EEEFD06200620072650000070177010B0645535901071BB1430F01726201650027E3237977078181C78203FF01010101044553590177070100010800FF0101621E52FC690000000063A6A6480177070100020800FF0101621E52FC6900000000AF8A98FE0177070100010801FF0101621E520165000040C60177070100010802FF0101621E520165000000880177070100020801FF0101621E520165000072870177070100020802FF0101621E520165000000830177070100010700FF0101621B52FE55FFFD57F00177070100600505FF010101016301A00101016360D700760551EEEFD1620062007265000002017101630A8200001B1B1B1B1A01A3FF";


# Inputvalue is $smlfile. This part checks if the SML header and footer are available and complete

if ($smlfile =~ m/1B1B1B1B1A[0-9A-F]{6}$/) {
  if ($smlfile =~ m/^1B1B1B1B01010101/) {
    print "Header - OK\n"; } 
  else {
    if ($smlfile =~ m/^(1B){0,4}01010101/) {
      $smlfile =~ s/^(1B){0,4}01010101/1B1B1B1B01010101/g;
      print "Header - Repaired\n";} 
    else {
      print "Header - No header found!\n";}
  }} 
else {
  print "Footer - No footer found\n";
}
 
my $telegramm;
my $scaler;
my $typelength;
my $unit;
my $direction;

my $length_all = 0;
my $length_value = 0;


# Try to find a SML telegramm in the SML file

while ($smlfile =~ m/7707[0-9A-F]{10}FF[0-9A-F]*/) {
  $telegramm = $&;
  # Try to find the OBIS code in the hash of known and supported OBIS codes
  # OBIS Code with the start (7707) is always 8 bit long (16 nible)
 
  if (defined $obiscodes{substr($telegramm,0,16)}) {
    
    # OBIS code found start parsing
    
    $length_all   = 16;    
    $length_value = 0;
    $direction = undef;


    print substr($telegramm,0,16);


    ###########################################################
    # Statusword
    ###########################################################

    # Detect length of status word (very static at the moment)
    # You can find more information if you google for type length field
    # 01 = Statusword not set
    # 62 is (6 = no more tl fields and type = unsigned?, 2 = 2 bytes or 4 hex chars)
    
    $length_all+=hexstr_to_signed32int(substr($telegramm,17,1))*2+2;

    # Detect the direction of engergy from the status word
  
    $direction = "Bezug"       if (substr($telegramm,$length_all-4,2) eq "82");
    $direction = "Einspeisung" if (substr($telegramm,$length_all-4,2) eq "A2");

    print " " . substr($telegramm,16,4);


    ###########################################################
    # Detect the unit. Also very static and could be improved
    ###########################################################

    if (substr($telegramm,$length_all,4) eq "621E") {
        $unit = "W/h"; }
    else {
        $unit = "W"; }

    # Possible bug! Unit could theoretically be longer than 2 byte!
    $length_all+=4;

    print " " . substr($telegramm,20,4);

    ############################################################
    # Calculate the scaler 
    ############################################################

    $scaler = 10**hexstr_to_signed8int(substr($telegramm,$length_all+2,2));
    # Possible bug! Scaler could theoretically be longer than 2 byte!
    $length_all+=4;

    print " " . substr($telegramm,24,4);

    ############################################################
    # Extract value
    ############################################################

    $length_value=hexstr_to_signed32int(substr($telegramm,$length_all+1,1))*2;
    $length_all+=2;   
    
    print " " . substr($telegramm,28,2);
    print " " . substr($telegramm,30,hex(substr($telegramm,29,1))*2) . "\t";

    # If value is bigger than 9999 W/h change to kW/h 

    if (sprintf("%.2f",hexstr_to_signed32int(substr($telegramm,$length_all,$length_value-2))*$scaler) > 9999) { 
      $scaler = 10**-4; 
      $unit = "kW/h"; }

    # Output of results only if a meaningful value is found. Otherwise nothing happens.

    if (sprintf("%.2f",hexstr_to_signed32int(substr($telegramm,$length_all,$length_value-2))*$scaler) > 0) {
      print "$obiscodes{substr($telegramm,0,16)}";
      print " : " . sprintf("%.2f",hexstr_to_signed32int(substr($telegramm,$length_all,$length_value-2))*$scaler) . " $unit";  
      if (defined $direction) {
        print " --> Direction: $direction\n"; }
      else {
        print "\n"; }}
 
  }
  else {

    # If no known OBIS code can be found the telegramm will be ignored (or logged)
    # print "No Obis Code found!: " . substr($telegramm,0,16) ."\n"; 
    
    # The telegramm  header needs at least to be removed from the smlfile to detect the next one.
    
    $length_all=16; 
  }
 
  # Remove found telegram from remaining sml file.  
  $smlfile = substr($smlfile,index($smlfile,$&)+$length_all+$length_value,length($smlfile));
}

# No good crc16 function found or developed yet. This is a todo
#my $crc = substr($smlfile,length($smlfile)-4,4);
#print "CRC: $crc - \n";

sub hexstr_to_signed32int {
    my ($hexstr) = @_;
    return 0
      if $hexstr !~ /^[0-9A-Fa-f]{1,24}$/;
    my $num = hex($hexstr);


    # TODO!!!!! 30 ist falsch! Müsste 32 sein! Umrechnung von signed int!!!!
    return $num >> 31 ? $num - 2 ** 30 : $num;
}
sub hexstr_to_signed8int {
    my ($hexstr) = @_;
    return 0
      if $hexstr !~ /^[0-9A-Fa-f]{1,8}$/;
    my $num = hex($hexstr);
    return $num >> 7 ? $num - 2 ** 8 : $num;
}
sub hex2bin {
        my $h = shift;
        my $hlen = length($h);
        my $blen = $hlen * 4;
        return unpack("B$blen", pack("H$hlen", $h));
}
