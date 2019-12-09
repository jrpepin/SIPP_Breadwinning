** Create elements for Table 1: Table1a.docx and Table1b.csv 
do "$childhh_base_code/do_and_log" "$sipp2008_code" "$sipp2008_logs" Table1  

** Create elements for Table 2: HHChange.xlsx and CompChangeType.xlsx 
do "$childhh_base_code/do_and_log" "$sipp2008_code" "$sipp2008_logs" Table2  
	
** Creates MissingReport.docx		
do "$childhh_base_code/do_and_log" "$sipp2008_code" "$sipp2008_logs" missing_analysis


** Evaluates our transitively-derived relationships against the Wave 2 relationship matrix
do "$childhh_base_code/do_and_log" "$sipp2008_code" "$sipp2008_logs" relationship_matrix.do
