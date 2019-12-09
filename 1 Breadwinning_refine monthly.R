#####################################################################################
# Set-up the environment

## Set-up the Directories
mainDir    <- "C:/Users/Joanna/Dropbox/Data" # This is your master data folder 
SIPPDir    <- "SIPP" # Name of the folder where we keep all SIPP datafiles
sipp08Dir  <- "SIPP2008" # Name of the folder where we keep processed SIPP2008 data
dataDir    <- file.path(mainDir, SIPPDir, sipp08Dir) # File path to the processed SIPP data files

repoDir <- "C:/Users/joanna/Dropbox/Repositories/SIPP_Breadwinning" # This should be your master project folder (Project GitRepository)
outDir <- file.path(repoDir, "results") # This will be the name of the folder where data output goes
figDir <- file.path(repoDir, "figures") # This will be the name of the folder where figures are saved

## This will create a data sub-directory folder in the master project directory if doesn't exist
if (!dir.exists(outDir)){
  dir.create(outDir)
} else {
  print("output directory already exists!")
}

## This will create a figures sub-directory folder in the master project directory if doesn't exist
if (!dir.exists(figDir)){
  dir.create(figDir)
} else {
  print("figure directory already exists!")
}

setwd(repoDir) # This will set the working directory to the master project folder

## Open the data
load(paste0(dataDir, "/sipp08tpearn_all.Rda"))

## Load the libraries
library(haven)
library(tidyverse)

### Create a sample dataset to tryout code.
sample <- data[sample(nrow(data), 500), ]

#####################################################################################
# Total Personal Earnings
  # tpearn    -- SIPP provided variable of Total Personal Earnings
  # altpearn  -- Create total personal earnings with no negative values
  # ualtpearn -- Create total personal earnings with no negative values & no allocated data 

## Summary of tpearn 
summary(data$tpearn)

## Create altpearn
### Add income from job 1 (tpmsum1), job 2 (tpmsum2), business 1 (tbmsum1), business 2 (tbmsum2), and moonlighting (tmlmsum)
data <- data %>%
  mutate(altpearn = select(., c("tpmsum1", "tpmsum2", "tbmsum1", "tbmsum2", "tmlmsum")) %>% 
  rowSums(na.rm = TRUE))

## Create ualtpearn
### Identify imputed income data.
data$anyallocate <- 0
data$anyallocate[data$abmsum1 != "Not imputed"] <- 1
data$anyallocate[data$abmsum2 != "Not imputed"] <- 1
data$anyallocate[data$apmsum1 != "Not imputed"] <- 1
data$anyallocate[data$apmsum2 != "Not imputed"] <- 1
data$anyallocate[data$amlmsum != "Not imputed"] <- 1

table(data$anyallocate)

### Set ualtpearn to missing if it is based on allocated data
data$ualtpearn <- data$altpearn
data$ualtpearn[data$anyallocate == 1] <- NA

#####################################################################################
# Account for business losses <- THESE AREN'T USED IN ANY OTHER PLACE????
data <- data %>%
  mutate(profit = select(., c("tprftb1", "tprftb2")) %>% 
           rowSums(na.rm = TRUE))

# Identify imputed business data.   ######## NOT IN KR'S CODE. WHY??
data$bizallocate <- 0
data$bizallocate[data$aprftb1 != "Not imputed"] <- 1
data$bizallocate[data$aprftb2 != "Not imputed"] <- 1

# set ualtpearn to missing if it is based on allocated data
data$uprofit <- data$profit
data$uprofit[data$bizallocate == 1] <- NA

#####################################################################################
# Create measures of household and family income
# Note that aggregating tpearn (Total person's earned income) instead of altpearn replicates 
# thearn (Total household earned income) and tfearn (Total family earned income). 

## Total Household Earnings
# thearn    -- SIPP provided variable of Total Household Earnings
# althearn  -- Create total household earnings with no negative values
# ualthearn -- Create total household earnings with no negative values & no allocated data 

