* Set up the base ChildHH (Children's Households) environment.

* The current directory is assumed to be the one with the base ChildHH code.
cd "C:\Users\Joanna\Dropbox\Repositories\SIPP_Breadwinning\DemographySupplement"

* We expect to find your setup file, named setup_<username>.do
* in the base ChildHH directory (as defined above).


* Find my home directory, depending on OS.
if ("`c(os)'" == "Windows") {
    local temp_drive : env HOMEDRIVE
    local temp_dir : env HOMEPATH
    global homedir "`temp_drive'`temp_dir'"
    macro drop _temp_drive _temp_dir`
}
else {
    if ("`c(os)'" == "MacOSX") {
        global homedir : env HOME
    }
    else {
        display "Unknown operating system:  `c(os)'"
        exit
    }
}

*global childhh_base_code "`c(pwd)'"

do setup_`c(username)'

