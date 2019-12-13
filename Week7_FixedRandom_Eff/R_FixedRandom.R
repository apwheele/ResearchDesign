#Fixed and random effect models in R
library(lme4)
library(MASS)
library(ggplot2)

#note that the slashes need to be escaped in R
mydir <- "C:\\Users\\axw161530\\Box Sync\\Classes\\Sem_ResearchAnalysis\\Code_Snippets\\7_FixedRandom_Effects" 
setwd(mydir)

#read in CSV file
CrimeData <- read.csv(file="DC_Crime_withAreas.csv",header=TRUE)
summary(CrimeData)
#making the FishId variable a factor variable
CrimeData$FishID <- as.factor(CrimeData$FishID)
#Making a variable that is the sum of calls for service
CrimeData$CFS_All <- CrimeData$CFS1 + CrimeData$CFS2

#Fixed effects regression model using dummy variable approach, since FishID is a factor
FixEffM1 <- lm(TotalCrime ~ TotalLic + CFS_All + FishID, data=CrimeData)
summary(FixEffM1)

#Fixed effects using demeaning approach (note standard errors are smaller, and not correct)
agg_Means <- aggregate(cbind(TotalLic,CFS_All,TotalCrime) ~ FishID,FUN=mean, data=CrimeData) #creating the aggregated means per FishID
names(agg_Means) <- c("FishID","MeanLic","MeanCFS","MeanCrime") #renaming the mean variables
Crime_wMean <- merge(CrimeData,agg_Means,by="FishID")           #add back into the original dataset
Crime_wMean$Cri_MM <- Crime_wMean$TotalCrime - Crime_wMean$MeanCrime #creating the demeaned variables for crime, alc licenses, and calls for service
Crime_wMean$Lic_MM <- Crime_wMean$TotalLic - Crime_wMean$MeanLic
Crime_wMean$CFS_MM <- Crime_wMean$CFS_All - Crime_wMean$MeanCFS

FixEffM2 <- lm(Cri_MM ~ Lic_MM + CFS_MM, data=Crime_wMean) #fitting the demeaned model
summary(FixEffM2)

#the coefficient estimates for the two models are the same!
coef(FixEffM2)[2:3];coef(FixEffM1)[2:3]

#fitting a fixed effect negative binomial model, takes about 5 minutes
FixEffM3 <- glm.nb(TotalCrime ~ TotalLic + CFS_All + FishID, data=CrimeData)
summary(FixEffM3)

#fitting a random effect negative binomial model, this takes about 5 minutes
Ran_Eff_M1 <- glmer.nb(TotalCrime ~ TotalLic + CFS_All + (1|FishID), data=CrimeData)
#gives a warning, but converged to the very nearly the same estimates as Stata
summary(Ran_Eff_M1)

#lets plot the random effects over the study area
rEffM1 <- ranef(Ran_Eff_M1,condVar=TRUE,drop=TRUE) #extracts the random effects for individual groups
vars <- attr(rEffM1$FishID,"postVar") #roundabout way to get the variances of those individual random effects
rEff_df <- data.frame(ranef(Ran_Eff_M1)$FishID,vars) #creating a new dataframe 
names(rEff_df) <- c("RanInt","Var")
rEff_df$FishID <- rownames(rEff_df) #will use this later, adding the FishID as a column and not just the rownames
#now making predictions back on the count scale, using the random effects, 1 bar and 0 calls for service
d <- c(1,1,0)
rEff_df$pred_count <- exp( sum(fixef(Ran_Eff_M1)*d) + rEff_df$RanInt )
rEff_df$low_ci <- exp( sum(fixef(Ran_Eff_M1)*d) + (rEff_df$RanInt - 1.96*sqrt(rEff_df$Var)) )  #95 percent confidence intervals, low and high
rEff_df$hig_ci <- exp( sum(fixef(Ran_Eff_M1)*d) + (rEff_df$RanInt + 1.96*sqrt(rEff_df$Var)) )  #this works because exp is a monotonic transformation
rEff_df$rank_ri <- rank(rEff_df$RanInt)
#now making a caterpillar plot
cat_p <- ggplot(data=rEff_df, aes(x=rank_ri,y=pred_count,ymin=low_ci,ymax=hig_ci)) + geom_linerange(color="grey",alpha=0.5) + geom_point(cex=1,color="black")
cat_p

#now lets have the effect of alcohol licenses vary according to the neighborhood (again takes a few minutes)
Ran_Eff_M2 <- glmer.nb(TotalCrime ~ TotalLic + CFS_All + (1 + TotalLic|FishID), data=CrimeData)
#again errors about model convergence, similar effect estimates to Stata in terms of variance components, but user beware
#fixed effects for TotalLic are a bit different though
summarize(Ran_Eff_M2)
#to see the differences in effects across the different neighborhoods, predict with 0 bars vs 1 bar
rEff_df$TotalLic <- 0 #add the variables to the newdata dataframe, zero licenses and zero calls for service
rEff_df$CFS_All <- 0
rEff_df$pred_zBar <- predict(Ran_Eff_M2,newdata=rEff_df,type="response")
rEff_df$TotalLic <- 1
rEff_df$pred_oBar <- predict(Ran_Eff_M2,,newdata=rEff_df,type="response")
rEff_df$Dif <- rEff_df$pred_oBar - rEff_df$pred_zBar
hist(rEff_df$Dif,breaks=20)
#some locations the effect is 0.2, many it is closer to 1, the mean is around 0.7










