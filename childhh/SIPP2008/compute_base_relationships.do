//========================================================================================================//
//===== Children's Household Instability Project                                     
//===== Dataset: SIPP2008                                                            
//===== Purpose: Compute relationships of ego to other household members using epnmom, epndad, epnspouse and errp 
//========================================================================================================//

********************************************************************************
* Section: Start by creating programs to process data
********************************************************************************

** Program to create process data from all waves and save a record for EGO and coresident (bio/step/adoptive mother/father) 
** Each relationship type is saved in a different file.
** The program also creates inverse relationships (i.e. relationships of other people to ego). 

capture program drop compute_relationships
program define compute_relationships
    args person1 person2 relationship_1_2 relationship_2_1 reason condition filename_1_2 filename_2_1 /* local macro */

    preserve
    gen relfrom = `person1' if `condition'
    gen relto = `person2' if `condition'
    gen relationship_tc0 = "`relationship_1_2'":relationship if `condition'
    label values relationship_tc0 relationship
    gen reason_tc0 = "`reason'" if `condition'
    tab relationship_tc0 swave
    keep ssuid shhadid swave relfrom relto relationship_tc0 reason_tc0
    drop if missing(relationship_tc0)
    drop if (relfrom == relto)
    save "$tempdir/`filename_1_2'", $replace
    restore

    preserve
    gen relfrom = `person2' if `condition'
    gen relto = `person1' if `condition'
    gen relationship_tc0 = "`relationship_2_1'":relationship if `condition'
    label values relationship_tc0 relationship
    gen reason_tc0 = "`reason'" if `condition'
    tab relationship_tc0 swave
    keep ssuid shhadid swave relfrom relto relationship_tc0 reason_tc0
    drop if missing(relationship_tc0)
    drop if (relfrom == relto)
    save "$tempdir/`filename_2_1'", $replace
    restore
end

** Program to fix conflicting relationship pairs, taking the first as preferable to the second. Conflicting relationships are
** possible when relationship identified with the parent pointer is not the same as the relationship identified with the
** relationship to householder variable. 

capture program drop fixup_rel_pair
program define fixup_rel_pair
    args preferred_rel second_rel /*local macro, the first relationship is preferred */

    display "Preferring `preferred_rel' over `second_rel'"
    
    gen meets_condition = (((relationship_tc01 == "`preferred_rel'":relationship) & (relationship_tc02 == "`second_rel'":relationship)) | ((relationship_tc02 == "`preferred_rel'":relationship) & (relationship_tc01 == "`second_rel'":relationship)))
    gen needs_swap = ((relationship_tc02 == "`preferred_rel'":relationship) & (relationship_tc01 == "`second_rel'":relationship))

    replace numrels_tc0 = 1 if (meets_condition == 1)
    replace relationship_tc01 = "`preferred_rel'":relationship if ((meets_condition == 1) & (needs_swap == 1))
    replace relationship_tc02 = . if (meets_condition == 1)
    replace reason_tc01 = reason_tc02 if ((meets_condition == 1) & (needs_swap == 1))
    replace reason_tc02 = "" if (meets_condition == 1)

    drop meets_condition needs_swap
end

********************************************************************************
* Read in and label data
use "$tempdir/allwaves"

do "$sipp2008_code/relationship_label"
********************************************************************************

* A small number of cases identified themselves as their own mother, father, or spouse
destring epppnum, generate(epppnum_n)
drop epppnum
rename epppnum_n epppnum

replace epnmom=.   if epppnum==epnmom
replace epndad=.   if epppnum==epndad
replace epnspous=. if epppnum==epnspous

