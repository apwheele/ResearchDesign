#Generalized linear models and non-linear effects in R
library(ggplot2)
library(Hmisc) #for restricted cubic splines
library(MASS) #for negative binomial regression

#######################################################################
#setting the directory and prepping the data
mydir <- "C:\\Users\\axw161530\\Box Sync\\Classes\\Sem_ResearchAnalysis\\Code_Snippets\\4_NonLinearRegression" 
setwd(mydir)

#read in the csv file
CrimeData <- read.csv(file="DC_Crime_MicroPlaces.csv")

#add a new variable to the data frame, R is case sensitive
CrimeData$AlcLic <- CrimeData$TypeA + CrimeData$TypeB + CrimeData$TypeC_D
#######################################################################


#######################################################################
#LINEAR MODEL

LinMod <- lm(TotalCrime ~ AlcLic + CFS1 + CFS2, data=CrimeData)
summary(LinMod)

#linear predictions for new data
PredData <- data.frame(CFS1=1:10)
PredData$AlcLic <- 0
PredData$CFS2 <- 5
LinPred <- predict(LinMod,newdata=PredData,se.fit=TRUE)
#PredData$LinB <- LinPred$fit
#PredData$LinSE <- LinPred$se.fit
#######################################################################

#######################################################################
#GENERALIZED LINEAR MODEL - POISSON

#Lets check to see if Poisson would be a good fit given the number of zeroes
freqN <- as.data.frame(table(CrimeData$TotalCrime))
freqN$Perc <- (freqN$Freq/sum(freqN$Freq))*100

mu <- mean(CrimeData$TotalCrime)
mu
#64% of the data are zeroes, what we would expect with a mean though of just over 1.5?
dpois(0,mu)
#would only expect 22%, so lets go with negative binomial

#negative binomial regression model
PoisMod <- glm.nb(TotalCrime ~ AlcLic + CFS1 + CFS2, data=CrimeData)

#now lets see how well it fits 
predPois <- predict(PoisMod,type="response")
PredZero <- sum(dnbinom(0, mu=predPois, size=PoisMod$theta))
PredZero
PredZero/sum(freqN$Freq)
#64%, the fit is very good!

#now lets look at the predictions for CFS1 for the two models
PoisPred <- predict(PoisMod,newdata=PredData,se.fit=TRUE,type="response")

#lets look at the combined predictions now
DifPred <- data.frame(LinP=LinPred$fit,LinSE=LinPred$se.fit,PoisP=PoisPred$fit,PoisSE=PoisPred$se.fit)
DifPred$CFS1 <- 1:10
DifPred
#very similar predictions

#Make a graph showing how similar
DifP_Graph <- ggplot(data=DifPred) + 
              geom_line(aes(x=CFS1, y=LinP, linetype="Linear Effect")) +
			  geom_line(aes(x=CFS1, y=PoisP, linetype="Negative Binomial Effect")) +
			  scale_linetype_manual(values=c("Linear Effect"=1,"Negative Binomial Effect"=2))
DifP_Graph
#######################################################################


#######################################################################
#NON-LINEAR EFFECTS IN LINEAR AND GENLIN MODELS

#Now lets make non-linear effects using restricted cubic splines
summary(CrimeData$LnArea)

#adding restricted cubic splines to data frame
SplineVars <- rcspline.eval(CrimeData$LnArea, nk=7)
SplineDF <- as.data.frame(SplineVars)
knotsLnArea <- attr(SplineVars, "knots")
names(SplineDF) <- paste0("LnArea_RCS",1:5)
CrimeWSplines <- cbind(CrimeData,SplineDF)


LinModwSplines <- lm(TotalCrime ~ AlcLic + CFS1 + CFS2 + LnArea + LnArea_RCS1 + LnArea_RCS2 + LnArea_RCS3 + LnArea_RCS4 + LnArea_RCS5, data=CrimeWSplines)
SplineBasis <- as.data.frame(rcspline.eval(seq(from=0,to=13,by=0.1), inclx=TRUE, knots=knotsLnArea))
names(SplineBasis) <- c("LnArea",paste0("LnArea_RCS",1:5))

SplineBasis$AlcLic <- 0
SplineBasis$CFS2 <- 5
SplineBasis$CFS1 <- 0

PredLinSp <- predict(LinModwSplines,newdata=SplineBasis,se.fit=TRUE)
SplineBasis$LinPred <- PredLinSp$fit
SplineBasis$LinLow <- PredLinSp$fit - 2*PredLinSp$se.fit
SplineBasis$LinHigh <- PredLinSp$fit + 2*PredLinSp$se.fit

pLinSp <- ggplot(data=SplineBasis, aes(x=LnArea, y = LinPred, ymin = LinLow, ymax=LinHigh)) + geom_ribbon(alpha=0.5, color="grey") + geom_line()
pLinSp

#now lets look at the same for negative binomial regression
PoisModwSplines <- glm.nb(TotalCrime ~ AlcLic + CFS1 + CFS2 + LnArea + LnArea_RCS1 + LnArea_RCS2 + LnArea_RCS3 + LnArea_RCS4 + LnArea_RCS5, data=CrimeWSplines)

PredPoisSp <- predict(PoisModwSplines,newdata=SplineBasis,se.fit=TRUE,type="response")
SplineBasis$PoisPred <- PredPoisSp$fit
SplineBasis$PoisLow <- PredPoisSp$fit - 2*PredPoisSp$se.fit
SplineBasis$PoisHigh <- PredPoisSp$fit + 2*PredPoisSp$se.fit

pPoisSp <- ggplot(data=SplineBasis, aes(x=LnArea, y = PoisPred, ymin = PoisLow, ymax=PoisHigh)) + geom_ribbon(alpha=0.5, color="grey") + geom_line()
pPoisSp

#similar predictions where the bulk of the data is
#######################################################################
