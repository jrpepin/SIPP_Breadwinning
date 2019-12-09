//==============================================================================
//===== Children's Household Instability Project
//===== Dataset: SIPP2008
//===== Purpose:  Link individuals identified as entering, leaving, or staying in
//===== a person's (ego's) household to their relationship to ego.
//==============================================================================

use "$SIPP08keep/comp_change.dta", clear

keep SSUID EPPPNUM SHHADID* arrivers* leavers* stayers* comp_change* comp_change_reason* adj_age* 

reshape long SHHADID adj_age arrivers leavers stayers comp_change comp_change_reason, i(SSUID EPPPNUM) j(SWAVE)

gen have_arrivers = (indexnot(arrivers, " ") != 0)
gen have_leavers = (indexnot(leavers, " ") != 0)

gen have_changers = (have_arrivers | have_leavers)

tab comp_change have_changers

assert (have_changers == 0) if (comp_change == 0)
assert (have_changers == 0) if missing(comp_change)
assert (have_changers == 1) if (comp_change == 1)

drop if missing(comp_change)

drop if (comp_change == 0)

save "$tempdir/comp_change_onlychangers", $replace

********************************************************************************
* Section: create long file where each record is a person who started or stopped
*          living with ego (and stayed living with ego).
********************************************************************************

foreach changer in leaver arriver stayer {
    clear

    use "$tempdir/comp_change_onlychangers"

    * Compute max number of leavers/arrivers.
    gen n_`changer's = wordcount(`changer's)
    egen max_`changer's = max(n_`changer's)

    forvalues my_`changer'_num = 1/`=max_`changer's' {
        gen `changer'`my_`changer'_num' = word(`changer's, `my_`changer'_num')
    }
    drop `changer's max_`changer's

    keep SSUID EPPPNUM SHHADID SWAVE adj_age comp_change_reason n_`changer's `changer'* 

    reshape long `changer', i(SSUID EPPPNUM SWAVE) j(`changer'_num)

    drop if missing(`changer')

    save "$tempdir/hh_`changer's", $replace
}

********************************************************************************
* Section: Linking those who leave to relationships in that wave
********************************************************************************

use "$tempdir/hh_leavers", clear
drop if missing(leaver)
gen relfrom = EPPPNUM
destring leaver, gen(relto)
merge 1:1 SSUID relfrom relto SWAVE using "$tempdir/relationship_pairs_bywave", keepusing(relationship)
	
display "deleting relationships to self"
drop if relfrom==relto

replace relationship=40 if _merge==1

drop if _merge == 2
drop _merge

display "Relationships for leavers"
tab relationship, m sort
save "$tempdir/leaver_rels", $replace

********************************************************************************
* Section: Linking those who arrive to relationships
*          We have to link in wave+n because they aren't with ego in the current 
*          wave else they wouldn't be arrivers 
********************************************************************************

use "$tempdir/hh_arrivers", clear

* We link to relationship in next wave, since they aren't together in this wave
replace SWAVE=SWAVE+1
drop if missing(arriver)
gen relfrom = EPPPNUM
destring arriver, gen(relto)
merge 1:1 SSUID relfrom relto SWAVE using "$tempdir/relationship_pairs_bywave", keepusing(relationship)

* return SWAVE to its original value. (Yiwen, this is the silly error I made 
* that broke the code. I forgot to put SWAVE back to its original value). 	
replace SWAVE=SWAVE-1

display "deleting relationships to self"
drop if relfrom==relto

replace relationship=40 if _merge==1

drop if _merge == 2
drop _merge

display "Relationships for arrivers"
tab relationship, m sort
save "$tempdir/arriver_rels", $replace

********************************************************************************
* Section: getting the age of each person so that we can calculate an age difference
********************************************************************************
foreach changer in leaver arriver {
	clear
    display "Processing `changer's"
	
	use "$tempdir/`changer'_rels"

    rename adj_age from_age

	drop EPPPNUM
	
	* get changer age *
    gen EPPPNUM = relto
    merge m:1 SSUID EPPPNUM SWAVE using "$tempdir/demo_long_all", keepusing(adj_age)
    drop if (_merge == 2)
    assert (_merge == 3)
	
    drop _merge
    drop EPPPNUM
    rename adj_age to_age
	
	* bring back ego's person number
	rename relfrom EPPPNUM
	
	save "$tempdir/`changer'_rels_withage", $replace
}    

gen change_type=1

append using "$tempdir/leaver_rels_withage"
replace change_type=2 if missing(change_type)

label variable change_type "Indicator for whether this person arrive in or left from ego's household"
label define change_type 1 "arriver" 2 "leaver" 

label values change_type change_type 

* Label relationships. 
do "$sipp2008_code/simple_rel_label"

***********************************************************************
* Note that we compared our relationships to the relationships identified 
* in the relationship matrix available in Wave 2 (see relationship_matrix.do) 
* and found thatthe cases coded child_or_relative (31) or child_or_ 
* nephewniece (30) were never children and always an other relatives. 
* Likewise for auntuncle_or_parent (25). Thus, we code these as other relatives
*
* In addition, we found that nearly all (85%) the missing relationships (40) were
* nonrelatives.
**********************************************************************


gen bioparent=1 if relationship==1
gen parent=1 if inlist(relationship,1,4,7,19,21)
gen sibling=1 if inlist(relationship,17)
gen child=1 if inlist(relationship,2,3,5,6,8,9,10,11,23)
gen spartner=1 if inlist(relationship,12,18)
gen nonrel=1 if inlist(relationship,20,22,34,37,38,40)
gen foster=1 if inlist(relationship,20,22,34,38)
gen grandparent=1 if inlist(relationship,13,14,27)
gen other_rel=1 if inlist(relationship, 15,16,24,25,26,28,29,30,31,33,32,35,36) //not parents, siblings, children, spouses, or grandparents
gen unknown=1 if relationship==40 | missing(relationship)
gen nonnuke=1 if nonrel==1 | grandparent==1 | other_rel==1 | unknown==1
gen allelse=1 if inlist(relationship,2,3,5,6,8,9,10,11,23,12,18) // children, spouses

gen adult_arrive=1 if change_type==1 & to_age >= $adult_age
gen adult_leave=1 if change_type==2 & to_age >= $adult_age

*create variables for parent_arrive and parent_leave
gen parent_arrive=1 if change_type==1 & parent==1
gen parent_leave=1 if change_type==2 & parent==1

save "$tempdir/changer_rels", $replace



