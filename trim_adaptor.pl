#! /usr/bin/perl

$input = $ARGV[0];
$output= $ARGV[1];

open (INPUT, "<$input") || die "Can't open input file\n";
open (OUTPUT, ">$output") || die "Can't open output file\n";

$one = 0;
$two = 0;
$three = 0;
$four = 0;
$five = 0;
$six = 0;
$seven = 0;

while ($line1 = <INPUT>)
{
  if ($line1 !~ /^@/) 
  {
    print "Out-of sync-error";
    sys.exit();
  }
  $line2=<INPUT>;
  $line3=<INPUT>;
  $line4=<INPUT>;

  $read_length = length($line2);
  if ($line2 =~ m/AGATCGG\n$/)
  {
    $seven++;
    $output_line2 = substr($line2, 0, $read_length-8);
    $output_line4 = substr($line4, 0, $read_length-8);
  }
  elsif ($line2 =~ m/AGATCG\n$/)
  {
    $six++;
    $output_line2 = substr($line2, 0, $read_length-7);
    $output_line4 = substr($line4, 0, $read_length-7);
  }
  elsif ($line2 =~ m/AGATC\n$/)
  {
    $five++;
    $output_line2 = substr($line2, 0, $read_length-6);
    $output_line4 = substr($line4, 0, $read_length-6);
  }
  elsif ($line2 =~ m/AGAT\n$/)
  {
    $four++;
    $output_line2 = substr($line2, 0, $read_length-5);
    $output_line4 = substr($line4, 0, $read_length-5);
  }
  elsif ($line2 =~ m/AGA\n$/)
  {
    $three++;
    $output_line2 = substr($line2, 0, $read_length-4);
    $output_line4 = substr($line4, 0, $read_length-4);
  }
  elsif ($line2 =~ m/AG\n$/)
  {
    $two++;
    $output_line2 = substr($line2, 0, $read_length-3);
    $output_line4 = substr($line4, 0, $read_length-3);
  }
  elsif ($line2 =~ m/A\n$/)
  {
    $one++;
    $output_line2 = substr($line2, 0, $read_length-2);
    $output_line4 = substr($line4, 0, $read_length-2);
  }
  else
  {
    print OUTPUT $line1;
    print OUTPUT $line2;
    print OUTPUT $line3;
    print OUTPUT $line4;
    next;
  }
  print OUTPUT $line1;
  print OUTPUT "$output_line2\n";
  print OUTPUT $line3;
  print OUTPUT "$output_line4\n";
}

print "\nResidual adaptor sequences removed:\n";
print "   1 Base : $one\n";
print "   2 Bases: $two\n";
print "   3 Bases: $three\n";
print "   4 Bases: $four\n";
print "   5 Bases: $five\n";
print "   6 Bases: $six\n";
print "   7 Bases: $seven\n\n";

close INPUT;
close OUTPUT;
