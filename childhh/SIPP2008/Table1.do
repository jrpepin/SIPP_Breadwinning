* For Table 1 of HHstability paper
* Run do_childrens_household_core (or at least project_macros) before executing.

use "$SIPP08keep/HHComp_asis", clear

keep if adj_age < $adult_age

tab relationship [aweight=WPFINWGT]

gen bioparent=1 if relationship==1
gen parent=1 if inlist(relationship,1,4,7,19,21)
gen sibling=1 if inlist(relationship, 17)
gen child=1 if inlist(relationship,2,3,5,6,8,9,10,11,22,23)
gen spartner=1 if inlist(relationship,12,18)
gen nonrel=1 if inlist(relationship,20,22,34,37,38,40)
gen grandparent=1 if inlist(relationship,13,14,27)
gen other_rel=1 if inlist(relationship, 15,16,24,25,26,28,29,30,31,33,32,35,36) //not parents, siblings, children, spouses, or grandparents
gen unknown=1 if relationship==40 | missing(relationship)
gen nonnuke=1 if nonrel==1 | grandparent==1 | other_rel==1 | unknown==1 
gen allelse=1 if inlist(relationship,2,3,5,6,8,9,10,11,23,12,18) // children, spouses

gen extended_kin=1 if grandparent==1 | other_rel==1

local rellist "bioparent parent sibling  child spartner nonrel grandparent other_rel extended_kin unknown nonnuke"

collapse (count) `rellist', by (SSUID EPPPNUM SWAVE) fast

merge 1:1 SSUID EPPPNUM SWAVE using "$tempdir/demo_long_interviews.dta", keepusing(WPFINWGT my_racealt adj_age my_sex biomom_ed_first par_ed_first ref_person_educ mom_measure)

keep if _merge==3

drop _merge

gen weight=int(WPFINWGT*10000)

tab adj_age par_ed_first

foreach v in `rellist'{
 tab `v' [fweight=weight]
 }
 
 recode nonnuke (0=0)(1/20=1), gen(anynonuke)
 recode nonrel (0=0)(1/20=1), gen(anynonrel)
 recode grandparent (0=0)(1/20=1), gen(anygp)
 recode other_rel (0=0)(1/20=1), gen(anyother)
 recode extended_kin (0=0)(1/20=1), gen(anyextended)
 recode unknown (0=0)(1/20=1), gen(anyunknown)

label variable anynonuke "non-nuclear kin or non-relative"
label variable anynonrel "non-relative"
label variable anygp "grandparent"
label variable anyother "non-nuclear non-grandparent kin"
label variable anyunknown "unknown relation"
label variable anyextended "any extended kin"

#delimit ;
label define yesno  0 "no"
                    1 "yes";
#delimit cr 

local anyrel "anynonuke anynonrel anygp anyother anyextended anyunknown"

label variable my_racealt "Race-Ethnicity"

foreach v in `anyrel'{
label values `v' yesno
tab `v' 
}

* Setup to put output in document

	putdocx begin
	
	// Create a paragraph
	putdocx paragraph
	putdocx text ("How often do children live with non-nuclear household members"), bold
	putdocx paragraph
	putdocx text ("We used measures of the relationship of each person in a ")
	putdocx text ("child's household to create indicators of whether anyone ")
	putdocx text ("was a non-nuclear member (i.e. not a parent or a sibling), ")
	putdocx text ("a non-relative, a grandparent other relative, or an unknown relation. ")
	putdocx text ("Note that any non-nuclear member includes non-relatives, ")
	putdocx text ("grandparents, other relatives, and unknown relations, ") 
	putdocx text ("but other relative does not include grandparent. ")
	putdocx text ("Table can be found in Table1b.csv")
	
	putdocx save "$results/Table1a.docx", replace

	*/

tabout anynonuke anynonrel anygp anyother anyextended anyunknown my_racealt [aweight=WPFINWGT] using "$results/Table1b.csv", replace ///
cells(col) ///
clab(_ _ _) ///
layout(rb) ///
h1( | White | Black | Hispanic | Asian | Other | Total ) h2(nil) ///
style(csv)
	
tabout anynonuke anynonrel anygp anyother anyextended anyunknown par_ed_first [aweight=WPFINWGT] using "$results/Table1b.csv", append ///
cells(col) ///
clab(_ _ _) ///
layout(rb) ///
h1( | < HS | High School | Some College | College Grad | Total ) h2(nil) h3(nil) ///
style(csv)	
	

tab my_racealt, m
tab par_ed_first, m
tab mom_measure, m

duplicates drop SSUID EPPPNUM, force

tab my_racealt, m
tab par_ed_first, m
tab mom_measure, m



