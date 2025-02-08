## BEFORE BEGINNING, MAKE SURE TO INSTALL THE FOLLOWING PACKAGES
# dplyr, remotes, ggplot2

## ENSURE THAT THE 'Crime_Incidents_in_2024.csv' FILE IS IN THE EXACT SAME 
## FOLDER AS THIS R CODE FILE. NOTE THAT DUE TO THE LOOPING THIS 
##PROGRAM DOES, IT MAKE TAKE A COUPLE MINUTES TO FINISH PROCESSING ALL THE DATA. 

## Loading Packages
library(dplyr)
library(remotes)
library(ggplot2)
install_github("BingoLaHaye/DCmapR")
library(DCmapR)

## Loading Data
crimeDataOriginal<-read.delim("Crime_Incidents_in_2024.csv", sep=",", header=T)

## Generating Federal Holidays List + Christmas Eve
federalHolidays<- as.Date(c("2024/01/01", "2024/01/15", "2024/02/19", "2024/05/27",
                    "2024/06/19", "2024/07/04", "2024/09/02", "2024/10/14",
                    "2024/11/11", "2024/11/28", "2024/12/24", "2024/12/25"))

## Deleting Unnecessary Columns in New Dataframe
crimeData<-subset(crimeDataOriginal, select = -c(X, Y, 
                                                 CCN, XBLOCK, YBLOCK, ANC, PSA, 
                                                 BLOCK_GROUP, CENSUS_TRACT, 
                                                 VOTING_PRECINCT, BID, 
                                                 OBJECTID, DISTRICT,
                                                 NEIGHBORHOOD_CLUSTER, 
                                                 OCTO_RECORD_ID))

## Transforming REPORT_DAT Column to Include Only Date and not Time
crimeData$REPORT_DAT = substr(crimeData$REPORT_DAT, 
                              1, nchar(crimeData$REPORT_DAT)-12)

## Adding Needed Columns to Transform Data in New Dataframe
crimeData$WARD_DUMMY<-ifelse(crimeData$WARD == 2 | crimeData$WARD == 6 | crimeData$WARD == 3 , 0, 1)
crimeData$DAY_WEIGHT<-ifelse(crimeData$SHIFT == "DAY", 0, 
                             ifelse(crimeData$SHIFT == "EVENING", 0.5, 1))
crimeData$HOLIDAY_PROXIM<-min(as.Date(federalHolidays, format = "%Y/%m/%d") 
                              - as.Date("2024/03/19", format = "%Y/%m/%d"))

# Adding in season tags
crimeData$SEASON<-ifelse(crimeData$REPORT_DAT >= "2024/03/19" 
                         & crimeData$REPORT_DAT < "2024/06/20", "SPRING", 
                         ifelse(crimeData$REPORT_DAT >= "2024/06/20" 
                                & crimeData$REPORT_DAT < "2024/09/21", "SUMMER",
                         ifelse(crimeData$REPORT_DAT >= "2024/09/22"
                                & crimeData$REPORT_DAT < "2024/12/20", "FALL", 
                                "WINTER")))

crimeData$HOLIDAY_PROXIM<-365
for(i in 1:nrow(crimeData))
{
  for(j in 1:length(federalHolidays))
  {
      crimeData$HOLIDAY_PROXIM[i]<-pmin(abs(as.Date(federalHolidays[j]) - as.Date(crimeData$REPORT_DAT[i])), crimeData$HOLIDAY_PROXIM[i])
  }
}

crimeData$VIOLENT_CRIME<-ifelse( crimeData$OFFENSE == "ASSAULT W/DANGEROUS WEAPON" 
                               | crimeData$OFFENSE == "HOMICIDE"
                               | crimeData$OFFENSE == "ROBBERY"
                               | crimeData$OFFENSE == "SEX ABUSE", 1, 0)

crimeData<-subset(crimeData,  !is.na(VIOLENT_CRIME)
                            & !is.na(WARD_DUMMY)
                            & !is.na(DAY_WEIGHT)
                            & !is.na(HOLIDAY_PROXIM)
                            & !is.na(SEASON))

## Creating GLM Model Train and Test Datasets
n_total<-nrow(crimeData)
vars<-runif(n_total)
crimeData_train<- crimeData[vars < 0.7,]
crimeData_test<- crimeData[vars >= 0.7,]

