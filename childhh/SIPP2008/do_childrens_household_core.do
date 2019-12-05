//==============================================================================//
//===== Children's Household Instability Project
//===== Dataset: SIPP2008
//===== Purpose: Executes do files to create core datafiles:
//===== 

//=========================================================================//
//== Purpose: Preparation for running the program.
//== 
//== Note: This program requires the mdesc and confirmdir packages. If you do not have this, type ssc install mdesc/confirmdir before running.
//=========================================================================//

***************************************************************************
** Section: The following code attempts to make sure these packages are installed before allowing execution.
***************************************************************************
capture findfile mdesc.ado
if ("`r(fn)'" == "") {
    display as error "It appears the mdesc package is not installed."
    display as error "Try 'ssc install mdesc' to acquire it."
    exit
}

capture findfile confirmdir.ado
if ("`r(fn)'" == "") {
    display as error "It appears the confirmdir package is not installed."
    display as error "Try 'ssc install confirmdir' to acquire it."
    exit
}

***************************************************************************
** Section: Creates macros for wave, age, month, relationships
***************************************************************************
do "$childhh_base_code/SIPP2008/project_macros" /* this do-file contains macros of wave, age, month, relationships */

***************************************************************************
** Section: Check to make sure the required directories exist.
***************************************************************************

if ("$sipp2008_code" == "") {
    display as error "sipp2008_code macro not set."
    display as error "This macro tells us where to find the project code."
    exit
}

if ("$sipp2008_logs" == "") {
    display as error "sipp2008_logs macro not set."
    display as error "This macro tells us where to put the log files."
    exit
}

confirmdir "$sipp2008_logs"
if `r(confirmdir)' {
    display as error "The sipp2008_logs macro specifies a directory that does not exist:  $sipp2008_logs"
    exit
}

confirmdir "$sipp2008_code"
if `r(confirmdir)' {
    display as error "The sipp2008_code macro specifies a directory that does not exist:  $sipp2008_code"
    exit
}

********************************************************************************
* Execute scripts to process data.
********************************************************************************
** Combines all the waves into a long file where every person-wave is a record. 
do "$childhh_base_code/do_and_log" "$sipp2008_code" "$sipp2008_logs" merge_waves  

** Makes sub-datasets for analyses.
** Includes file for maternal and parental characteristics like education and immigration status
do "$childhh_base_code/do_and_log" "$sipp2008_code" "$sipp2008_logs" make_auxiliary_datasets 

** Generates a wide dataset by person (includes static demographic variables). 
do "$childhh_base_code/do_and_log" "$sipp2008_code" "$sipp2008_logs" convert_to_wide 

** Makes sure ages are consistent in all the waves. Caveat: cleaning incomplete.
* Also produces demo_wide and demo_long data files
do "$childhh_base_code/do_and_log" "$sipp2008_code" "$sipp2008_logs" normalize_ages 

** Computes biderectional base relationships (mom, dad, child, spouse) 
do "$childhh_base_code/do_and_log" "$sipp2008_code" "$sipp2008_logs" compute_base_relationships 

** Identifies additional relationships transitively
do "$childhh_base_code/do_and_log" "$sipp2008_code" "$sipp2008_logs" compute_secondary_relationships 

** Identifies one consistent relationship between every pair of coresident individuals
** We no longer use unfied relationships favoring instead measures based on relationships 
** reported in a wave
*do "$childhh_base_code/do_and_log" "$sipp2008_code" "$sipp2008_logs" unify_relationships_across_waves 

** Creates a variable to measure change in household composition.
** Also creates lists of people who arrive/leave or stay in ego's household
do "$childhh_base_code/do_and_log" "$sipp2008_code" "$sipp2008_logs" create_comp_change 

** Creates addr_change and hh_change. Converts data file to long. Core file: hh_change.dta
do "$childhh_base_code/do_and_log" "$sipp2008_code" "$sipp2008_logs" create_hh_change 

** Links ego's household arrivers and stayers (in comp_change) 
** to relationships data created by compute_secondary_relationships. 
do "$childhh_base_code/do_and_log" "$sipp2008_code" "$sipp2008_logs" create_changer_rels 

** Merges relationship of changers to ego back to comp_change
do "$childhh_base_code/do_and_log" "$sipp2008_code" "$sipp2008_logs" create_HHchangeWithRelationships 

** Creates a pairwise data file with one record per coresident individuals in each wave.
** Useful for identifying household composition of children, but to produce results that describe
** households of children, need to collapse by SSUID SHHADID and SWAVE and then select if adj_age < 18
do "$childhh_base_code/do_and_log" "$sipp2008_code" "$sipp2008_logs" create_HHComp_asis

