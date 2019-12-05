use "$SIPP2008\FullFile\sippp08putm2.dta", clear

keep ssuid epppnum shhadid erelat* eprlpn* tage

tab erelat01

 *******************************************************
 * rename variables to remove leading 0 for single digits
 
 forvalues p=1/9 {
  rename eprlpn0`p' eprlpn`p'
  rename erelat0`p' erelat`p'
 }

****************************************************
* count the number of other people in the household
*

gen countall=0
gen countother=0

 forvalues p=1/30 {
  replace countother=countother+1 if eprlpn`p' > 0 & erelat`p' !=99
  replace countall=countall+1 if eprlpn`p' > 0
 }
 
 tab countall 
 tab countother

rename epppnum relfrom

reshape long erelat eprlpn, i(ssuid relfrom) j(pn)

rename eprlpn relto

tab erelat

drop if relto < 0

rename ssuid SSUID
destring relfrom, replace

drop if relfrom==relto

save "$tempdir/relationship_matrix", $replace

use "$tempdir/relationship_pairs_bywave"

keep if SWAVE==2

merge 1:1 SSUID relto relfrom using "$tempdir/relationship_matrix"


putexcel set "$results/compare_relationships.xlsx", sheet(checkrels) modify

tab relationship erelat, matcell(checkrels)

putexcel C3=matrix(checkrels)


