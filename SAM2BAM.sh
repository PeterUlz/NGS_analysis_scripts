#! /bin/bash

#
# Prepare BAM file from SAM Alignment output
# Command line argument 1 is Input SAM file
# Command line argument 2 is Output BAM file

input_sam=$1
output_bam=$2

if ( [ ! -e $1 ] || [ -z "$2" ] ); then
   echo "Usage: ./SAM2BAM.sh <input.sam> <output.bam>"
   exit
fi


### Sort BAM File using picard by coordinate and create Index######################################
java -Xmx4g -Djava.io.tmpdir=/tmp \
     -jar ~/Software/SNP_calling/picard-tools-1.47/SortSam.jar \
     SO=coordinate \
     INPUT=$input_sam \
     OUTPUT=${output_bam} \
     VALIDATION_STRINGENCY=LENIENT \
     CREATE_INDEX=true

if [ $? -ne 0 ]; then
  echo "Picard SortSam crashed. Will exit."
  exit
fi



