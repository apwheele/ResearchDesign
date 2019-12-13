#Differences in Differences model in R 
library(car)

#note that the slashes need to be escaped in R
mydir <- "C:\\Users\\axw161530\\Box Sync\\Classes\\Sem_ResearchAnalysis\\Code_Snippets\\6_Diff_in_Diff" 
setwd(mydir)

#read in the Rdata file
load("Monthly_Sim_Data.RData")
ls() #see the objects now available, we have a new object called "ShootData"
summary(ShootData)

#################################################################
#Now fit a linear model
linMod1 <- lm(Y ~ Post*Exper, data=ShootData)
summary(linMod1)

#predicted marginal means for pre-post
predData <- data.frame(Post=c(0,1,0,1),Exper=c(0,0,1,1))
predlinMod1 <- predict(linMod1,newdata=predData,se.fit=TRUE)
predData$MeanLin1 <- predlinMod1$fit
predData$seLin1 <- predlinMod1$se.fit
predData

#what is the hypothetical mean without the treatment
deltaMethod(linMod1,"(Intercept) + Post + Exper")
#could get standard errors directly without the deltaMethod, but I am lazy


#How about a poisson model 
PoisMod1 <- glm(Y ~ Post*Exper,data=ShootData,family=poisson)
summary(PoisMod1)

#predicted marginal means
predPoisMod1 <- predict(PoisMod1,newdata=predData[,c(1,2)],se.fit=TRUE,type="response")
predData$MeanPoi1 <- predPoisMod1$fit
predData$sePoi1 <- predPoisMod1$se.fit
predData
#predicted means are identical, but standard errors are not

#what is the hypothetical mean for the Poisson model?
deltaMethod(PoisMod1,"exp((Intercept) + Post + Exper)")
#a bit higher than the linear model

#In the Stata code I estimate a generelized estimating equation using ar1 errors
#You can do this in R, but the predict function and deltaMethod function do not work
#library(geepack)
#PoisMod2 <- geeglm(Y ~ Post*Exper,data=ShootData,family=poisson,id=Exper,waves=Ord,corstr="ar1")
#predPoisMod2 <- predict(PoisMod1,newdata=predData[,c(1,2)],se.fit=TRUE,type="response") #this generates errors
#deltaMethod(PoisMod1,"exp((Intercept) + Post + Exper)") #this does not work either
#so you would have to do more work to get this information (I would just switch to Stata or SPSS!)