*** We also need a dataset of reference persons.
use "$tempdir/allwaves"
keep ssuid epppnum shhadid errp esex swave eeducate
keep if ((errp == 1) | (errp == 2))
drop errp

recode eeducate (31/38 = 1)  (39 = 2)  (40/43 = 3)  (44/47 = 4), gen (educ)

rename epppnum ref_person
rename esex ref_person_sex
rename educ ref_person_educ

label values ref_person_educ educ

drop eeducate

duplicates drop
save "$tempdir/ref_person_long", $replace

reshape wide ref_person ref_person_sex ref_person_educ, i(ssuid shhadid) j(swave)
save "$tempdir/ref_person_wide", $replace
