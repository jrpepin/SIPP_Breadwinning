//========================================================================================================//
//===== Children's Household Instability Project                               
//===== Dataset: SIPP2008                                                     
//===== Purpose: Creates an analysis file with demographic variables. 
//========================================================================================================//



use "$tempdir/hh_change", clear

keep SSUID EPPPNUM SHHADID* WPFINWGT* adj_age* addr_change* comp_change* adult_change* child_change* my_race

reshape long adj_age addr_change comp_change WPFINWGT adult_change child_change SHHADID, i(SSUID EPPPNUM) j(SWAVE)

************************************************************
** Function: Merge hh_change with demo08
**
** Logic: Allwaves will have race and sex
************************************************************
sort SSUID EPPPNUM SWAVE
merge m:1 SSUID EPPPNUM SWAVE using "$tempdir/demo08.dta" 


* allwaves will have race and sex but not maternal education
tab adj_age _merge, m


* Keep recodes in both hh_change and demo08
keep if _merge==3

drop _merge




*************************************************************
** Function: Merge the updated datset with demoHH08.
*************************************************************
sort SSUID SHHADID SWAVE
merge m:1 SSUID SHHADID SWAVE using "$tempdir/demoHH08.dta"

/* Note that waves without interviews are missing in demoHH08.
 There are 5,328 cases where comp_change==1 or addr_change==1
 because they were not in the current wave, but they appear in an existing household in the next. 
 For these cases demoHH08 is missing.*/

keep if _merge==3 | comp_change==1 | addr_change==1

drop _merge

gen anychange=addr_change
replace anychange=1 if comp_change==1

** Keep only respondents who are children. 
keep if adj_age < 17


save "$tempdir/hhchange_analysis", replace


tab first_raceth
tab momfirstced




//==================== Attention!===========================//
* Why is this sample smaller than for Table 1? Is it because one needs to be observed in two waves? 
