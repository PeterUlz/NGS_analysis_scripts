#! /bin/bash

###################################################################################################
# Realign.sh                                                                                      #
# prepares BAM files for SNP calling in three steps                                               #
# 1) MarkDuplicates (Picard) marks reads as PCR duplicates when aligning to exact same position   #
# 2) Realign (multiple alignment) the reads around suspicious loci to improve SNP calling         #
# 3) Recalibrate quality scores to get them close to empirical quality values                     #
#                                                                                                 #
# Version 0.3 07.10.2011                                                                          #
###################################################################################################

#reference file (chr1, chr2, chr3,...,chr22, chrX, chrY, chrM)
hg19=/home/peter/RefSeq/hg19_070510/hg19.fa

#input bam file
input_bam=$1

#metrics file to be saved by MarkDuplicates
metrics=${input_bam}.metrics

#position of snp file ordered in same way as reference file
dbsnp=/home/peter/RefSeq/GATK_ressource_bundle/dbsnp_132.hg19.vcf

#position of 1000g dindel file ordered in same way as reference file
indel=/home/peter/RefSeq/1000genomes/EUR.dindel.20100804.sites.vcf

##from GATK Homepage:
#Sample-level realignment with known indels and recalibration
#Rather than doing the lane level cleaning and recalibration, this process aggregates all of the reads for each sample and then does a full dedupping, realign, and recalibration, yielding the best single-sample results. 
#The big change here is sample-level cleaning followed by recalibration, giving you the most accurate quality scores possible for a single sample. 
#
#

start_time=`date +%T`
echo " "
echo "----------------------------"
echo "Starting MarkDuplicates at `date +%T`"
echo "----------------------------"
echo " "


### Mark Duplicates using Picard###################################################################
java -Xmx10g -Djava.io.tmpdir=/tmp \
     -jar ~/Software/SNP_calling/picard-tools-1.89/MarkDuplicates.jar \
     INPUT=${input_bam} \
     OUTPUT=${input_bam}.marked.bam \
     METRICS_FILE=$metrics \
     VALIDATION_STRINGENCY=LENIENT \
     CREATE_INDEX=true

if [ $? -ne 0 ]; then
   echo "Mark duplicates crashed. Will exit"
   exit
fi

realign_time=`date +%T`
echo " "
echo "----------------------------"
echo "Starting with Realigning at $realign_time"
echo "----------------------------"
echo " "

### Realigning using GATK##########################################################################
# Step 1 determining small suspicious intervals likely in need to be realigned
java -Xmx10g -jar ~/Software/SNP_calling/GenomeAnalysisTK-2.4-9-g532efad/GenomeAnalysisTK.jar \
     -rf BadCigar \
     -T RealignerTargetCreator  \
     -nt 8 \
     -R $hg19 \
     --known /home/peter/RefSeq/GATK_ressource_bundle/1000G_biallelic.indels.hg19.vcf \
     -o ${input_bam}.list \
     -I ${input_bam}.marked.bam 

if [ $? -ne 0 ]; then
   echo "Realigning crashed in step 1. Will exit"
   exit
fi

# Step 2 Running the realigner over the intervals
java -Xmx10g -Djava.io.tmpdir=/tmp -jar ~/Software/SNP_calling/GenomeAnalysisTK-2.4-9-g532efad/GenomeAnalysisTK.jar \
     -rf BadCigar \
     -I ${input_bam} \
     -R $hg19 \
     -T IndelRealigner \
     -targetIntervals ${input_bam}.list \
     -o ${input_bam}.marked.realigned.bam

if [ $? -ne 0 ]; then
   echo "Realigning crashed in step 2. Will exit"
   exit
fi

# Step 3 fix mate information using Picard when using paired end approaches
java -Xmx10g -Djava.io.tmpdir=/tmp/ \
  -jar ~/Software/SNP_calling/picard-tools-1.89/FixMateInformation.jar \
  INPUT=${input_bam}.marked.realigned.bam \
  OUTPUT=${input_bam}.marked.realigned.fixed.bam \
  SO=coordinate \
  VALIDATION_STRINGENCY=LENIENT \
  CREATE_INDEX=true

if [ $? -ne 0 ]; then
   echo "Realignment crashed in step 3. Will exit"
   exit
fi


recal_time=`date +%T`
echo " "
echo "----------------------------"
echo "Starting with Recalibration at $recal_time"
echo "----------------------------"
echo " "

### Base quality score recalibration ##############################################################
# Count Covariates
java -Xmx10g -jar ~/Software/SNP_calling/GenomeAnalysisTK-2.4-9-g532efad/GenomeAnalysisTK.jar \
     -l INFO \
     -R $hg19 \
     -nct 8 \
     -knownSites $dbsnp \
     -I ${input_bam}.marked.realigned.fixed.bam \
     -T BaseRecalibrator\
     -o ${input_bam}.recal_data.csv

if [ $? -ne 0 ]; then
   echo "Recalibration crashed in count covariates. Will exit"
   exit
fi

# Table Recalibration
java -Xmx10g -jar ~/Software/SNP_calling/GenomeAnalysisTK-2.4-9-g532efad/GenomeAnalysisTK.jar \
  -l INFO \
  -R $hg19 \
  -nct 8 \
  -I ${input_bam}.marked.realigned.fixed.bam \
  -T PrintReads \
  -o ${input_bam}.marked.realigned.fixed.recal.bam \
  -BQSR ${input_bam}.recal_data.csv

if [ $? -ne 0 ]; then
   echo "Recalibration crashed in Table recalibration. Will exit"
   exit
fi

mv ${input_bam}.marked.realigned.fixed.recal.bam ${input_bam}.finished.bam

#index marked realigned recalibrated BAM file for SNP calling
samtools index ${input_bam}.finished.bam

rm ${input_bam}.marked.*
rm $input_bam
rm ${input_bam}.bai

end_time=`date +%T`
echo ""
echo "------------------------------------------"
echo "Ended at $end_time"
echo "MarkDuplicates at $start_time"
echo "Realigning at $realign_time"
echo "Recalibration at $recal_time"
echo "File saved under ${input_bam}.finished.bam"
echo "------------------------------------------"
echo ""