********************************************************************************
** Section: Process parent/child relationships from epnmom, epndad, and epnspous.
**
** Use Program: compute_relationships
**        args: person1 person2 relationship_1_2 relationship_2_1 reason condition filename_1_2 filename_2_1
********************************************************************************
compute_relationships epppnum epnmom biochild biomom epnmom "((!missing(epnmom)) & (epnmom != 9999) & (etypmom == 1))" biochild_of_mom biomom
compute_relationships epppnum epndad biochild biodad epndad "((!missing(epndad)) & (epndad != 9999) & (etypdad == 1))" biochild_of_dad biodad
compute_relationships epppnum epnmom stepchild stepmom epnmom "((!missing(epnmom)) & (epnmom != 9999) & (etypmom == 2))" stepchild_of_mom stepmom
compute_relationships epppnum epndad stepchild stepdad epndad "((!missing(epndad)) & (epndad != 9999) & (etypdad == 2))" stepchild_of_dad stepdad
compute_relationships epppnum epnmom adoptchild adoptmom epnmom "((!missing(epnmom)) & (epnmom != 9999) & (etypmom == 3))" adoptchild_of_mom adoptmom
compute_relationships epppnum epndad adoptchild adoptdad epndad "((!missing(epndad)) & (epndad != 9999) & (etypdad == 3))" adoptchild_of_dad adoptdad
compute_relationships epppnum epnspous spouse spouse epnspous "((!missing(epnspous)) & (epnspous != 9999) & (esex == 1))" epnspous1 epnspous2 

********************************************************************************
** Section: Merge in errp, a variable indicating the reference person for the household.
**          ref_person_long was created with make_auxiliary_datasets
********************************************************************************

merge m:1 ssuid shhadid swave using "$tempdir/ref_person_long"
assert missing(ref_person) if (_merge == 2)
drop if (_merge == 2)
assert (_merge == 3)
drop _merge
********************************************************************************


********************************************************************************
** Section: Generate records for spouse, child, grandchild, parent, sibling, 
**          others, foster child, partener, no relation based errp. 
** Note: The 1 and 2 suffixes below are convenient but not very descriptive.
**        1 means the relationship as stated; 2 means the reverse.  
**        E.g., errp_child_of_mom2 are moms of children identified by errp == 4.
**
** Use Program: compute_relationships
**        args: person1 person2 relationship_1_2 relationship_2_1 reason condition filename_1_2 filename_2_1
***********************************************************************************************************************
destring ref_person, generate(ref_person_n)
drop ref_person
rename ref_person_n ref_person

* Spouse of reference person.
compute_relationships epppnum ref_person spouse spouse errp_3 "(errp == 3)" errp_spouse1 errp_spouse2

* Child of reference person.  You'd expect epnmom/dad to capture this, too.
compute_relationships epppnum ref_person child mom errp_4 "((errp == 4) & (ref_person_sex == 2))" errp_child_of_mom1 errp_child_of_mom2
compute_relationships epppnum ref_person child dad errp_4 "((errp == 4) & (ref_person_sex == 1))" errp_child_of_dad1 errp_child_of_dad2

* Grandchild of reference person.
compute_relationships epppnum ref_person grandchild grandparent errp_5 "(errp == 5)" errp_grandchild1 errp_grandchild2

* Parent of reference person.
compute_relationships epppnum ref_person mom child errp_6 "((errp == 6) & (esex == 2))" errp_mom1 errp_mom2
compute_relationships epppnum ref_person dad child errp_6 "((errp == 6) & (esex == 1))" errp_dad1 errp_dad2

* Sibling of reference person.
compute_relationships epppnum ref_person sibling sibling errp_7 "(errp == 7)" errp_sibling1 errp_sibling2

* Other relative.
compute_relationships epppnum ref_person other_rel other_rel errp_8 "(errp == 8)" errp_otherrel1 errp_otherrel2

* Foster child.
compute_relationships epppnum ref_person f_child f_parent errp_9 "(errp == 9)" errp_fosterchild1 errp_fosterchild2

* Partner of reference person.
compute_relationships epppnum ref_person partner partner errp_10 "(errp == 10)" errp_partner1 errp_partner2

