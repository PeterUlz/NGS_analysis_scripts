#! /bin/bash

#
#
# SNP calling using the Unified Genotyper from GATK
#
#

##INPUT for SNP_calling algorithms ########################
hg19=~/RefSeq/hg19_070510/hg19.fa
input_bam=$1
metrics=${input_bam}.SNP.metrics
indel_metrics=${input_bam}.Indel.metrics
dbsnp=~/RefSeq/GATK_ressource_bundle/dbsnp_132.hg19.vcf
interval=~/RefSeq/GATK_Exome_Interval_list/hg19_exons_plus10bp.sorted.bed
snp_results=$2


### SNP calling ############################################
java -Xmx4g -jar ~/Software/SNP_calling/GenomeAnalysisTK-1.6-13-g91f02df/GenomeAnalysisTK.jar \
     -glm BOTH \
     -nt 30 \
     -R $hg19 \
     -T UnifiedGenotyper \
     -I $input_bam \
     -D $dbsnp \
     -o $snp_results \
     -metrics $metrics \
     -stand_call_conf 50.0 \
     -stand_emit_conf 10.0 \
     -dcov 1000 \
     -A DepthOfCoverage \
     -A AlleleBalance \
     -L $interval


