//====================================================================//
//===== Children's Household Instability Project                    
//===== Dataset: SIPP2008                                           
//===== Purpose: This code append all waves of SIPP2008 original data into a long form dataset. 
//               It keeps only observations in the reference month (4).  
//=====================================================================//

** Import first wave. 
use "$SIPP2008/sippl08puw${first_wave}", clear 

** Keep only observations in the reference month. 
keep if srefmon == ${refmon}

** Append the first wave with waves from the second to last, also keep only observations from the reference month. 
forvalues wave = $second_wave/$final_wave {
    append using "$SIPP2008/sippl08puw`wave'"
    keep if srefmon == ${refmon} 
}

** allwaves.dta is a long-form datasets include all the waves from SIPP2008, month 4 data. 
save "$tempdir/allwaves", $replace
