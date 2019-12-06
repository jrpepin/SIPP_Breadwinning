//=================================================================================//
//====== Children's Household Instability Project                          
//====== Dataset: SIPP2008                                               
//====== Purpose: Creates sub-databases: shhadid_members.dta, ssuid_members_wide.dta
//====== ssuid_shhadid_wide.dta, person_pdemo (parents demographics), partner_of_ref_person_long (and wide)
//=================================================================================//


//================================================================================//
//== Purpose: Make the shhadid member database with a single string variable 
//== containing a list of all epppnums in a household in a wave. This file will also 
//== be used for normalize ages and so it includes a string variable with list of 
//== all ages of household members with epppnum.
//================================================================================//
use "$tempdir/allwaves"

local i_vars "ssuid shhadid" 
local j_vars "swave"

keep `i_vars' `j_vars' epppnum tage
sort `i_vars' `j_vars' epppnum tage

by `i_vars' `j_vars':  gen hhmemnum = _n  /* Number the people in household in each wave. */

egen maxpnum = max(hhmemnum) /* max n of people in household in any wave. */
local maxpn = `=maxpnum' /* to use below in forvalues loop */

*******************************************************************************
** Section: Generate a horizontal list of people in the household at each wave.
*******************************************************************************

* Create for_concat* variables equal to string value of pn's epppnum for for_contact_*[pn] and missing otherwise
* and for_concat_age_* variables equal to string value of tage-epppnum
forvalues pn = 1/`maxpn' {
    gen for_concat_person`pn' = epppnum if (hhmemnum == `pn')
}

drop hhmemnum

* Collapse by address (ssuid shhadid) to take the first non-missing value of the 
* variables we built above. Note that there is exactly one non-missing -- 
* only the nth person in the household in this wave got a value set for variable #n.

keep `i_vars' `j_vars' for_concat_person* 

collapse (firstnm) for_concat_person* , by (`i_vars' `j_vars')

* Concatenate all for_concat* variables into a single string where each person number is separated by a blank.
egen shhadid_members = concat(for_concat_person*), punct(" ")

* clean up
drop for_concat_person* 

* Strip out extra spaces.
replace shhadid_members = strtrim(shhadid_members)

* Add a space at the beginning and end of the string to make sure every person appears surrounded by spaces.
replace shhadid_members = " " + shhadid_members + " "

********************************************************************
** Section: Compute number of household members by wave and overall.
********************************************************************
sort swave
gen n_shhadid_members = wordcount(shhadid_members)
by swave:  egen max_shhadid_members = max(n_shhadid_members)
egen overall_max_shhadid_members = max(n_shhadid_members)
drop n_shhadid_members

compress 

macro drop i_vars j_vars 

save "$tempdir/shhadid_members", $replace

//================================================================================//
//== Purpose: Make the ssuid member database
//== The logic is similar for the shhadid database, but here we are going to collapse
//== by sample unit (ssuid) instead of address (ssuid shhadid) to create variables
//== describing number of sample unit members across all waves
//================================================================================//

use "$tempdir/allwaves"

local i_vars "ssuid"
local j_vars "swave"

keep `i_vars' `j_vars' epppnum
sort `i_vars' `j_vars' epppnum

by `i_vars' `j_vars':  gen hhmemnum = _n  /* Number the people in the sampling unit in each wave. */

egen maxpnum = max(hhmemnum) /* max n of people in sampling unit in any wave. */
local maxpn = `=maxpnum' /* to use below in forvalues loop */

*******************************************************************
** Section: Generate a horizontal list of people in the ssuid (original sampling unit).
********************************************************************

* Create for_concat* variable equal to string value of pn's epppnum for for_contact_*[pn] and missing otherwise
forvalues pn = 1/`maxpn' {
    gen for_concat_person`pn' = epppnum if (hhmemnum == `pn')
}

drop hhmemnum

keep `i_vars' `j_vars' for_concat_person*

