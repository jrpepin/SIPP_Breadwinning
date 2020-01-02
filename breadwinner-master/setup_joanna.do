global replace "replace"

global logdir "$homedir/Dropbox\Repositories\SIPP_Breadwinning\DemographySupplement\stata_logs"
global tempdir "$homedir/Dropbox\Repositories\SIPP_Breadwinning\DemographySupplement\stata_data\stata_tmp"


global boxdir "C:\Users\joanna\Box Sync UT\Box Sync"
global projdir "$boxdir/SIPP/Results and Papers/breadwinner"
global projcode "C:\Users\Joanna\Dropbox\Repositories\SIPP_Breadwinning\breadwinner-master\2008"
global sipp2008_code "$projcode\SIPP2008"
global sipp2008_logs "C:\Users\joanna\logs\SIPP\2008"
* global SIPPshared "$projdir/data/shared"

global first_wave 1
global final_wave 15
global second_wave = ${first_wave} + 1
global penultimate_wave = ${final_wave} - 1

global demodata "C:\Users\Joanna\Dropbox\Repositories\SIPP_Breadwinning\DemographySupplement\stata_data"