* No relation.
compute_relationships epppnum ref_person norel norel errp_ge_11 "((errp == 11) | (errp == 12) | (errp == 13))" errp_norelation1 errp_norelation2

clear

*******************************************************************************
** Section: Append all relationship data sets together.
*******************************************************************************
use "$tempdir/biochild_of_mom"
append using "$tempdir/biomom"
append using "$tempdir/biochild_of_dad"
append using "$tempdir/biodad"
append using "$tempdir/stepchild_of_mom"
append using "$tempdir/stepmom"
append using "$tempdir/stepchild_of_dad"
append using "$tempdir/stepdad"
append using "$tempdir/adoptchild_of_mom"
append using "$tempdir/adoptmom"
append using "$tempdir/adoptchild_of_dad"
append using "$tempdir/adoptdad"
append using "$tempdir/errp_spouse1"
append using "$tempdir/errp_spouse2"
append using "$tempdir/errp_child_of_mom1"
append using "$tempdir/errp_child_of_mom2"
append using "$tempdir/errp_child_of_dad1"
append using "$tempdir/errp_child_of_dad2"
append using "$tempdir/errp_grandchild1"
append using "$tempdir/errp_grandchild2"
append using "$tempdir/errp_mom1"
append using "$tempdir/errp_mom2"
append using "$tempdir/errp_dad1"
append using "$tempdir/errp_dad2"
append using "$tempdir/errp_sibling1"
append using "$tempdir/errp_sibling2"
append using "$tempdir/errp_otherrel1"
append using "$tempdir/errp_otherrel2"
append using "$tempdir/errp_fosterchild1"
append using "$tempdir/errp_fosterchild2"
append using "$tempdir/errp_partner1"
append using "$tempdir/errp_partner2"
append using "$tempdir/errp_norelation1"
append using "$tempdir/errp_norelation2"
append using "$tempdir/epnspous1"
append using "$tempdir/epnspous2"


* Force drop when we have more than one reason for the SAME relationship 
duplicates drop ssuid shhadid swave relfrom relto relationship_tc0, force

save "$tempdir/relationships_tc0_all", $replace

********************************************************************************
** Section: Find pairs for which we have more than one relationship type in a single wave.
**           Select the more specific one
********************************************************************************
sort ssuid shhadid swave relfrom relto
by ssuid shhadid swave relfrom relto:  gen numrels_tc0 = _N /* total number of relationships */
by ssuid shhadid swave relfrom relto:  gen relnum_tc0 = _n

assert (numrels_tc0 <= 2)

*reshape so that we can compare relationships for pairs (within wave) with more than one relationship type
reshape wide relationship_tc0 reason_tc0, i(ssuid shhadid swave relfrom relto) j(relnum_tc0)

display "Number of relationships in a wave before any fix-ups"
tab numrels_tc0

** Use program: fixup_rel_pair args: args preferred_rel second_rel
* start with biological parents
fixup_rel_pair biomom mom
fixup_rel_pair biodad dad
fixup_rel_pair biochild child

display "Number of relationships in a wave after bio fixes"
tab numrels_tc0

* Fix adopt and step. 
fixup_rel_pair stepmom mom
fixup_rel_pair stepdad dad
fixup_rel_pair stepchild child
fixup_rel_pair adoptmom mom
fixup_rel_pair adoptdad dad
fixup_rel_pair adoptchild child

display "Number of relationships in a wave after step and adopt fixes"
tab numrels_tc0

tab relationship_tc01 relationship_tc02 if (numrels_tc0 > 1)

* Save a data set with remaining conflicted relationships.
preserve
keep if (numrels_tc0 > 1)
save "$tempdir/relationships_tc0_lost", $replace 
restore

rename relationship_tc01 relationship
rename reason_tc01 reason

drop relationship_tc02 reason_tc02

replace relationship=. if numrels_tc0 > 1

*Despite the name, this file is still long. One record per pair per wave.
save "$tempdir/relationships_tc0_wide", $replace