## Creating Model
fmla<- VIOLENT_CRIME ~ WARD_DUMMY + DAY_WEIGHT + HOLIDAY_PROXIM + SEASON
VIOLENT_CRIME_MODEL<- glm(fmla, data=crimeData_train, family=binomial)

## Summarizing the Training Data Model
summary(VIOLENT_CRIME_MODEL)

## Making the Test Data Model
crimeData_test$pred<-predict(VIOLENT_CRIME_MODEL, newdata=crimeData_test, type = "response")
summary(crimeData_test$pred)

nullVCM<-glm(VIOLENT_CRIME~1, data=crimeData_train, family=binomial)
mcfaddenR2<-(1-(logLik(VIOLENT_CRIME_MODEL)/logLik(nullVCM)))

## Applying the Model to the Entire Data Set
crimeData$pred<-predict(VIOLENT_CRIME_MODEL, newdata=crimeData, type = "response")

######################
## Sort Dataset by Probability of 'pred' column
crimeData <- crimeData[order(crimeData$pred, decreasing=FALSE),]

## Getting Data for Plots
numViolentCrimesWard<-c()
avgPercentChanceWard<-c()
for (i in 1:8)
{
  numTotalCrimesWard<-append(numTotalCrimesWard, 
                             sum(crimeData$WARD == i))
  
  numViolentCrimesWard<-append(numViolentCrimesWard, 
                               sum(crimeData$WARD == i & 
                               (crimeData$OFFENSE == 'ASSAULT W/DANGEROUS WEAPON'
                               |crimeData$OFFENSE == 'HOMICIDE'
                               |crimeData$OFFENSE == 'ROBBERY'
                               |crimeData$OFFENSE == 'SEX ABUSE')))
  
  avgPercentChanceWard<-append(avgPercentChanceWard, 
                               mean(crimeData[crimeData$WARD == i
                               ,'pred'], na.rm = TRUE))
}
numViolentCrimesWard<-as.data.frame(numViolentCrimesWard)
print(numViolentCrimesWard)
avgPercentChanceWard<-as.data.frame(avgPercentChanceWard)
numViolentCrimesWard$WARD<-c(1,2,3,4,5,6,7,8)
avgPercentChanceWard$WARD<-c(1,2,3,4,5,6,7,8)
numViolentCrimesWard$WARD<-as.factor((as.character(numViolentCrimesWard$WARD)))
avgPercentChanceWard$WARD<-as.factor((as.character(avgPercentChanceWard$WARD)))

## Establish two Datasets for Sampling Within
crimeData_first1000 <- crimeData[1:1000,]
crimeData_last1000  <- crimeData[28296:29295,]

## Count Frequency of Violent Crime Occurrences in Both sets
table(crimeData_first1000$OFFENSE)
table(crimeData_last1000$OFFENSE)


######################
## Plotting Violent Crimes by Number in Ward
WardsDF <- get_Ward(dataframe = TRUE)
centroid <- get_centroid(Ward = TRUE)
violentCrimesSet <- WardsDF %>%
  full_join(numViolentCrimesWard, by = c("Ward" = "WARD"))
violentCrimesMap <- ggplot() +
  geom_polygon(data = violentCrimesSet, aes(x = long, y = lat, group = group, 
                                     fill = as.numeric(as.character(numViolentCrimesWard))), 
               col  = "black", alpha = 0.6, size = 1) +
  scale_fill_gradient(name = "Violent Crimes by Raw Total in Each Ward", low = "white", high="red" ) +
  theme(legend.title = element_text(size = 10)) + geom_text(data = centroid, aes(x, y, label = Ward), size = 5) +
  coord_quickmap()
violentCrimesMap

## Plotting Crimes by Percent Chance from Model in Ward
crimeModelPercentSet <- WardsDF %>%
  full_join(avgPercentChanceWard, by = c("Ward" = "WARD"))
crimeModelPercentMap <- ggplot() +
  geom_polygon(data = crimeModelPercentSet, aes(x = long, y = lat, group = group, 
                                            fill = as.numeric(as.character(avgPercentChanceWard))), 
               col  = "black", alpha = 0.6, size = 1) +
  scale_fill_gradient(name = "Violent Crimes by Model Percentage Prediction", low = "white", high="orange" ) +
  theme(legend.title = element_text(size = 10)) +  geom_text(data = centroid, aes(x, y, label = Ward), size = 5) +
  coord_quickmap()
crimeModelPercentMap

