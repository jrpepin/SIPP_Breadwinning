* This file extracts the needed data from the NBER core data files and formats 
* them for this project, which originally used a data file extracted directly 
* from Census using data ferrett (with capitalized variable names, for example)


/* We first create an extract from the wave 2 topical module that will be merge 
later to the other waves. This TM contains information on migration for all the
individuals in the household ages 15 or older. 
*/

clear 
use "$SIPP2008tm/sippp08putm2"
keep ssuid epppnum tmoveus tbrstate 
save "$SIPP2008/wave2_migration_extract", $replace

* Core questions:
forvalues wave=1/15{
	clear
	use "$SIPP2008core/sippl08puw`wave'"
	keep tftotinc thtotinc tfipsst ebornus ems eorigin epndad epnmom epnspous ///
	erace errp esex etypdad etypmom tage uentmain ulftmain ehhnumpp eoutcome ///
	rhchange rhnf thtotinc eentaid eppintvw epppnum lgtkey tmovrflg rhcalyr ///
	shhadid srefmon srotaton ssuseq swave wpfinwgt eeducate ssuid renroll ///
	eenrlm eenlevel
	
	merge m:1 ssuid epppnum using "$SIPP2008/wave2_migration_extract"
	drop if _merge==2
	drop _merge
	
	destring eentaid, replace
	destring epppnum, replace
	destring lgtkey, replace
	rename *, upper

	save "$SIPP08/wave`wave'_extract", $replace
}
