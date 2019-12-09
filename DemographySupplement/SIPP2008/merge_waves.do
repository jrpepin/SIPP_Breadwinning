//====================================================================//
//===== Children's Household Instability Project                    
//===== Dataset: SIPP2008                                           
//===== Purpose: This code append all waves of SIPP2008 original data into a long form dataset. 
//               It keeps only observations in the reference month (4).  
//=====================================================================//

** Import first wave. 
use "$SIPP2008/wave${first_wave}_extract", clear 

** Keep only observations in the reference month. 
keep if SREFMON == ${refmon}

** Append the first wave with waves from the second to last, also keep only observations from the reference month. 
forvalues wave = $second_wave/$final_wave {
    append using "$SIPP2008/wave`wave'_extract"
    keep if SREFMON == ${refmon} 
}

** allwaves.dta is a long-form datasets include all the waves from SIPP2008, month 4 data. 
save "$tempdir/allwaves", $replace
