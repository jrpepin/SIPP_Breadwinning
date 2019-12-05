*******************************************************
* Table 2 analysis
*******************************************************
use "$SIPP08keep/HHchangeWithRelationships.dta", clear

* limit to cases that have fully-observed intervals or we were able to infer hh_change

drop if insample==0

keep if adj_age < $adult_age 

* this doesn't really matter since comp_change is missing if SWAVE==15
drop if SWAVE==15

do "$sipp2008_code/HHchange_table"  

do "$sipp2008_code/Compchange_table"  

do "$sipp2008_code/addrchange_table"  


