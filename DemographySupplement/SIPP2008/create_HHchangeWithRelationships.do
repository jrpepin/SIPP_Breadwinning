//====================================================================//
//===== Children's Household Instability Project                    
//===== Dataset: SIPP2008                                           
//===== Purpose: This code merges a file with information on the relationship
//                 of household members who arrive or leave in the next wave                
//               to comp_change hh_change and addr_change. And then collapses
//               to an individual data file with dummy indicators of whether 
//               ego saw anyone leave, anyone arrive, a parent leave or arrive,
//               a sibling leave or arrive, anyone else leave or arrive.
//=====================================================================//

* hh_change has one record per person per wave
use "$SIPP08keep/hh_change.dta"

keep SSUID EPPPNUM SWAVE comp_change hh_change addr_change 

* changer_rels.dta has one record for every person arriving or leaving ego's 
* household between this wave and the next. There may be records for both 
* arrivers and leavers. An "arriver" might be someone that ego moves in with
* or someone who moves in with ego. Analogously, a leaver could be someone ego
* leaves ego's household or someone who ego leaves behind when she leaves.   

* changer_rels includes no records for individuals who experienced no composition change in the wave
* we get these records from hh_change.dta. Thus any variable we pull in with "changer_rels" is missing for everyone
* who did not experience a composition change. For example, adult_arrive is missing for everyone with comp_change==0
merge 1:m SSUID EPPPNUM SWAVE using "$tempdir/changer_rels", keepusing(relationship parent sibling grandparent nonrel other_rel foster allelse adult_arrive adult_leave parent_arrive parent_leave change_type)

* be sure that all cases with a comp_change were found in changer_rels
assert _merge==3 if comp_change==1

drop _merge

tab  relationship change_type, m

gen someoneleft=0 if !missing(comp_change)
gen someonearrived=0 if !missing(comp_change)

replace someonearrived=1 if change_type==1
replace someoneleft=1 if change_type==2

gen parent_change=1 if comp_change==1 & parent==1
gen sib_change=1 if comp_change==1 & sibling==1
gen other_change=1 if comp_change==1 & parent!=1 & sibling !=1
gen gp_change=1 if comp_change==1 & grandparent==1
gen nonrel_change=1 if comp_change==1 & nonrel==1
gen otherrel_change=1 if comp_change==1 & other_rel==1
gen foster_change=1 if comp_change==1 & foster==1 		// tiny
gen allelse_change=1 if comp_change==1 & allelse==1

collapse (max) comp_change parent_change sib_change other_change gp_change nonrel_change otherrel_change foster_change allelse_change adult_arrive adult_leave someonearrived someoneleft parent_arrive parent_leave, by(SSUID EPPPNUM SWAVE)

merge 1:1 SSUID EPPPNUM SWAVE using "$SIPP08keep/hh_change.dta"

drop _merge

* remove observations that are missing because of lack of interview and
* unable to infer comp_change. insample is generated at the end of create_hh_change.do
keep if insample !=0

local reltyp "parent sib other gp nonrel otherrel foster allelse"

* set relationship-specific composition change variables to 0 if comp_change is not missing and specific relationship type wasn't observed among the changers.
foreach r in `reltyp'{
	replace `r'_change=0 if missing(`r'_change) & !missing(comp_change)
}

assert parent_change==. if comp_change==.
assert parent_change==0 if comp_change==0
assert other_change==. if comp_change==.
assert other_change==0 if comp_change==0

replace adult_arrive=0 if missing(adult_arrive) & !missing(comp_change)
replace adult_leave=0 if missing(adult_leave) & !missing(comp_change)

replace parent_arrive=0 if missing(parent_arrive) & !missing(comp_change)
replace parent_leave=0 if missing(parent_leave) & !missing(comp_change)

gen otheradult_arrive=1 if  comp_change==1 & adult_arrive==1 & parent_arrive==0
gen otheradult_leave=1 if  comp_change==1 & adult_leave==1 & parent_leave==0

replace otheradult_arrive=0 if missing(otheradult_arrive) & !missing(comp_change)
replace otheradult_leave=0 if missing(otheradult_leave) & !missing(comp_change)

save "$SIPP08keep/HHchangeWithRelationships.dta", $replace


