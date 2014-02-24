#! /usr/bin/python

#intersect of vcf1 and vcf2 file

import sys

#try getting file names from comand line
try:
  VCF1_file = sys.argv[1]
  VCF2_file = sys.argv[2]
  output_file=sys.argv[3]
except: 
  print ("Usage: ./vcf_intersect.py <VCF1 file> <VCF2 file> <output_file>")
  sys.exit()

#try opening files
try:
  VCF1 = open(VCF1_file)
except:
  print ("Couldn't open VCF1 file")
  sys.exit()


try:
  output = open(output_file, "w")
except:
  print ("Couldn't open output file")
  sys.exit()

#reading the first lines of the three files
vcf1_line = VCF1.readline()

count=0

#iterate till no comment
startvcf1=vcf1_line[0:1]
while startvcf1=='#':
  vcf1_line=VCF1.readline()
  startvcf1=vcf1_line[0:1]


while vcf1_line:
  vcf1_info=vcf1_line.split()

  try:
    VCF2 = open(VCF2_file)
  except:
    print ("Couldn't open VCF2 file")
    sys.exit()

  vcf2_line = VCF2.readline()

  startvcf2=vcf2_line[0:1]
  while startvcf2=='#':
    vcf2_line=VCF2.readline()
    startvcf2=vcf2_line[0:1]


  while vcf2_line:
    vcf2_info=vcf2_line.split()
    if ((vcf1_info[0] == vcf2_info[0]) and (vcf1_info[1] == vcf2_info[1]) and (vcf1_info[3] == vcf2_info[3]) and (vcf1_info[4] == vcf2_info[4])):
      output.write(vcf1_line)
      count+=1
      break
    vcf2_line=VCF2.readline()

  vcf1_line=VCF1.readline()

  if (count % 100 == 0):
    print count, "SNPs intersected"
  VCF2.close()

VCF1.close()
VCF2.close()
output.close()

