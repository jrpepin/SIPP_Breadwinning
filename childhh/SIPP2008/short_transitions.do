/*Our core analysis and code are based on the 4th reference months in each wave. 
This mean that people who lived in the household for a short period of time between 
the two refernece months are not counted. The code below aims to estimate the effect 
of this potemtial bias, by comparing wave 1 and 2 using 5 reference months: 
4th month of wave 1 and the four reference months of wave 2.*/


*Create a dataset with the five reference months:
use "$SIPP2008/wave1_extract.dta", clear
keep if SREFMON==4
g ref=1 
drop SWAVE
save "$tempdir/ref1.dta", replace

forvalue r=1/4{
local x=`r'+1
use "$SIPP2008/wave2_extract.dta", clear
keep if SREFMON==`r'
g ref=`x'
drop SWAVE
save "$tempdir/ref`x'.dta", replace
}

use "$tempdir/ref1.dta", clear
forvalue r=2/5 {
append using "$tempdir/ref`r'.dta"
}
save "$tempdir/long_5months.dta", replace


/*Excluding household that were only interviewed in wave 1- only if the entire original household 
was not interviewed again in wave 2*/
use "$tempdir/ref1.dta", clear
keep SSUID 
duplicates drop
merge 1:m SSUID using "$tempdir/ref5.dta"
keep if _merge==1
keep SSUID 
merge 1:m SSUID using "$tempdir/long_5months.dta"
drop if _merge==3
drop _merge
save "$tempdir/long_5months.dta", replace

*Adding variable of householder id:
keep if ERRP==1 | ERRP==2
g hholder=EPPPNUM 
keep SSUID SHHADID ref hholder 
merge 1:m SSUID SHHADID ref using "$tempdir/long_5months.dta"
drop _merge
save "$tempdir/long_5months.dta", replace


*Householder's education:
local i_vars "SSUID EPPPNUM"
local j_vars "ref"

keep `i_vars' `j_vars' EEDUCATE 

** Label recoded education.
#delimit ;
label define educ   1 "lths"
                    2 "hs"
                    3 "ltcol"
                    4 "coll";
#delimit cr

recode EEDUCATE (31/38 = 1)  (39 = 2)  (40/43 = 3)  (44/47 = 4), gen (educ)
label values educ educ

drop EEDUCATE 

*merge with orignal:
rename EPPPNUM hholder
merge 1:m SSUID hholder `j_vars' using "$tempdir/long_5months.dta"
keep if _merge==3
drop _merge
save "$tempdir/long_5months.dta", replace

 
/*Generate a horizontal list of people in the household at each wave. Based on 
"make_auxiliary_dataset.do" 
*/

use "$tempdir/long_5months.dta", clear

local i_vars "SSUID SHHADID" 
local j_vars "ref"

keep `i_vars' `j_vars' EPPPNUM TAGE
sort `i_vars' `j_vars' EPPPNUM TAGE

by `i_vars' `j_vars':  gen pnum = _n  /* Number the people in the household in each wave. */

egen maxpnum = max(pnum) /* max n of people in any household in any wave. */
local maxpn = `=maxpnum' /* to use below in forvalues loop */

*******************************************************************
** Section: Generate a horizontal list of people in the household at each wave.
********************************************************************
* Create for_concat_person variables equal to string value of pn's EPPPNUM for for_contact_*[pn] and missing otherwise
* and for_concat_age_* variables equal to string value of TAGE-EPPPNUM
forvalues pn = 1/`maxpn' {
    gen for_concat_person`pn' = string(EPPPNUM) if (pnum == `pn')
   }

drop pnum

* Collapse to take the first non-missing of the variables we built above.  
* There is exactly one non-missing -- only the nth person in the household in this wave got a value set for variable #n.
keep `i_vars' `j_vars' for_concat_person* 

collapse (firstnm) for_concat_person*, by (`i_vars' `j_vars')

* Concatenate all for_concat* variables into a single string where each person number is separated by a blank.
egen shhadid_members = concat(for_concat_person*), punct(" ")
drop for_concat_person* 

* Strip out extra spaces.
replace shhadid_members = strtrim(shhadid_members)

* Add a space at the beginning and end of the string to make sure every person appears surrounded by spaces.
replace shhadid_members = " " + shhadid_members + " "

*merge to the orignal file:
merge 1:m `i_vars' `j_vars' using "$tempdir/long_5months.dta"
drop _merge

*Reshape to wide format- will unable us to compare compositions
keep SSUID EPPPNUM ref shhadid_members 
reshape wide shhadid_members, i(SSUID EPPPNUM) j(ref)

/*Comp change- by reference months (ref1 to ref5) and by waves (ref1 & ref5)
If the household composition is not the same as in the previous month/wave:*/
forvalue ref=1/4{
local nextref=`ref'+1
g compchange_ref`ref'= (shhadid_members`ref'!=shhadid_members`nextref')
}
g compchange_wave=(shhadid_members1!=shhadid_members5)


*reshape to long and merge with original file for analysis:
reshape long shhadid_members compchange_ref, i(SSUID EPPPNUM compchange_wave) j(ref)
merge 1:1 SSUID EPPPNUM ref using "$tempdir/long_5months.dta"
keep if _merge==3
drop _merge

/*Analysis- number of composition changes by reference months and waves: 
In order to get the final number of transition we need to multiple the reference 
month transition rates by 12 and the wave transition rates by 3 and sum them*/
ta TAGE compchange_ref [aweight=WPFINWGT] if TAGE<=16 /*Reference months*/
ta TAGE compchange_wave [aweight=WPFINWGT] if TAGE<=16 & ref==1 /*Waves*/
