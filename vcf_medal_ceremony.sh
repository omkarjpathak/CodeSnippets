#!/bin/bash
# Runs medal ceremony on a vcf (originally designed for ClearSeq vcfs)
#
# Note: several other files will be written named <input file>.suffix, in then
# current working directory
#
# Parameters:
# $1 = input file in current working directory
# $2 = output file

# Show usage information if no parameters were sent
if [ "$#" == 0 ]; then about.sh $0; exit 1; fi

# Get parameters
INPUT=$1
OUTPUT=$2

OUT_DIR=`dirname $OUTPUT`
mkdir -p $OUT_DIR
if [ ! -d "$OUT_DIR" ]
then echo "Output directory could not be created: $OUT_DIR" >&2; exit 1
fi

set -e
set -x

filter_vcf.pl $INPUT 20 > $INPUT.filter.vcf
vcf2tab.pl -file $INPUT.filter.vcf -annovar 2> $INPUT.vcf2tab.log
bambino2annovar.pl -sjpi -genome GRCh37-lite -file $INPUT.filter.vcf.cooked.tab -scratch
annovar2medals.pl -genome GRCh37-lite -file  $INPUT.filter.vcf.cooked.tab.annovar_merged.tab
double_medal.pl -file $INPUT.filter.vcf.cooked.tab.annovar_merged.tab.mp.tab
cp $INPUT.filter.vcf.cooked.tab.annovar_merged.tab.mp.tab.medals.tab.medals.tab $OUTPUT
