#Multiple imputation through chained equations in R
library(mice)      #for multiple imputations
library(systemfit) #for seemingly unrelated regression
library(multcomp)  #for hypothesis tests of models coefficients

#note that the slashes need to be escaped in R
mydir <- "C:\\Users\\axw161530\\Box Sync\\Classes\\Sem_ResearchAnalysis\\Code_Snippets\\8_MissingData_Analysis" 
setwd(mydir)

#read in CSV file
SurvData <- read.csv(file="MissingData_DallasSurvey.csv",header=TRUE)
summary(SurvData)
names(SurvData)[1] <- "Safety_Violent" #name gets messed up, probably a BOM at the beginning of the csv file

#Need to recode the missing values, use NA in R
NineMis <- c("Safety_Violent","Safety_Prop","Gender","Race","Income","Edu","Age","OwnHome")
summary(SurvData[,NineMis])
for (i in NineMis){
  SurvData[SurvData[,i]==9,i] <- NA
}
summary(SurvData[,NineMis])
#YearsDallas has a missing data value of 999
SurvData[SurvData$YearsDallas==999,"YearsDallas"] <- NA
summary(SurvData$YearsDallas)
#note district is never missing

###########################################################################
#Lets do a complete case analysis, predicting safety_violent and safety_property as a function of 
#income and race

SurvComplete <- SurvData[complete.cases(SurvData),]
#check the number in the original versus the complete dataset
c(length(SurvData[,1]),length(SurvComplete[,1]))
#so we loose 1512-1223 = 289 cases

#now fitting seemingly unrelated regression
viol <- Safety_Violent ~ Income + as.factor(Race)
prop <- Safety_Prop ~ Income + as.factor(Race)
fitsur <- systemfit(list(violreg = viol, propreg= prop), data=SurvComplete, method="SUR")
summary(fitsur)

#testing whether income effect is equivalent for both models
viol_more_prop <- glht(fitsur,linfct = c("violreg_Income - propreg_Income = 0"))
summary(viol_more_prop) 
###########################################################################



###########################################################################
#now lets do a multiple imputation analysis

#only going to do safety variables, race and income for this analysis, include district to help predict
#missing data
SurvSub_wMissing <- SurvData[,c("Safety_Violent","Safety_Prop","Income","Race","District")]
SurvSub_wMissing$District <- as.factor(SurvSub_wMissing$District)
SurvSub_wMissing$Race <- as.factor(SurvSub_wMissing$Race)
SurvSub_wMissing$Income <- as.factor(SurvSub_wMissing$Income)
#this treats the safety variables as linear, and uses predictive mean matching to force the observations to be
#integer and within range, treats income as ordinal logistic, and treats race as multinomial logistic
#do not need to impute District
imp5 <- mice(SurvSub_wMissing, m = 5, meth = c("pmm","pmm","polr","polyreg",""), seed=10)

#we can do a simple linear regression and have mice pool it for us already
pool_viol <- with(imp5, lm(Safety_Violent ~ as.numeric(Income) + Race)) #need to do income as numeric becauase it was recoded to a factor
summary(pool(pool_viol))

pool_prop <- with(imp5, lm(Safety_Prop ~ as.numeric(Income) + Race))
summary(pool(pool_prop))

#if we want to do the seemingly unrelated regression though ourselves (accounting for the correlation between equations)
#we can extract the datasets and loop over each imputation
SurvImpComp <- complete(imp5,"long")
summary(SurvImpComp) #the first variable is the imputation number, see 1512
SurvImpComp$Income <- as.numeric(SurvImpComp$Income) #changing this back to a continuous variable
#now creating systemfit results for each subset

results_SUR <- vector(mode="list",length=5) #will store the linear regression results
hypTest_SUR <- vector(mode="list",length=5) #will store the hypothesis test
viol2 <- Safety_Violent ~ Income + Race
prop2 <- Safety_Prop ~ Income + Race
for (i in 1:5){
  SubImp <- SurvImpComp[SurvImpComp[,1]==i,] #subset the data
  results_SUR[[i]] <- systemfit(list(violreg = viol2, propreg= prop2), data=SubImp, method="SUR") #store regression
  print(summary(results_SUR[[i]])) #print results
  hypTest_SUR[[i]] <- glht(results_SUR[[i]],linfct = c("violreg_Income - propreg_Income = 0")) #store hypothesis test
  print(summary(hypTest_SUR[[i]])) #print hypothesis test
}

#I want to make a nicer dataframe to store the results
est <- data.frame(coef(summary(fitsur))) #extracts the coefficients, puts in a dataframe
est$imp <- 0 #complete case analysis, using zero to indicate
est$varC <- rownames(est) #making a variable that says the varaible in the regression (instead of the row names)

for (i in 1:5){
  tempI <- data.frame(coef(summary(results_SUR[[i]])))  #this takes each subset and stacks against the original
  tempI$imp <- i
  tempI$varC <- rownames(tempI)
  names(tempI) <- names(est) #necessary to combine the datasets
  est <- rbind(est,tempI)
}
rownames(est) <- 1:length(rownames(est)) #turning the rownames into a numeric vector

#you can then easily see the estimates across each subset
est[est$varC=="propreg_Income",]  
est[est$varC=="violreg_Income",]
#can see very little variance across the subsets
   
#now doing the same for hypothesis test of violent larger than property
#this is a bit down the rabbit hole....
hyp_Imp <- data.frame(summary(viol_more_prop)$test$coefficients,summary(viol_more_prop)$test$sigma,0)
names(hyp_Imp) <- c("Est","SE","Imp")
rownames(hyp_Imp) <- 1
hyp_Imp
#now add the other five imputations
for (i in 1:5){
  temp <- summary(hypTest_SUR[[i]])
  tempDF <- data.frame(temp$test$coefficients,temp$test$sigma,i)
  names(tempDF) <- names(hyp_Imp)
  rownames(tempDF) <- i + 1
  hyp_Imp <- rbind(hyp_Imp,tempDF)
}
hyp_Imp
#very similar difference across the 5 imputations
#can pool the results
poolTest <- pool.scalar(hyp_Imp$Est[2:6],hyp_Imp$SE[2:6]^2,n=1512)
poolTest

#qbar is the averaged estimate
#t is the total variance of the pooled values
#so sqrt(poolTest$t) is the standard error of the pooled estimate
#slightly smaller than the complete case, but slightly larger than any individual imputation
