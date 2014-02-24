#! /bin/bash

#
# Control script for subsequent Alignment, SAM2BAM conversion, Realignment and SNP calling
# from a FASTQ file
#
#
# Version 0.92 29.12.2011
#
# Usage: ./Pipeline.sh <projectname> <input.fq> (<input2.fq>) 
version="0.93 21.05.2012"

#-------------------------------------------------------------------------------
### check commandline
#-------------------------------------------------------------------------------
if ( [ -z "$1" ] || [ -z "$2" ] ); then
  echo "Pipeline"
  echo "--------"
  echo "Usage: ./Pipeline.sh <projectname> <input.fq> (<input2.fq>)"
  echo ""
  exit
fi

projectname=$1
input_fq=$2
current_dir=$PWD

#check if first argument is a filename in the directory by mistake
if [ -f projectname ]; then
  echo "Pipeline"
  echo "--------"
  echo "Attention: First argument should be project name: you specified an existing file!"
  echo "Usage: ./Pipeline.sh <projectname> <input.fq> (<input2.fq>)"
  echo ""
  exit
fi

#check if first file name can be opened
if [ ! -f $input_fq ]; then
  echo "Pipeline"
  echo "--------"
  echo "Inputfile not found"
  echo ""
  exit
fi

#check if two file names are specified for paired end run
if [ ! -z "$3" ]; then
  input2_fq=$3
  if [ ! -f $input_fq ]; then
    echo "Pipeline"
    echo "--------"
    echo "Second Inputfile not found"
    echo ""
    exit
  fi
  paired="true"
fi

#-------------------------------------------------------------------------------
### Create data hierarchy
#-------------------------------------------------------------------------------
mkdir $current_dir/$projectname
alignment_dir=$current_dir/$projectname/Alignment
mkdir $alignment_dir
snp_dir=$current_dir/$projectname/SNP
mkdir $snp_dir
coverage_dir=$current_dir/$projectname/Coverage
mkdir $coverage_dir
snp_val_dir=$snp_dir/SNP_validation
snp_eval_dir=$snp_dir/SNP_evaluation
snp_filter_dir=$snp_dir/SNP_filtering
mkdir $snp_val_dir
mkdir $snp_eval_dir
mkdir $snp_filter_dir
pipeline_file=$current_dir/$projectname/${projectname}.log
error_log=$current_dir/$projectname/error.log
coverage_log=$coverage_dir/cov.log

#------------------------------------------------------------------------------- 
### Step 1 call appropriate Alignment Script
#-------------------------------------------------------------------------------
echo "              Pipeline V.$version" | tee $pipeline_file
echo "        ------------------------" | tee -a $pipeline_file
echo ""
echo "Pipeline for processing Illumina Sequencing data"
echo ""
echo "---------------------------------------------"
echo "| Step 1 Alignment starting at `date`" | tee -a $pipeline_file
echo "---------------------------------------------"
echo ""
if [ ! -z "$3" ]; then
  echo "  Paired end sequencing"
  echo ""
  #  STD::ERR is outputted to error.log but bwa outputs normal output on std::err as well !!!
  ~/Pipeline/Align_PE.sh $input_fq $input2_fq ${alignment_dir}/$projectname.sam ILLUMINA $projectname 2> $error_log
  if [ $? -ne 0 ];then
    echo "Step 1 Alignment crashed at `date`" | tee -a $pipeline_file
    exit
  fi
else 
  echo "  Single end sequencing"
  echo ""
  ~/Pipeline/Align_SE.sh $input_fq ${alignment_dir}/$projectname.sam ILLUMINA 2> $error_log
  if [ $? -ne 0 ];then
    echo "Step 1 Alignment crashed at `date`" | tee -a $pipeline_file
    exit
  fi
fi


#------------------------------------------------------------------------------- 
### Step 2 Convert SAM2BAM
#-------------------------------------------------------------------------------
echo "---------------------------------------------------------"
echo "| Step 2 SAM filtering and SAM2BAM Conversion starting at `date`" | tee -a $pipeline_file
echo "---------------------------------------------------------"
echo ""
~/Pipeline/filterSAM.sh ${alignment_dir}/${projectname}.sam ${alignment_dir}/${projectname}.filtered.sam
~/Pipeline/SAM2BAM.sh ${alignment_dir}/${projectname}.filtered.sam ${alignment_dir}/${projectname}.bam 2>> $error_log
if [ $? -ne 0 ];then
  echo "Step 2 SAM2BAM Conversion crashed at `date`" | tee -a $pipeline_file
  exit
fi

rm ${alignment_dir}/${projectname}.sam

#------------------------------------------------------------------------------- 
### Step 3 Postprocessing BAM
#-------------------------------------------------------------------------------
echo "---------------------------------------------------------"
echo "| Step 3 BAM Postprocessing starting at `date`" | tee -a $pipeline_file
echo "---------------------------------------------------------"
echo ""
~/Pipeline/Realign.sh ${alignment_dir}/$projectname.bam 2>> $error_log
if [ $? -ne 0 ];then
  echo "Step 3 BAM Postprocessing crashed at `date`" | tee -a $pipeline_file
  exit
fi