## Summary of thearn 
summary(data$thearn)

## Create althearn
data <- data %>%
  group_by(ssuid, shhadid, swave) %>%
  mutate(althearn = sum(altpearn))

## Create ualthearn
data <- data %>%
  group_by(ssuid, shhadid, swave) %>%
  mutate(ualthearn = sum(ualtpearn))

# I don't think this part is necessary. Already unallocated based on ualtpearn.
        # data <- data %>% # aggregate allocation flag
        #   group_by(ssuid, shhadid, swave) %>%
        #   mutate(anyalloh = sum(anyallocate))
        # 
        # table(data$anyalloh)
        # 
        # data$ualthearn[data$anyalloh >= 1] <- NA # replace any allocated data with missing

## Total Family Earnings
# tfearn    -- SIPP provided variable of Total Family Earnings
# altfearn  -- Create total family earnings with no negative values
# ualtfearn -- Create total family earnings with no negative values & no allocated data 

## Summary of tfearn

## Create altfearn
data <- data %>%
  group_by(ssuid, shhadid, rfid, swave) %>%
  mutate(altfearn = sum(altpearn))

## Create ualtfearn
data <- data %>%
  group_by(ssuid, shhadid, rfid, swave) %>%
  mutate(ualtfearn = sum(ualtpearn))

#####################################################################################
# Diagnostics check of new variables

## Look at the variables
myvars <- c("tpearn", "altpearn", "ualtpearn", "thearn", "althearn", "ualthearn",  "tfearn",  "altfearn", "ualtfearn")
summary(data[myvars])

## Create indicator if personal earnings are less than 0
data$negearn <- 0
data$negearn[data$tpearn < 0] <- 1

## Check if SIPP provided earnings variables = created earnings variables without negative values

data$samepearn <- with(data, altpearn==tpearn) # Personal earnings
data$samefearn <- with(data, altfearn==tfearn) # Family earnings
data$samehearn <- with(data, althearn==thearn) # Household earnings

apply(data[c("samepearn", "samefearn", "samehearn")], 2, table) # View the frequencies

#####################################################################################
# Create breadwinning at 50% threshold
## bw50 is missing if thearn is negative
data <- data %>%
  mutate(
    bw50 = case_when(
      tpearn/thearn     >= .50 & thearn > 0 ~ 1,
      tpearn/thearn     <  .5  & thearn > 0 ~ 0),
    abw50 = case_when(
      altpearn/althearn <  .5  & thearn > 0 ~ 0,
     (altpearn/althearn >= .50 & thearn > 0) | thearn > 0 ~ 1)) ## KR'S CODE GIVES 1 TO abw50 IF THEARN IS NOT 0 EVEN IF ALTPEARN AND ALTHEARN ARE 0
       
apply(data[c("bw50", "abw50")], 2, table) # View the frequencies

data <- data %>%
  mutate(
    ratio = case_when(
      thearn > 0 & (tpearn/thearn != 0) ~ 1))
data$ratio[is.na(data$ratio)] <- 0
#####################################################################################
# Create education variable

data$eeducate <- as.numeric(data$eeducate)

data <- data %>%
  mutate(
    educ = case_when(
      eeducate == 1                   ~ "Not in Universe",
      eeducate >=2 & eeducate <= 9    ~ "< HS",
      eeducate == 10                  ~ "HS Grad",
      eeducate >= 11 & eeducate <= 13 ~ "Some College",
      eeducate >= 14 & eeducate <= 17 ~ "College Grad"))

data$educ <- factor(data$educ, levels = c("Not in Universe", "< HS", "HS Grad","Some College", "College Grad"))

#####################################################################################
## Look at the variables
myvars <- c("bw50", "abw50", "ratio")
summary(data[myvars])

length(data$abw50[!is.na(data$bw50)])
length(data$abw50[!is.na(data$abw50)])
length(data$ratio[!is.na(data$ratio)])