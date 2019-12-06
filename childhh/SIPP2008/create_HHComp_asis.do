* Create a data file with one record for each coresident pair in each wave
* Merge onto the file the relationships data created by unify_relationships.


****************************************************************************
* create database with all pairs of coresident individuals in each wave
****************************************************************************
use "$tempdir/allwaves"

keep ssuid shhadid epppnum swave errp

sort ssuid shhadid swave

by ssuid shhadid swave:  gen HHmembers = _N  /* Number the people in the household in each wave. */

* merge in age of other person in the household to save as "to_age"
merge 1:1 ssuid epppnum swave using "$tempdir/demo_long_interviews.dta", keepusing(adj_age)

assert _merge==3

drop _merge

rename epppnum relto
rename errp errpto
rename adj_age to_age

save "$tempdir/to", $replace

use "$tempdir/allwaves", clear

keep ssuid shhadid epppnum swave errp

rename epppnum relfrom
rename errp errpfrom

joinby ssuid shhadid swave using "$tempdir/to"  

* drop pairs of ego to self
drop if relto==relfrom

save "$tempdir/pairwise_bywave", $replace

/*
********************************************************************************
* for the purpose of checking how many pairs of individuals are represented in 
* the unified relationships, create a pairwise database for all waves
********************************************************************************

duplicates drop ssuid relfrom relto, force

drop swave

save "$tempdir/pairwise", $replace

*/

use "$tempdir/pairwise_bywave", clear

merge m:1 ssuid relfrom relto swave using "$tempdir/relationship_pairs_bywave"

replace relationship = .a if (_merge == 1) & (missing(relationship))
replace relationship = .m if (_merge == 3) & (missing(relationship))

assert (relationship != .)
drop _merge

tab relationship, m

rename relfrom epppnum
rename relto to_EPPNUM

merge m:1 ssuid epppnum swave using "$tempdir/demo_long_interviews.dta"

drop if _merge==2

drop _merge

tab relationship, m 

do "$sipp2008_code/simple_rel_label"

save "$SIPP08keep/HHComp_asis.dta", $replace






