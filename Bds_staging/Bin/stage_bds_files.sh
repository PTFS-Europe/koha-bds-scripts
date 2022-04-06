#!/bin/bash
source "$(dirname "$0")/options.sh"
#check folders exist
if [ ! -d ${HOME}/Custom/Bds_staging/Inprocess ]; then
        mkdir -p ${HOME}/Custom/Bds_staging/Inprocess;
fi


perl Bin/stage_bds_files
for x in `cat Inprocess/files_to_stage`
do
  cd Source;
  ${KOHASCRIPTSPATH}stage_file.pl --file $x --match 1 --item-action ignore > ../Logs/$x.log
  batchnumber=`grep '^Batch' ../Logs/${x}.log | sed 's/[^0-9]//g'`
  ${KOHASCRIPTSPATH}commit_file.pl --batch-number $batchnumber >> ../Logs/$x.log
  cp $x ../Archive/
  cd ..
done

# Convert resevoir 10 character isbns to 13-digit forms
perl ${HOME}${BDSDIR}normalize_isbns