* Collapse to take the first non-missing of the variables we built above.  
* There is exactly one non-missing -- only the nth person in the household in this wave got a value set for variable #n.
collapse (firstnm) for_concat_person*, by (`i_vars' `j_vars')

*Concatenate all person-numbers into a single string.
egen ssuid_members = concat(for_concat_person*), punct(" ")

drop for_concat_person*

* Strip out extra space to save space.
replace ssuid_members = strtrim(ssuid_members)

* Add a space at the beginning and end of the string so we are sure every person appears surrounded by spaces.
replace ssuid_members = " " + ssuid_members + " "

* Compute max number of members by wave and overall.
sort swave
gen n_ssuid_members = wordcount(ssuid_members)
by swave:  egen max_ssuid_members = max(n_ssuid_members)
egen overall_max_ssuid_members = max(n_ssuid_members)
drop n_ssuid_members

compress 

reshape wide ssuid_members max_ssuid_members, i(`i_vars') j(`j_vars')

macro drop i_vars j_vars

save "$tempdir/ssuid_members_wide", $replace

//================================================================================//
//== Purpose: Make the ssuid shhadid database with information on the number of addresses (shhadid)
//== in the sampling unit (ssuid) in each wave and overall.
//================================================================================//

use "$tempdir/allwaves"

local i_vars "ssuid"
local j_vars "swave"

keep `i_vars' `j_vars' shhadid
sort `i_vars' `j_vars' shhadid
duplicates drop


by `i_vars' `j_vars':  gen anum = _n /* Number the addresses in the household for each wave. */

* maximum number of addresses in any household in any wave.
egen maxanum = max(anum)
local maxan = `=maxanum'

*******************************************************************
** Section: Generate a horizontal list of addresses in the ssuid (original sampling unit).
********************************************************************

* Create for_concat* variable equal to string value of address's shhadid for for_contact_*[an] and missing otherwise
forvalues an = 1/`maxan' {
    gen for_concat_address`an' = string(shhadid) if (anum == `an')
}

drop anum

keep `i_vars' `j_vars' for_concat_address* 

* Collapse to take the first non-missing of the variables we built above.  
* There is exactly one non-missing -- only the nth address in the household in this wave got a value set for variable #n.
collapse (firstnm) for_concat_address*, by (`i_vars' `j_vars')


*Concatenate all "addresses" into a single string.
egen ssuid_shhadid = concat(for_concat_address*), punct(" ")

drop for_concat_address*

* Save space by stripping out extra spaces.
replace ssuid_shhadid = strtrim(ssuid_shhadid)

* Add a space at the beginning and end of the string so we are sure every person appears surrounded by spaces.
replace ssuid_shhadid = " " + ssuid_shhadid + " "

* Compute max number of addresses by wave and overall.

sort swave
gen n_ssuid_shhadid = wordcount(ssuid_shhadid)
by swave:  egen max_ssuid_shhadid = max(n_ssuid_shhadid)
egen overall_max_ssuid_shhadid = max(n_ssuid_shhadid)
drop n_ssuid_shhadid

compress 

reshape wide ssuid_shhadid max_ssuid_shhadid, i(`i_vars') j(`j_vars')

macro drop i_vars j_vars

save "$tempdir/ssuid_shhadid_wide", $replace

//================================================================================//
//== Purpose: Create a dataset with education, immigration status, and age for merging 
//== Logic: Rename epppnum to later merge onto person number of mother (EPNMOM) 
//==        and father (EPNDAD) to get parents' educ and immigration status in the analysis dataset.
//================================================================================//

use "$tempdir/allwaves"

local i_vars "ssuid epppnum"
local j_vars "swave"


keep `i_vars' `j_vars' eeducate ebornus tage
sort `i_vars' `j_vars' eeducate ebornus tage


** Label recoded education.
#delimit ;
label define educ   1 "lths"
                    2 "hs"
                    3 "ltcol"
                    4 "coll";
#delimit cr

recode eeducate (31/38 = 1)  (39 = 2)  (40/43 = 3)  (44/47 = 4), gen (educ)
label values educ educ

recode ebornus (1 = 0)  (2 = 1) , gen (immigrant)

drop eeducate ebornus

* demo_epppnum will be key to merge with epnmom and epndad to get parent education onto
* ego's record
destring epppnum, gen(pdemo_epppnum)
drop epppnum

rename tage page /* page for "parent age" */

save "$tempdir/person_pdemo", $replace

* create a dataset of household reference persons.
do "$childhh_base_code/SIPP2008/make_aux_refperson"

