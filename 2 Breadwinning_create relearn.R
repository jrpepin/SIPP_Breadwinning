#####################################################################################
# Set-up the environment
## Load the libraries
library(haven)
library(tidyverse)

## Open the data
setwd(dataDir)
sippp08putm2 <- read_dta("sippp08putm2.dta") # Import the downloaded data file.

setwd(repoDir)

## Select Variables
hhdata <- select(sippp08putm2, ssuid, epppnum, tfmyear, tfsyear, tftyear, 
                 tsmyear, tssyear, tstyear, tlmyear, tlsyear, tltyear, 
                 tfbrthyr, exmar, ewidiv1, ewidiv2, ems, esex, tmomchl, tage) %>%
          filter(esex == 2)

### Create a sample dataset to tryout code.
sample <- hhdata[sample(nrow(data), 500), ]

#####################################################################################
# Identify mothers

# tmomchl -- Number of children resp. has ever given birth to
# tlmyear -- Year of last marriage
# exmar   -- Number of times married in lifetime
# tfmyear -- Edited year of first marriage: All persons aged 15+ who have been married at least twice. 

hhdata$anybirth <- 0
hhdata$anybirth[hhdata$tmomchl == 1] <- 1 ###   WHY ARE WE IDENTIFYING ONLY MOTHERS WHO HAVE GIVEN BIRTH 1 TIME? WHY NOT ALL MOTHERS?

hhdata <- hhdata %>%
  mutate(
    yrmar1 = case_when(
      exmar == 1 ~ tlmyear,
      exmar >  1 ~ tfmyear,
      exmar <  1 ~ 999))



replace msbirth=0 if ems==6 // never married
replace msbirth=0 if tfbrthyr < yrmar1 & tfbrthyr > 0 // birth happened before first marriage
replace msbirth=1 if tfbrthyr >= yrmar1 // birth happened after (or year of) first marriage
replace msbirth=9 if anybirth==0

hhdata$msbirth <- NA
hhdata$msbirth[hhdata$tage     >= 65]                                  <- -1
hhdata$msbirth[hhdata$ems      == 6]                                   <- 0 # never married
hhdata$msbirth[hhdata$tfbrthyr <  hhdata$yrmar1 & hhdata$tfbrthyr > 0] <- 0 # birth happened before first marriage
hhdata$msbirth[hhdata$tfbrthyr >= hhdata$yrmar1]                       <- 1 # birth happened after (or year of) first marriage
hhdata$msbirth[hhdata$anybirth == 0]                                   <- 9 

## Convert epppnum to match data
hhdata$epppnum <- as.integer(hhdata$epppnum)