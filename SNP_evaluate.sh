#! /bin/bash

#
# Evaluate SNPs by computing Ti/Tv ratios
#

#Set variables
input_snp_vcf=$1
eval_results=$2
hg19=/home/flx-auswerter/RefSeq/hg19_070510/Chromosomes/hg19.fa
dbsnp=/home/flx-auswerter/RefSeq/dbSNP132_200611_hg19/snp132.txt


#Evaluate variants using GATK VariantEvaluator
java -Xmx4g -jar ~/Software/SNP_calling/GenomeAnalysisTK-1.2-35/GenomeAnalysisTK.jar \
     -R $hg19 \
     -T VariantEval \
     -D $dbsnp \
     -B:eval,VCF $input_snp_vcf \
     -o $eval_results




