//========================================================================================================================//
//=================== Children's Household Instability Project                    ========================================//
//=================== Dataset: SIPP2008                                           ========================================//
//=================== Purpose: This file fixes up age so the waves are consistent ========================================//
//========================================================================================================================//
use "$tempdir/person_wide"

gen num_ages = 0
forvalues wave = $first_wave/$final_wave {
    replace num_ages = num_ages + 1 if (!missing(TAGE`wave'))
}

******************************************************************************
*Section: create expected age variables based on age at first observation and 
*          aging the person one year every 3 observations or based on last observation
*          and decrementing one year every 3 observations 
******************************************************************************

*** We make a simple projection of expected age from the first reported age
* and from the last reported age.  
gen expected_age_fwd = TAGE$first_wave
gen expected_age_fwd$first_wave = expected_age_fwd

* a counter; after 3 observations at current age, increase by 1
gen num_curr_age = 0
replace num_curr_age = 1 if (!missing(expected_age_fwd))

forvalues wave = $second_wave/$final_wave {
    * Increment counter of age runs if we have established an age.
    * Set the counter to 1 if we are just now establishing an age.
    replace num_curr_age = num_curr_age + 1 if (!missing(expected_age_fwd))
    replace num_curr_age = 1 if ((!missing(TAGE`wave')) & (missing(expected_age_fwd)))
    replace expected_age_fwd = TAGE`wave' if ((!missing(TAGE`wave')) & (missing(expected_age_fwd)))

    * Increment the age if we've already used it three times. Reset counter.
    replace expected_age_fwd = expected_age_fwd + 1 if (num_curr_age > 3)
    replace num_curr_age = 1 if (num_curr_age > 3)

    gen expected_age_fwd`wave' = expected_age_fwd
}
drop num_curr_age expected_age_fwd

* backward projection.
gen expected_age_bkwd = TAGE$final_wave
gen expected_age_bkwd$final_wave = expected_age_bkwd

gen num_curr_age = 0
replace num_curr_age = 1 if (!missing(expected_age_bkwd))

forvalues wave = $penultimate_wave (-1) $first_wave {
    * Increment counter of age runs if we have established an age.
    * Set the counter to 1 if we are just now establishing an age.
    replace num_curr_age = num_curr_age + 1 if (!missing(expected_age_bkwd))
    replace num_curr_age = 1 if ((!missing(TAGE`wave')) & (missing(expected_age_bkwd)))
    replace expected_age_bkwd = TAGE`wave' if ((!missing(TAGE`wave')) & (missing(expected_age_bkwd)))

    * Decrement the age if we've already used it three times.
    replace expected_age_bkwd = expected_age_bkwd - 1 if (num_curr_age > 3)
    replace num_curr_age = 1 if (num_curr_age > 3)

    gen expected_age_bkwd`wave' = expected_age_bkwd
}
drop num_curr_age expected_age_bkwd

********************************************************************************
* Section: Check backwards and forwards projections against what is coded
********************************************************************************

*** Count the number of times age matches each projection (within one, in the correct direction).
gen num_fwd_matches = 0
gen num_bkwd_matches = 0
forvalues wave = $first_wave/$final_wave {
    gen fwd_match`wave' = ((!missing(TAGE`wave')) & (TAGE`wave' >= expected_age_fwd`wave') & (TAGE`wave' <= expected_age_fwd`wave' + 1))
    replace num_fwd_matches = num_fwd_matches + 1 if (fwd_match`wave' == 1)
    gen bkwd_match`wave' = ((!missing(TAGE`wave')) & (TAGE`wave' <= expected_age_bkwd`wave') & (TAGE`wave' >= expected_age_bkwd`wave' - 1))
    replace num_bkwd_matches = num_bkwd_matches + 1 if (bkwd_match`wave' == 1)
}

*check against number of observed waves to create problem flag 
gen num_fwd_problem=num_ages-num_fwd_matches
gen num_bkwd_problem=num_ages-num_bkwd_matches

gen anyproblem=0
replace anyproblem=1 if num_fwd_problem > 0 | num_bkwd_problem > 0

tab anyproblem

********************************************************************************
* Section: adjust age to projection if backwards and forwards projection are within 1
********************************************************************************

gen adj_age$first_wave = TAGE$first_wave
forvalues wave = $second_wave/$final_wave {

* fix age when it is out of line with backwards and forwards projections
    gen adj_age`wave' = TAGE`wave'
    replace adj_age`wave' = expected_age_fwd`wave' if ((!missing(TAGE`wave')) & (fwd_match`wave' == 0) & (bkwd_match`wave' == 0) & (abs(expected_age_fwd`wave' - expected_age_bkwd`wave') <= 1))
	
* fix age when it is missing. Take forward projection first. If no forward projection, then take backward projection.	
	replace adj_age`wave'= expected_age_fwd`wave' if missing(adj_age`wave') & !missing(expected_age_fwd`wave')
	replace adj_age`wave'=expected_age_bkwd`wave' if missing(adj_age`wave') & !missing(expected_age_bkwd`wave')
}

* The plan will be to replace adjusted ages when adj_age is missing and expected_age_fwd/expected_age_bkwd are not.

********************************************************************************
* Section: Check backwards and forwards projections against adjusted age
********************************************************************************
gen num_adjfwd_matches = 0
gen num_adjbkwd_matches = 0
forvalues wave = $first_wave/$final_wave {
    gen adjfwd_match`wave' = ((!missing(adj_age`wave')) & (adj_age`wave' >= expected_age_fwd`wave') & (adj_age`wave' <= expected_age_fwd`wave' + 1))
    replace num_adjfwd_matches = num_adjfwd_matches + 1 if (adjfwd_match`wave' == 1)
    gen adjbkwd_match`wave' = ((!missing(adj_age`wave')) & (adj_age`wave' <= expected_age_bkwd`wave') & (adj_age`wave' >= expected_age_bkwd`wave' - 1))
    replace num_adjbkwd_matches = num_adjbkwd_matches + 1 if (adjbkwd_match`wave' == 1)
}

gen num_adjfwd_problem=num_ages-num_adjfwd_matches
gen num_adjbkwd_problem=num_ages-num_adjbkwd_matches

gen any_adj_problem=0
replace any_adj_problem=1 if num_adjfwd_problem > 0 | num_adjbkwd_problem > 0

*******************************************************************************
* Section: create flags for data that remain problematic. 
*******************************************************************************

gen monotonic = 1 /* dpes age always increase? */
gen ageproblem=0 /* are there deviations in age from one observation to the next greater than 5 */
gen childageproblem=0
gen curr_age = adj_age$first_wave
forvalues wave = $second_wave/$final_wave {
    replace monotonic = 0 if ((!missing(adj_age`wave')) & (!missing(curr_age)) & (adj_age`wave' < curr_age))
	replace ageproblem=1 if ((!missing(adj_age`wave')) & (!missing(curr_age)) & (abs(adj_age`wave'-curr_age) > 5))
	replace childageproblem=1 if ((!missing(adj_age`wave')) & (!missing(curr_age)) & (abs(adj_age`wave'-curr_age) > 5)) & (curr_age < 18)
    replace curr_age = adj_age`wave' if (!missing(adj_age`wave'))
}

tab ageproblem anyproblem
tab childageproblem

tab ageproblem any_adj_problem

drop curr_age
drop expected_age_bkwd* expected_age_fwd*
drop adjbkwd* adjfwd*
drop bkwd* fwd*
drop monotonic
drop num_adjbkwd_matches num_adjfwd_matches 
drop anyproblem
drop any_adj_problem
drop TAGE*


* Create dummies for whether in this interview to be able to create an indicator for whether in interview next wave
forvalues w=1/$final_wave {
  gen in`w'=0
  replace in`w'=1 if !missing(ERRP`w')
  }
  
forvalues w=1/$penultimate_wave {
  local x=`w'+1
  gen innext`w'=0
  replace innext`w'=1 if in`x'==1
 }

save "$tempdir/person_wide_adjusted_ages", $replace

keep SSUID EPPPNUM EMS* ERRP* WPFINWGT* EORIGIN* EBORNUS* ETYPMOM* ETYPDAD* my_race my_racealt my_sex mom_educ* dad_educ* mom_immigrant* dad_immigrant* adj_age* mom_age* biomom_age* biomom_educ* dad_age* biodad_age* innext* ref_person* ref_person_sex* ref_person_educ* biomom_ed_first mom_ed_first dad_ed_first par_ed_first mom_measure

save "$tempdir/demo_wide.dta", $replace

reshape long adj_age EMS ERRP WPFINWGT EORIGIN EBORNUS ETYPMOM ETYPDAD mom_educ dad_educ mom_immigrant dad_immigrant mom_age biomom_age biomom_educ dad_age biodad_age innext ref_person ref_person_sex ref_person_educ, i(SSUID EPPPNUM) j(SWAVE)

label variable adj_age "Adjusted Age"
label variable innext "Is this person interviewed in next wave?"

* now includes all observations, even when missing interview. ERRP is missing when no interview.
tab ERRP,m 

* most important for linking to arrivers who have missing data 
save "$tempdir/demo_long_all", $replace

drop if missing(ERRP)

save "$tempdir/demo_long_interviews", $replace
