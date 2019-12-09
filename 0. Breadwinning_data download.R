#####################################################################################
# Set-up the Directories
mainDir    <- "C:/Users/Joanna/Dropbox/Data" # Change this to your master data folder 
SIPPDir    <- "SIPP" # Name of the folder where we keep all SIPP datafiles
rawDir     <- "SIPP2008_raw" # Name of the sub-folder where we download the SIPP data
sipp08Dir  <- "SIPP2008" # Name of the folder where we keep processed SIPP2008 data

dataDir    <- file.path(mainDir, SIPPDir) # File path to the SIPP data files

## This will create a sub-directory "SIPP" folder in the master data directory if doesn't exist
if (!dir.exists(dataDir)){
  dir.create(dataDir)
} else {
  print("SIPP data directory already exists!")
}

## This will create a sub-directory "SIPP2008_raw" folder in the SIPP data directory if doesn't exist
if (!dir.exists(file.path(dataDir, rawDir))){
  dir.create(dataDir)
} else {
  print("SIPP2008_raw sub-folder already exists!")
}

## This will create a sub-directory "SIPP2008" folder in the SIPP data directory if doesn't exist
if (!dir.exists(file.path(dataDir, sipp08Dir))){
  dir.create(dataDir)
} else {
  print("SIPP2008 sub-folder already exists!")
}
#####################################################################################
# Follow instructions in the markdown file (breadwinning.Rmd) to download and prep the data for import.
### This step takes place in Stata

#####################################################################################
# Importing the (Stata) data files
library(plyr)
library(tidyverse)
library(readstata13)
library(haven)
library(data.table)

setwd(file.path(dataDir, sipp08Dir))

fileNames <- list.files(pattern = "^sippl08puw.*\\.dta$") # create a list of all waves

## Add something about ignoring/muting warnings. (See RMD output)
sipp <- lapply(fileNames, function(x) {
        read.dta13(x, 
        select.cols = c("ssuid", "shhadid", "rfid", "epppnum", "swave", "srefmon",
                        "tpearn", "thearn", "tfearn", 
                        "thothinc", "thtotinc", "tftotinc", "tpprpinc", "tptrninc", "tpothinc",
                        "tmlmsum", "amlmsum", 
                        "efnp", "t15amt", "eeducate", 
                        "aoincb1", "aoincb2", "eoincb1", "eoincb2",  
                        "tbmsum1", "tbmsum2", "abmsum1", "abmsum2",
                        "tpmsum1", "tpmsum2", "apmsum1", "apmsum2",
                        "tprftb1", "tprftb2", "aprftb1", "aprftb2",
                        "eslryb1", "eslryb2", "aslryb1", "aslryb2")) %>%
        subset(srefmon=="Fourth Reference month")
})

# Turn the list of dataframes into one master dataframe.
data <- rbindlist(sipp)

# Turn the epppnum variable into an integer
data$epppnum <- as.integer(data$epppnum)

## Subsetting data to match KR in Stata -- delete?
data <- data %>%
  subset(swave != 16)

## Save the dataframe for easy open in the future
save(data, file="sipp08tpearn_all.Rda")
