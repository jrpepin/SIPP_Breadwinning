#####################################################################################
# Create Household Composition variables and merge earnings and income data to hh_change data files

#####################################################################################
# Set-up the environment
## Load the libraries
library(haven)
library(tidyverse)

## Note that parts of this script is created using data created from the DemographySupplement (see breadwinning.Rmd)

### This points to where your demography supplement processed data was saved.
demoDir1 <- "C:/Users/Joanna/Dropbox/Repositories/SIPP_Breadwinning/DemographySupplement/stata_data/SIPP08_Processed" 

### This points to where your demography supplement temporary data was saved.
demoDir2 <- "C:/Users/Joanna/Dropbox/Repositories/SIPP_Breadwinning/DemographySupplement/stata_data/stata_tmp"

#####################################################################################
# Section: Create an extract with year of first birth and marital history

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

## Identify mothers

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

#####################################################################################
# Section: Create Household Composition variables

## Note that this file is created using code from the childhh project.
## run do_childrens_household_core to create. (see DemographySupplement)
## The file has one observation per person in ego's (EPPPNUM's) household. 
## It does not include a record for self and thus does not include people living alone.
asis <- read_dta(paste0(demoDir1, "/HHComp_asis.dta"))

# Create a dummy indicator for whether ego is a mother to anyone in the household
# by collapsing all records for same person (ssuid epppnum swave)

asis$nmomto <- ifelse(asis$relationship %in% c(2,5,8), 1, 0)
asis$nmomto[asis$relationship == 22 & asis$my_sex ==2] <- 1
asis$nmomto[asis$relationship == 23 & asis$my_sex ==2] <- 1

asis$nmomtominor <- ifelse(asis$relationship %in% c(2,5,8) & asis$to_age < 18, 1, 0)
asis$nmomtominor[asis$relationship == 22 & asis$to_age < 18 & asis$my_sex ==2] <- 1
asis$nmomtominor[asis$relationship == 23 & asis$to_age < 18 & asis$my_sex ==2] <- 1

asis$nbiomomto <- ifelse(asis$relationship ==2 & !is.na(asis$relationship), 1, 0)

### Create indicators for other aspects of household composition
asis$HHsize <- 1

asis$nHHkids <- 0
asis$nHHkids[asis$adj_age < 18] <- 1

### age of oldest son or daughter in the household
asis$agechild <- NA
asis$agechild <- ifelse(asis$relationship %in% c(2,3,8,22,23), asis$to_age, asis$agechild)

### spouse or partner
asis$spouse  <- ifelse(asis$relationship ==12 & !is.na(asis$relationship), 1, 0)
asis$partner <- ifelse(asis$relationship ==18 & !is.na(asis$relationship), 1, 0)
asis$spartner_pnum <- ifelse(asis$relationship %in% c(12, 18), asis$to_EPPNUM, NA)


### collapse across all people in ego's (EPPPNUM's) household to create a person-level file
  ### with information on that person's household composition in the wave.
count <- asis %>%
  select(SSUID, EPPPNUM, SHHADID, SWAVE, nmomto, nmomtominor, nbiomomto, HHsize, nHHkids, spouse, partner) %>%
  group_by(SSUID, EPPPNUM, SHHADID, SWAVE) %>% 
  summarise_all(list(~sum(.)))

maxmin <- asis %>%
  select(SSUID, EPPPNUM, SHHADID, SWAVE, agechild, spartner_pnum) %>%
  group_by(SSUID, EPPPNUM, SHHADID, SWAVE) %>% 
  summarize(agechild = max(agechild, na.rm = TRUE),
            spartner_pnum = min(spartner_pnum, na.rm = TRUE))

asis_pl <- reduce(list(count, maxmin), 
               left_join, by = c("SSUID", "EPPPNUM", "SHHADID", "SWAVE"))

asis_pl$agechild[asis_pl$agechild == "-Inf"] <- NA
asis_pl$spartner_pnum[asis_pl$spartner_pnum == "Inf"] <- NA

names(asis_pl)[names(asis_pl) == "agechild"] <- "ageoldest"

### some (9) have more than one person in the household coded as partner. 
asis_pl$partner[asis_pl$partner > 0] <- 1

### a small number (26) have both a spouse and a partner in the household.
asis_pl$spartner <- NA
asis_pl$spartner[asis_pl$spouse == 0 & asis_pl$partner == 0] <- 0
asis_pl$spartner[asis_pl$spouse == 1] <- 1
asis_pl$spartner[asis_pl$spouse == 0 & asis_pl$partner == 1] <- 2

### add in self as a household member.
asis_pl$HHsize <- asis_pl$HHsize + 1 # Will fix the HH living alone later.

### Select variables
asis_pl <- asis_pl %>%
  select(SSUID, EPPPNUM, SHHADID, SWAVE, 
         nmomto, nmomtominor, nbiomomto, 
         HHsize, nHHkids, spartner, ageoldest, spartner_pnum)

#####################################################################################
# Section: merging to children's households long demographic file, 
# a person-level data file, to get basic demographic information about ego.

demo <- read_dta(paste0(demoDir2, "/demo_long_interviews.dta"))

withdem <- reduce(list(asis_pl, demo), 
                  full_join, by = c("SSUID", "EPPPNUM", "SWAVE"))

names(withdem)[names(withdem) == "SSUID"]   <- "ssuid"
names(withdem)[names(withdem) == "EPPPNUM"] <- "epppnum"
names(withdem)[names(withdem) == "SWAVE"]   <- "swave"
names(withdem)[names(withdem) == "SHHADID"] <- "shhadid"

## adding self to count of household kids if self is < 18
withdem$nHHkids <- ifelse(withdem$adj_age < 18 , withdem$nHHkids + 1,  withdem$nHHkids)

## fixing records living alone
withdem$HHsize[is.na(withdem$HHsize)] <- 1
withdem$nHHkids[is.na(withdem$nHHkids) & withdem$adj_age > 17] <- 0
withdem$nHHkids[is.na(withdem$nHHkids) & withdem$adj_age < 18] <- 1
withdem$nmomto[is.na(withdem$nmomto)] <- 0
withdem$nmomtominor[is.na(withdem$nmomtominor)] <- 0
withdem$nbiomomto[is.na(withdem$nbiomomto)] <- 0
withdem$spartner[is.na(withdem$spartner)] <- 0

withdem[with(withdem, order("ssuid", "epppnum", "shhadid", "swave")), ]