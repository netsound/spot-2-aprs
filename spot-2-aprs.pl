#!/usr/bin/perl

$spot_key = "!!KEY!!"; # SPOT API KEY For device... Must create public share page first and have data posted.
$pass = "!!PASS!!"; # APRS passcode for igate callsign (passcode CALLSIGN on *nix systems)
$aprs_server = "198.105.228.71"; # APRS-IS server to connect to
$aprs_port = "14580"; # Port of APRS-IS server normally 14580
$callsign = "!!CALLSIGN!!"; # Callsign for cellular tracker
$software = "SPOTG3"; # What type of device this is
$symbol = "/["; # APRS symbol
$comment = "SpotSat Tracker"; # APRS comment, so people know what this is

use JSON; # We will use this to decode the result
use LWP::Simple; # We will use this to get the encoded data over HTTPS
use Data::Dumper; # We will use this to display the result
use Ham::APRS::FAP; #We sill use this to generator the APRS Packet
use IO::Socket; #We will use this to connect to APRS-IS Server

# Download the json data
my $encoded_json = get("https://api.findmespot.com/spot-main-web/consumer/rest-api/2.0/public/feed/$spot_key/latest.json");
# Decode the json data
my $decoded = decode_json($encoded_json);

my $longitude = $decoded->{response}->{feedMessageResponse}->{messages}->{message}->{longitude};
my $latitude = $decoded->{response}->{feedMessageResponse}->{messages}->{message}->{latitude};
my $time = $decoded->{response}->{feedMessageResponse}->{messages}->{message}->{unixTime};
my $batterystate = $decoded->{response}->{feedMessageResponse}->{messages}->{message}->{batteryState};
my $friendly_name = $decoded->{response}->{feedMessageResponse}->{messages}->{message}->{messengerName};

$position = Ham::APRS::FAP::make_position($latitude,$longitude,0,0,0,$symbol,0,0);

print "*** W8FSM SPOT Tracker to APRS-IS ***\n";
print "Device SPOT Name: ";
print "$friendly_name\n";
print "Device APRS Callsign: ";
print "$callsign\n";
print "Device Lat: ";
print "$latitude\n";
print "Device Lon: ";
print "$longitude\n";
print "Device Battery: ";
print "$batterystate";
print "\n";

$packet = "$callsign>$software,TCPIP*:=$position Battery-$batterystate $comment";

print "Device APRS Packet Generated for TX: ";
print "$packet\n";

if ($packet ne $last_packet) {

  $sock = new IO::Socket::INET ( # One time connection to server for each packet
    PeerAddr => "$aprs_server",
    PeerPort => "$aprs_port",
    Proto => "tcp",
  );
  die "Could not connect to server\n" unless $sock;
  print $sock "user $callsign pass $pass\n";
  print $sock "$packet\n";
  close($sock);

  $last_packet = $packet; # So we don't send duplicate packets
}

die "Device Update Sent to APRS-IS via $aprs_server:$aprs_port\n";
