********************************************************************************
//===== Children's Household Instability Project
//===== Dataset: SIPP2008
********************************************************************************

This README file has instructions on how to run the accompanying code to: 
Part 1. Setup to be able to run the code
Part 2. Download and prepare original data
Part 3. Produce variables for analysis
Part 4. Create tables and supplementary analyses 

Part 1. Setup to be able to run the code

	To run the ChildHH data creation files, you need to have both mdesc and confirmdir packages installed. 
	If you do not, type ssc install mdesc/confirmdir before attempting to run this code.

	Edit setup_XXXX.do The personalized setup do file defines several macros required by the project code.
	The values of the macros are personalized, but the names of the macros must be the same for all users.
	See an example setup file, e.g. setup_XXXX.do, to learn which macros must be defined. To run the code
	you will need to create your own personalized setup file named setup_<username>.do, where <username> is replaced
	by your username on this computer running the code.

Part 2. Download and prepare original data

	The full files were obtained from NBER (http://www.nber.org/data/survey-of-income-and-program-participation-sipp-data.html). 
	
	The puw files are the Core data.
	he putm files are the Topical Module files.
	
        The original do files must be modified to match the environment in which they will be executed.
	A couple other modifications may also be useful.
	1. The original do file contains a hard-coded path to the data file.  This must be modified to
		match your environment.  In the version current as of this writing, the macro requiring
		modification is named dat_name.
	2. The original do file uses the "saveold" command instead of "save".  You may wish to change
		this to "save" to use the DTA format current for your version of Stata.  Saveold uses
		a backward compatible format, version 13 as of this writing.
	3. The original do file opens a log file but does not close it.  You may wish to add a
		"log close" to the do file.

	Also, you may find that the dictionary files are downloaded as "sippxxxx.dct.txt" rather than
	"sippxxxx.dct".  If so, you should rename them to remove the ".txt".

        You also need to unzip the data files before running the do files.

Part 3. Produce variables for analysis

	To get started with any ChildHH code:
		1.  start stata
		2.  cd to the directory that holds this file as well as setup_childhh_environment
		3.  do setup_childhh_environment.do
		4.  do do_childrens_household_core.do (find this file in the sipp2008_code directory) 

	setup_childhh_environment.do defines several macros that locate the project data and otherwise establish project norms.  
	It also executes a personalized setup do file, named setup_<username>.do.

	The remaining do files in this directory provide a convenient way to ensure that results are logged and
	that random number generator state is preserved so that results are repeatable.

	Part 4. Create tables and supplementary analsyses
	
	To create table 1, run Table1.do. To create table 2, run Table2.do
	The figures are based on data in the tables.
	
	To generate a report with information on missing data, run missing_analysis.do
	To see our comparison of our transitively-derived relationships with relationships
	reported in the Wave 2 relationships matrix, run relationship_matrix

Part 4. Create tables and supplementary analsyses
	
	To create table 1, run Table1.do. To create table 2, run Table2.do
	The figures are based on data in the tables.
	
	To generate a report with information on missing data, run missing_analysis.do
	To see our comparison of our transitively-derived relationships with relationships
	reported in the Wave 2 relationships matrix, run relationship_matrix

Part 5. A map of all do files and associated data


	Setup
	
	README.CHILDHH -- this file
	setup_childhh_environment
	setup_XXXX -- your setup file that is called by setup_childhh_envirnoment

	do_and_log -- a file that automatically initiates a log file that records settings and execution of code
	childhh_prolog -- do_and_log calls this file that begins the log file and records settings when code begins
	childhh_epilog -- do_and_log calls this file that records settings when code ends and closes log



	Create core datafiles

	do_childrens_household_core.do
		project_macros.do
		merge_waves.do 			   	--> allwaves.dta
	
		make_auxiliary_datasets.do 	--> shhadid_members.dta
									--> ssuid_members_wide.dta
									--> person_pdemo.dta
									--> partner_of_ref_person_long.dta
			make_aux_refperson.do  	--> ref_person_long
									--> ref_person_wide
		
		convert_to_wide.do	   		-->person_wide
		normalize_ages		   		-->person_wide_adjusted_ages
									-->demo_wide.dta
									-->demo_long_all
									-->demo_long_interviews
		compute_base_relationships 	--> relationships_tc0_wide
			relationship_label.do
	
		compute_secondary_relationships.do
									--> relationship_pairs_bywave
							   
		create_comp_change		   	--> comp_change.dta
		
		create_hh_change		   	--> hh_change.dta
		
		create_changer_rels		   	--> changer_rels
			simple_rel_label.do
			
		create_HHchangeWithRelationships	
									--> HHchangeWithRelationships
									
		create_HHComp_asis		   	--> HHComp_asis

	Analysis
		Table1.do						--> Table1a.docx
										--> Table1b.csv
	
		Table2.do
			HHchange_table				--> HHChange.xlsx
			Compchange_table			--> CompChangeType.xlsx
			addrchange_table		modifies HHChange.xlsx	
		
		missing_analysis.do
			short_transitions.do

		relationship_matrix.do