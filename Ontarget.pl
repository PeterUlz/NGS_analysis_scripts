#! /usr/bin/perl

#
# Checks SAM files for on and offtarget read ratio
# First argument is SAM File, second is BED fileof target regions
# read is considered on target when either it's start or end overlap with a target region
# 

#Usage ./Ontarget <SAM File> <Target BED File>

$file = $ARGV[0];
$targetfile = $ARGV[1];
$ontarget = 0;
$offtarget = 0;

@target_array;

open (INPUT, "<$file") || die "File not found";
open TARGET, "<$targetfile" || die "Can't open $targetfile";

print "Read Targets\n";
#Target regions are stored in an array as chrom<TAB>start<TAB>end
while ($targets = <TARGET>)
{
  #split each read of targetfile
  @targetinfo = split /\t/, $targets;

  $chrom = $targetinfo[0];
  $start = $targetinfo[1];
  $stop  = $targetinfo[2];

  push (@target_array, "$chrom\t$start\t$stop");
  
}

$count = 0;
print "Iterate through SAM file\n";
#iterate through SAM file
while ($line = <INPUT>)
{
  #omit header lines
  if ($line =~ /^@/) { next;}
  
  #count reads
  $count++;
  @info = split "\t", $line;
   
  $found = "false";
  
  #unaligned reads are for sure offtarget iteration through target array is not necessary
  if ($info[2] eq "*")
  {
    $unaligned++;
    $offtarget++;
    next;
  }


  $readstart = $info[3];
  $readend = $info[3] + length ($info[9]);

  foreach $target (@target_array)
  {
    @targetinfo = split /\t/, $target;

    $chrom = $targetinfo[0];
    $start = $targetinfo[1];
    $stop  = $targetinfo[2];

    if (($info[2] eq $chrom) && ((($readstart > $start) && ($readstart < $stop)) || (($readend > $start) && ($readend < $stop))))
    {
      $ontarget++;
      $found = "true";
      last;
    }
  }
  if ($found eq "false") { $offtarget++;} 

  if ($count%100000 == 0){
    print "   $count reads processed\n";}

}
 
close INPUT;
close TARGET;

$reads= $ontarget + $offtarget;
$percentage = ($ontarget / $reads) * 100;
print ("Reads: $reads On target: $ontarget On target (%): $percentage Unmapped:$unaligned\n");
