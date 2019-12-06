* This is the location of the SIPP extracts
global SIPP2008 "$homedir/Dropbox/Data/SIPP/SIPP2008"

* This is the base directory with the setup files.
* It is the directory you should change into before executing any files
global childhh_base_code "$homedir/Dropbox/Repositories/SIPP_Breadwinning/childhh/"

* This is the location of the do files.  
global sipp2008_code "$childhh_base_code/SIPP2008"

* This is where logfiles produced by stata will go
global sipp2008_logs "$childhh_base_code/stata_logs"

* This is where .doc and .xlxs files produced by stata will go
global results "$childhh_base_code/results"

* This is where temporary data files produced by stata will go
global tempdir "$childhh_base_code/stata_data/stata_tmp"

* This is where data will put data files that are used in the analysis
global SIPP08keep "$childhh_base_code/stata_data/SIPP08_Processed"

* If you change "replace" to " " the code will generally avoid overwriting any 
* existing data files including those in the temp directory.
global replace "replace"
