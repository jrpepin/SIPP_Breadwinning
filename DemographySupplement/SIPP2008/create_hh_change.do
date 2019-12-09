//==============================================================================
//===== Children's Household Instability Project                                                    
//===== Dataset: SIPP2008                                                                               
//===== Purpose: Create a database with comp_change, addr_change, and sociodemographic characteristics
//===== One record per person per wave.
//===== create_comp_change generates the variable comp_change. This file adds addr_change
//===== and reshapes the data to long form.
//===== Note: this code depends on macros set in project_macros and create_comp_change
//==============================================================================

use "$SIPP08keep/comp_change.dta", clear

#delimit ; 
label define addr_change          0 "No move"
                                  1 "Move";	 
#delimit cr

********************************************************************************
* Function Propagate shhadid_members forard into prev_SHHADID for missing waves.
********************************************************************************

gen prev_SHHADID$first_wave = .
forvalues wave = $second_wave/$final_wave {
    local prev_wave = `wave' - 1
    gen prev_SHHADID`wave' = SHHADID`prev_wave' if (missing(SHHADID`wave') & missing(prev_SHHADID`prev_wave'))
    replace prev_SHHADID`wave' = prev_SHHADID`prev_wave' if (missing(SHHADID`wave') & (!missing(prev_SHHADID`prev_wave')))
}

********************************************************************************
** Function:  Propagate shhadid_members backward into future_hh_members for missing waves.  
********************************************************************************

gen future_SHHADID$final_wave = .
forvalues wave = $penultimate_wave (-1) $first_wave {
    local next_wave = `wave' + 1
    gen future_SHHADID`wave' = SHHADID`next_wave' if (missing(SHHADID`wave') & missing(future_SHHADID`next_wave'))
    replace future_SHHADID`wave' = future_SHHADID`next_wave' if (missing(SHHADID`wave') & (!missing(future_SHHADID`next_wave')))
}

********************************************************************************
** Function: walk backward through the waves and for each wave in which ego is missing  compare prev_SHHAIDD to see if we find anyone
********************************************************************************

gen found_prev_SHHADID$first_wave = .
forvalues wave = $final_wave (-1) $second_wave {
	gen found_prev_SHHADID`wave'= 0 if (missing(SHHADID`wave'))
	gen found_prev_SHHADID_in_gap`wave'=0 if (missing(SHHADID`wave'))
	replace found_prev_SHHADID`wave' = 1 if ((missing(SHHADID`wave')) & (strpos(ssuid_shhadid`wave', " " + string(prev_SHHADID`wave') + " ") != 0))
	replace found_prev_SHHADID_in_gap`wave' = 1 if ((missing(SHHADID`wave')) & (strpos(ssuid_shhadid`wave', " " + string(prev_SHHADID`wave') + " ") !=0))
	if (`wave' < $final_wave) {
		local next_wave = `wave' + 1
		replace found_prev_SHHADID_in_gap`wave' = 1 if ((missing(SHHADID`wave')) & (found_prev_SHHADID_in_gap`next_wave' == 1))
	}
}

********************************************************************************
** Function: walk forward through the waves 
********************************************************************************

gen found_future_SHHADID$final_wave = .
forvalues wave = $first_wave/$penultimate_wave {
	gen found_future_SHHADID`wave'= 0 if (missing(SHHADID`wave'))
	gen found_future_SHHADID_in_gap`wave'=0 if (missing(SHHADID`wave'))
	replace found_future_SHHADID`wave' = 1 if ((missing(SHHADID`wave')) & (strpos(ssuid_shhadid`wave', " " + string(prev_SHHADID`wave') + " ") != 0))
	replace found_future_SHHADID_in_gap`wave' = 1 if ((missing(SHHADID`wave')) & (strpos(ssuid_shhadid`wave', " " + string(prev_SHHADID`wave') + " ") !=0))
	if (`wave' > $final_wave) {
		local prev_wave = `wave' - 1
		replace found_future_SHHADID_in_gap`wave' = 1 if ((missing(SHHADID`wave')) & (found_future_SHHADID_in_gap`prev_wave' == 1))
	}
}

*******************************************************************************
** Function: Compute address change.
*******************************************************************************

forvalues wave = $first_wave/$penultimate_wave {
    local next_wave = `wave' + 1

    * Start by assuming this wave is not interesting.
    gen addr_change`wave' = .

    * If we have data in both waves, just compare HH members.
    replace addr_change`wave' = (SHHADID`wave' != SHHADID`next_wave') if ((!missing(SHHADID`wave')) & (!missing(SHHADID`next_wave')))

    * If we are moving from a wave in which ego is missing to one in which ego is present
    * there is an address change if we have seen the future SHHADID in the gap during which ego was missing
    * UNLESS this is ego's birth.
    * We also need to populate age and weight from the next wave since ego has no data in this wave.
    replace addr_change`wave' = 1 if ((missing(SHHADID`wave')) & (!missing(SHHADID`next_wave')) & (found_future_SHHADID_in_gap`wave' == 1))
    replace adj_age`wave' = adj_age`next_wave' if ((missing(SHHADID`wave')) & (!missing(SHHADID`next_wave')) & (found_future_SHHADID_in_gap`wave' == 1))
    replace WPFINWGT`wave' = WPFINWGT`next_wave' if ((missing(SHHADID`wave')) & (!missing(SHHADID`next_wave')) & (found_future_SHHADID_in_gap`wave' == 1))
    * Undo those changes if this is birth.
    replace addr_change`wave' = . if ((`next_wave' == my_first_wave) & (adj_age`next_wave' == 0))
    replace adj_age`wave' = . if ((`next_wave' == my_first_wave) & (adj_age`next_wave' == 0))
    replace WPFINWGT`wave' = . if ((`next_wave' == my_first_wave) & (adj_age`next_wave' == 0))

    * If we are moving from a wave in which ego is present to one in which ego is missing
    * there is an address change if we have seen the current SHHADID in the gap 
    * during which ego is missing as we look forward.
    replace addr_change`wave' = 1 if ((!missing(SHHADID`wave')) & (missing(SHHADID`next_wave')) & (found_prev_SHHADID_in_gap`next_wave' == 1))

    * If we are moving from a wave in which ego is present to one in which ego is missing
    * and we do not see the current SHHADID in the gap looking forward,
    * we compare the current SHHADID to the future SHHADID as if we move into the
    * future household in the first missing wave, unless there is no future SHHADID
    * (ego's last appearance).
    replace addr_change`wave' = (SHHADID`wave' != future_SHHADID`next_wave') if ((!missing(SHHADID`wave')) & (missing(SHHADID`next_wave')) & (!missing(future_SHHADID`next_wave')) & (found_prev_SHHADID_in_gap`next_wave' != 1))


    * Tab "original" addr_change and comp_change variables.
    tab addr_change`wave' comp_change`wave', m

    * We once forced them up to have the same denominator by setting to zero if missing and the other variable is not missing.
	* but this is not appropriate. Sometimes we can know if there was an address change even if we don't know household composition
	* Keeping this here to document.
*    replace addr_change`wave' = 0 if (missing(addr_change`wave') & (!missing(comp_change`wave')))
*    replace comp_change`wave' = 0 if (missing(comp_change`wave') & (!missing(addr_change`wave')))

