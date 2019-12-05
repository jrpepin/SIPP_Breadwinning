preserve 
keep ssuid epppnum shhadid rfid swave altpearn althearn thearn abw50 
drop if abw50!=.
save "C:\Users\Joanna\Dropbox\Repositories\SIPP_Breadwinning\data\trouble.dta", replace
restore


preserve 
keep ssuid epppnum shhadid rfid swave tpearn thearn ratio
save "C:\Users\Joanna\Dropbox\Repositories\SIPP_Breadwinning\data\trouble2.dta", replace
restore
