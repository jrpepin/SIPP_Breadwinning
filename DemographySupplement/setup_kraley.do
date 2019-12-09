* This is the location of the original SIPP Core and Topical-Module datafiles
global SIPP2008tm "$projdir/stata_data/SIPP08"
global SIPP2008core "$projdir/stata_data/SIPP08"

* This is the location of the extracts
global SIPP08 "$projdir/kraley/childhh/stata_data/DS/keep"

* This is the base directory with the setup files.
* It is the directory you should change into before executing any files
global childhh_base_code "$projdir/kraley/childhh/DemographySupplement"

* This is the location of the do files.  
global sipp2008_code "$childhh_base_code/SIPP2008"

* This is where logfiles produced by stata will go
global sipp2008_logs "$projdir/kraley/childhh/stata_logs/DS"

* This is where .doc and .xlxs files produced by stata will go
global results "$projdir/kraley/childhh/results/DS"

* This is where temporary data files produced by stata will go
global tempdir "$projdir/kraley/childhh/stata_data/DS/stata_tmp"

* This is where data will put data files that are used in the analysis
global SIPP08keep "$projdir/kraley/childhh/stata_data/DS/keep"

* If you change "replace" to " " the code will generally avoid overwriting any 
* existing data files including those in the temp directory.
global replace "replace"


