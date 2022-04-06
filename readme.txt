**********
README
*********
BDS scripts - PTFS Europe - 20210706 
version 2 - 20220331
NB Default home is /home/koha unless changed in options.sh and options.cfg file 

Place "Bds" and "Bds_staging" folders in /Custom folder (under $home as defined in options file - normally /home/koha)


Ensure you set values in the two options files under /Custom/Bds before running. These are options.sh (Shell) and options.cfg (perl)

So that shared config files can be used, create a softlink from the options.sh and options.cfg files to the Bds_staging/Bin folder viz

ln -s /<Bds path>/options.sh /<Bds_staging/Bin path>/options.sh
ln -s /<Bds path>/options.cfg /<Bds_staging/Bin path>/options.cfg

Add to cron to schedule:

# retrieve BDS records for bibs created from edi quotes
mm  hh * * * /home/koha/Custom/Bds/submit_keys
mm  hh * * * /home/koha/Custom/Bds/import_records

NB/ The BDS scripts run everu hour at half-past, so the first
line must be before that and the second some while after

# Retrieve BDS bib data and stage it
mm hh * * * cd /home/koha/Custom/Bds_staging; /home/koha/Custom/Bds_staging/Bin/stage_bds_files.sh

Changes in v2
1. download_isn and download_ean directories become arrays pipe | separated
2. filename masks altered to allow for alphabetic suffixes. eg xxx20220101.mrc, xxx20220101a.mrc etc.
3. passive mode default added for ftp
4. MATCHRULE=<number> added to options.sh to state Koha matching rule to use when staging marc records.
5. Facility to load after staging in Koha added.
