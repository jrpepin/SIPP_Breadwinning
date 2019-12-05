jpdata <- data %>%
  filter(is.na(abw50)) %>%
  select(ssuid, epppnum, altpearn, althearn, thearn, abw50)

krdata <- read_dta("C:/Users/Joanna/Dropbox/Repositories/SIPP_Breadwinning/data/trouble.dta") # Import the downloaded data file.
krdata$krdata <- 1

missdata <- merge(jpdata, krdata[, c("ssuid", "shhadid", "rfid", "swave", "epppnum", 
                              "abw50", "altpearn", "althearn", "thearn", "krdata")], c("ssuid","shhadid", "rfid", "swave", "epppnum"), all.x=TRUE)

trouble <- missdata %>%
  filter(is.na(krdata))

case <- data %>%
  filter(ssuid == "019228130714") %>%
  select(ssuid, epppnum, altpearn, althearn, thearn, abw50, ratio)