*    tab addr_change`wave' comp_change`wave', m
}

gen original=1 if !missing(SHHADID1)
gen agewave1=adj_age1 if original==1

keep SSUID EPPPNUM SHHADID* adj_age* comp_change* addr_change* comp_change_reason* original agewave1

reshape long SHHADID adj_age comp_change addr_change comp_change_reason, i(SSUID EPPPNUM) j(SWAVE)

merge 1:1 SSUID EPPPNUM SWAVE using "$tempdir/demo_long_all.dta"

assert _merge==3

drop _merge

gen hh_change=comp_change
replace hh_change=1 if addr_change==1

gen inwave = !missing(ERRP)

gen insample=0
* Keep if in this wave and next
replace insample=1 if inwave==1 & innext==1
* also keep if hh_change is not missing. This would be (for example) if not in current wave, 
* but in next one and people you live with in next wave appear while ego is missing.
* hh_change also ==1 if in current wave and not in next, but some of the people 
* you are living with now appear in "next" wave while ego is missing.
* hh_change can =0 if not in next wave but in a subsequent one and everyone ego 
* is with in this wave is in the household in the next appearence
replace insample=2 if insample==0 & !missing(hh_change)

	label var comp_change_reason "Codes for whether comp_change is observed in adjascent waves or inferred"
    label values comp_change_reason comp_change_reason
	
	label var comp_change "Indicator for whether a composition change is observed or inferred"
	label values comp_change comp_change
	
	label var addr_change "Indicator for whether individual moved"
	label values addr_change addr_change

save "$SIPP08keep/hh_change.dta", $replace
