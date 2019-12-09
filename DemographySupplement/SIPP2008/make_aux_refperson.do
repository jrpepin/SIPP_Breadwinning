*** We also need a dataset of reference persons.
use "$tempdir/allwaves"
keep SSUID EPPPNUM SHHADID ERRP ESEX SWAVE EEDUCATE
keep if ((ERRP == 1) | (ERRP == 2))
drop ERRP

recode EEDUCATE (31/38 = 1)  (39 = 2)  (40/43 = 3)  (44/47 = 4), gen (educ)

rename EPPPNUM ref_person
rename ESEX ref_person_sex
rename educ ref_person_educ

label values ref_person_educ educ

drop EEDUCATE

duplicates drop
save "$tempdir/ref_person_long", $replace

reshape wide ref_person ref_person_sex ref_person_educ, i(SSUID SHHADID) j(SWAVE)
save "$tempdir/ref_person_wide", $replace