#------------------------------------------------------------------------------- 
### Step 4 Get target bases with low coverage
#-------------------------------------------------------------------------------
#echo "---------------------------------------------------------"
#echo "| Step 4 Run coverage analysis in background `date`" | tee -a $pipeline_file
#echo "---------------------------------------------------------"
#echo ""
#cd /home/flx-auswerter/Software/NGSrich_0.7.3/bin
#java NGSrich evaluate -r ${alignment_dir}/$projectname.bam.finished.bam -u hg19 -t /media/c810fef8-3cb0-4662-bfe6-f5c8f035338f/Exome/Illumina/TruSeq_files/TruSeq_exome_targeted_regions.hg19.bed.chr -o $coverage_dir &
#if [ $? -ne 0 ];then
#  echo "Step 4 Coverage analysis crashed at `date`" | tee -a $pipeline_file
#  exit
#fi

#------------------------------------------------------------------------------- 
### Step 5 SNP calling
#-------------------------------------------------------------------------------
#echo "---------------------------------------------------------"
#echo "| Step 5 SNP calling starting at `date`" | tee -a $pipeline_file
#echo "---------------------------------------------------------"
#echo ""
#~/Pipeline/SNP_calling.sh ${alignment_dir}/$projectname.bam.finished.bam ${snp_dir}/$projectname.snp.vcf 2>> $error_log
#if [ $? -ne 0 ];then
#  echo "Step 5 SNP calling crashed at `date`" | tee -a $pipeline_file
#  exit
#fi

#------------------------------------------------------------------------------- 
### Step 6 SNP validation
#-------------------------------------------------------------------------------
#echo "---------------------------------------------------------"
#echo "| Step 6 SNP validation starting at `date`" | tee -a $pipeline_file
#echo "---------------------------------------------------------"
#echo ""
#~/Pipeline/SNP_validation.sh  ${snp_dir}/$projectname.snp.vcf  2>> $error_log
#if [ $? -ne 0 ];then
#  echo "Step 6 SNP validation crashed at `date`" | tee -a $pipeline_file
#  exit
#fi

#------------------------------------------------------------------------------- 
### Step 7 SNP annotation
#-------------------------------------------------------------------------------
#echo "---------------------------------------------------------"
#echo "| Step 7 SNP annotation starting at `date`" | tee -a $pipeline_file
#echo "---------------------------------------------------------"
#echo ""
#~/Pipeline/annotation.sh  ${snp_dir}/$projectname.snp.vcf.filtered ${snp_val_dir}/$projectname 2>> $error_log
#if [ $? -ne 0 ];then
#  echo "Step 7 SNP annotation crashed at `date`" | tee -a $pipeline_file
#  exit
#fi




#------------------------------------------------------------------------------- 
### Step 8 SNP filtering
#-------------------------------------------------------------------------------
#echo "---------------------------------------------------------"
#echo "| Step 8 SNP filtering starting at `date`" | tee -a $pipeline_file
#echo "---------------------------------------------------------"
#echo ""
##
#~/Pipeline/SNP_filtering.pl ${snp_dir}/$projectname.snp.vcf $snp_filter_dir/$projectname 2>> $error_log
#if [ $? -ne 0 ];then
#  echo "Step 8 SNP filtering crashed at `date`" | tee -a $pipeline_file
#  exit
#fi

#------------------------------------------------------------------------------- 
### Step 9 SNP evaluation
#-------------------------------------------------------------------------------
#echo "---------------------------------------------------------"
#echo "| Step 9 SNP evaluation starting at `date`" | tee -a $pipeline_file
#echo "---------------------------------------------------------"
#echo ""
#~/Pipeline/SNP_evaluate.sh  ${snp_dir}/$projectname.snp.vcf ${snp_eval_dir}/$projectname.snp_evaluation 2>> $error_log
#if [ $? -ne 0 ];then
#  echo "Step 9 SNP evaluation crashed at `date`" | tee -a $pipeline_file
#  exit
#fi


#------------------------------------------------------------------------------- 
### Step 10 Copy .csv files to Apache html folder
#-------------------------------------------------------------------------------
#cp $current_dir/$projectname/${projectname}.csv /var/www/html/output/
#------------------------------------------------------------------------------- 
### Step 10 Enter SNPs in Database
#-------------------------------------------------------------------------------
#echo "---------------------------------------------------------"
#echo "| Step 10 put SNPs in database starting at `date`" | tee -a $pipeline_file
#echo "---------------------------------------------------------"
#echo ""
#~/Pipeline/add_SNPs_to_Database.pl  ${snp_dir}/$projectname.snp.vcf.filtered
#if [ $? -ne 0 ];then
#  echo "Step 10 put SNPs in database crashed at `date`" | tee -a $pipeline_file
#  exit
#fi

#------------------------------------------------------------------------------- 
### Step 11 results
#-------------------------------------------------------------------------------
#echo "----------------------------------------------------------------------------"
#echo "| Pipeline finished at `date`" | tee -a $pipeline_file
#echo "| Annotated SNP files have been written to $current_dir/$projectname/${projectname}.csv" | tee -a $pipeline_file
#echo "| SNP evaluation can be found at ${snp_eval_dir}/$projectname.snp_evaluation" | tee -a $pipeline_file
#echo "----------------------------------------------------------------------------"
#echo ""
#
