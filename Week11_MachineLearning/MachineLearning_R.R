library(gbm) #generalized boosted models
library(randomForest) #random forest
library(ROCR) #for ROC curves
library(ggplot2) #for nice graphs

MyDir <- "C:\\Users\\axw161530\\Box Sync\\Classes\\Sem_ResearchAnalysis\\Code_Snippets\\11_MachineLearning"
setwd(MyDir)
set.seed(10)

#read in CSV file
CompasData <- read.csv(file="PreppedCompas.csv",header=TRUE)
summary(CompasData)
names(CompasData)[1] <- "person_id" #name gets messed up, probably a BOM at the beginning of the csv file

#for factor variables, better to encode them as 0/1 continuous variables, here only using sex
#during cross-validation some factor levels can be missing
CompasData$Male <- 1*(CompasData$sex == "Male")

#Now lets create a hold-out dataset and a training dataset, will use a 30% hold-out
n <- length(CompasData[,1]) #11,757 observations 
p <- 0.3
holdout_size <- ceiling(n*p)

#randomly sample dataset
rs <- sample(1:n)
CompasHoldOut <- CompasData[rs[1:holdout_size],]   #hold out dataset
CompasPrep <- CompasData[rs[(holdout_size+1):n],]  #training dataset
c(length(CompasHoldOut$person_id),length(CompasPrep$person_id)) #checking that they are the correct size

#so the compas Prep is the dataset we will be fitting models on, and the hold out set is the one we will be evaluate the predictions of


################################################################################################
#FITTING MODELS

#Logistic regression
logitMod1 <- glm(formula=Recid30 ~ Male + YearsScreening + CompScore.1 + CompScore.2 + CompScore.3 + juv_fel_count, 
                 data=CompasPrep, family="binomial")
summary(logitMod1)

#Random Forest
rfMod2 <- randomForest(formula=as.factor(Recid30) ~ Male + YearsScreening + CompScore.1 + CompScore.2 + CompScore.3 + juv_fel_count, 
                       data=CompasPrep, importance=TRUE) #need as factor, else uses linear regression
print(rfMod2)
varImpPlot(rfMod2, type=1) #importance plot, the Compas Scores are the strongest predictors
					   
#generalized boosted regression
gbMod3 <- gbm(formula=Recid30 ~ Male + YearsScreening + CompScore.1 + CompScore.2 + CompScore.3 + juv_fel_count, 
              distribution="bernoulli", data=CompasPrep, interaction.depth=5)
summary(gbMod3) #CompasScore.1 is the main factor, other variables contribute much less
################################################################################################


################################################################################################
#Predictions on the hold out set

#predicted probabilities
PredLogit <- predict(logitMod1, newdata=CompasHoldOut, type="response")
PredRF <- predict(rfMod2, newdata=CompasHoldOut, type="prob")[,2] #response for this produces 0/1
PredGB <- predict(gbMod3, newdata=CompasHoldOut, type="response", n.trees=100)

#If we set the split at 50%, what is the classification table for each predictor?
#rows are observed, columns are predicted
table(CompasHoldOut$Recid30,(PredLogit > 0.5)*1) #Logit
table(CompasHoldOut$Recid30,(PredRF    > 0.5)*1) #Random Forest
table(CompasHoldOut$Recid30,(PredGB    > 0.5)*1) #does not work for this, because all predictions are within 40%!
hist(PredGB) #it still could be a decent classifier though

#Now lets create ROC curves for each of these predictors
#this step is needed for the ROCR packages
PredLogit_P <- prediction(PredLogit, CompasHoldOut$Recid30)
PredRF_P <- prediction(PredRF, CompasHoldOut$Recid30)
PredGB_P <- prediction(PredGB, CompasHoldOut$Recid30)

#superimpose the ROC curves
L1 <- performance(PredLogit_P, "tpr", "fpr")
R2 <- performance(PredRF_P, "tpr", "fpr")
G3 <- performance(PredGB_P, "tpr", "fpr")

#make into a nice dataframe
ROC_data <- data.frame(rbind(cbind(L1@x.values[[1]],L1@y.values[[1]],1),
                             cbind(R2@x.values[[1]],R2@y.values[[1]],2),
                             cbind(G3@x.values[[1]],G3@y.values[[1]],3))
	        )
names(ROC_data) <- c("fpr","tpr","Model")
ROC_data$Model <- as.factor(ROC_data$Model)
levels(ROC_data$Model) <- c("Logit","Random Forest","GBM")

p <- ggplot(data=ROC_data, aes(x=fpr,y=tpr,color=Model)) + geom_abline(slope=1) + geom_line() 
p

#area under the curve for each
performance(PredLogit_P, "auc")@y.values[[1]]
performance(PredRF_P, "auc")@y.values[[1]]
performance(PredGB_P, "auc")@y.values[[1]]





