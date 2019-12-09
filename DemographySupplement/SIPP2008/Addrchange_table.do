* Creates an excel spreadsheet with tables for estimates of address change for total and by race-ethnicity and by householder education

putexcel set "$results/HHChange.xlsx", sheet(addrchangeRaw) modify

tab adj_age addr_change [aweight=WPFINWGT], matcell(agerels)

putexcel A1="Table A2. Address Change by Race-Ethnicity and Parental Education"
putexcel A2=("Age") B2=("Total") E2=("By Race-Ethnicity") H2=("By Parental Education")
putexcel B3=("No Change") C3=("Change") D3=("Annual Rate")
putexcel B4=matrix(agerels)

forvalues a=1/18 {
   local rw=`a'+3
   putexcel D`rw'=formula(+3*C`rw'/(B`rw'+C`rw'))
 }
   putexcel D22=formula(SUM(D4:D21))
   
local racegroups "NHWhite Black NHAsian NHOther Hispanic"

putexcel E3=("No Change") F3=("Change") G3=("Annual Rate")

forvalues r=1/5 {
  local rw=(`r'-1)*19+4
  tab adj_age addr_change [aweight=WPFINWGT] if my_racealt==`r', matcell(agerace`r')
  putexcel E`rw'=matrix(agerace`r')
  forvalues a=1/18 {
	local arw=`rw'+`a'-1
	putexcel G`arw'=formula(+3*F`arw'/(E`arw'+F`arw'))
  }
  local s=`arw'+1
  local t=`arw'-17
  putexcel G`s'=formula(SUM(G`t':G`arw'))
 }

putexcel H3=("No Change") I3=("Change") J3=("Annual Rate")

forvalues e=1/4 {
  local rw=(`e'-1)*19+4
  tab adj_age addr_change [aweight=WPFINWGT] if par_ed_first==`e', matcell(ageeduc`e')
  putexcel H`rw'=matrix(ageeduc`e')
  forvalues a=1/18 {
	local arw=`rw'+`a'-1
	putexcel J`arw'=formula(+3*I`arw'/(H`arw'+I`arw'))
  }
  local s=`arw'+1
  local t=`arw'-17
  putexcel J`s'=formula(SUM(J`t':J`arw'))
}
