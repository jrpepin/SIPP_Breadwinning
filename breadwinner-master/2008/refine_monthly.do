use "$SIPP2008\sipp08tpearn_all", clear

* doing my best to reconstruct tpearn
* starting by summing up reported earnings
cap drop altpearn
gen altpearn=tpmsum1 if !missing(tpmsum1)             // income from job 1
replace altpearn=altpearn+tpmsum2 if !missing(tpmsum2) // income from job 2
replace altpearn=altpearn+tbmsum1 if !missing(tbmsum1) // income from business 1
replace altpearn=altpearn+tbmsum2 if !missing(tbmsum2) // income from business 2
replace altpearn=altpearn+tmlmsum

local allocate "abmsum1 abmsum2 apmsum1 apmsum2 amlmsum"

gen anyallocate=0
foreach var in `allocate'{
	replace anyallocate=1 if `var' !=0
}

tab anyallocate

* set ualtpearn to missing if it is based on allocated data
gen ualtpearn=altpearn
replace ualtpearn=. if anyallocate==1

* accounting for business losses
gen profit=tprftb1 if !missing(tprftb1)
replace profit=profit+tprftb2 if !missing(tprftb1)

* create measures of household and family income
* Note that aggregating tpearn instead of altpearn replicates
* thearn and tfearn. 
egen althearn=total(altpearn), by(ssuid shhadid swave)
egen altfearn=total(altpearn), by(ssuid shhadid rfid swave)

egen ualthearn=total(ualtpearn), by(ssuid shhadid swave)
egen ualtfearn=total(ualtpearn), by(ssuid shhadid rfid swave)

/* JP -- I don't think this part is necessary. Already unallocated based on ualtpearn
egen anyalloh=total(anyallocate), by(ssuid shhadid swave)
replace ualthearn=. if anyalloh > 0

tab anyalloh

label variable anyalloh "any allocated earnings data for household"
*/

gen negearn=1 if tpearn < 0

gen samepearn=1 if altpearn==tpearn 
gen samefearn=1 if altfearn==tfearn 
gen samehearn=1 if althearn==thearn

local same "samepearn samefearn samehearn"

foreach var in `same'{
	tab `var', m
}

gen diffpearn=altpearn-tpearn
gen diffhearn=althearn-thearn
gen difffearn=altfearn-tfearn

sum diffpearn diffhearn difffearn, detail

* bw50 is missing if thearn is negative
gen bw50=1 if tpearn/thearn >= .50 & thearn > 0
replace bw50=0 if tpearn/thearn < .5 & thearn > 0

gen     abw50=1 if altpearn/althearn >= .50 & thearn > 0
replace abw50=0 if altpearn/althearn <  .5  & thearn > 0

recode eeducate (-1=-1)(31/38=1)(39=2)(40/43=3)(44/47=4), gen(educ)

label define educ -1 "not in universe" 1 "< HS" 2 "HS Grad" 3 "Some College" 4 "College Grad"
label values educ educ

save "$tempdir/altearn.dta", $replace

gen ratio=tpearn/thearn & thearn > 0

sum bw50 abw50 ratio, detail
