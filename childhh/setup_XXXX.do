* This is the location of the SIPP extracts
global SIPP2008 "$homedir/childhh/data/SIPP2008"

* This is the base directory with the setup files.
* It is the directory you should change into before executing any files
global childhh_base_code "$homedir/childhh/"

* This is the location of the do files.  
global sipp2008_code "$childhh_base_code/SIPP2008"

* This is where logfiles produced by stata will go
global sipp2008_logs "$homedir/childhh/stata_logs"

* This is where .doc and .xlxs files produced by stata will go
global results "$homedir/childhh/results"

* This is where temporary data files produced by stata will go
global tempdir "$homedir/childhh/stata_data/stata_tmp"

* This is where data will put data files that are used in the analysis
global SIPP08keep "$homedir/childhh/stata_data/SIPP08_Processed"

* If you change "replace" to " " the code will generally avoid overwriting any 
* existing data files including those in the temp directory.
global replace "replace"


