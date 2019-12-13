#using the MatchIt library
library(MatchIt)
library(effsize)

set.seed(10)
mydir <- "C:\\Users\\axw161530\\Box Sync\\Classes\\Sem_ResearchAnalysis\\Code_Snippets\\5_PropensityScore" 
setwd(mydir)

#read in the csv file
ArrestData <- read.csv(file="Example_Dataset.csv")
summary(ArrestData)
names(ArrestData)[1] <- "MyId" #name gets messed up, probably a BOM at the beginning of the csv file

#turning 

#default use of matching
m.out1 <- matchit(Treatment ~ Race + Sex + TotalPriorArrests + Weight_lbs, data= ArrestData)
summary(m.out1)

#fit an equivalent logistic regression model
ModelTreat <- glm(Treatment ~ Race + Sex + TotalPriorArrests + Weight_lbs, data= ArrestData, family=binomial(logit))
summary(ModelTreat)
all.equal(predict(ModelTreat,type="response"),m.out1$distance) #shows the distance measure is the same for both


#exact matching on Race and Sex
m.out2 <- matchit(Treatment ~ Race + Sex + TotalPriorArrests + Weight_lbs, data= ArrestData
                  ,method = "nearest", exact = c("Race","Sex"), ratio=1)  #change ratio to higher number for more matches
summary(m.out2)

#lets see the ttest and cohensd for the original data and for the matched data
t.test(TotalPriorArrests~Treatment, data=ArrestData)
t.test(Weight_lbs~Treatment, data=ArrestData)
cohen.d(TotalPriorArrests~Treatment, data=ArrestData) #multiply this by 100 to get percentage bias
cohen.d(Weight_lbs~Treatment, data=ArrestData)

matchedData <- match.data(m.out2) #using the first matching model model, chaning it to m.out2 gives very different results!
length(matchedData$MyId) #1 for 1 matching

#now check for balance for the matched data
t.test(TotalPriorArrests~Treatment, data=matchedData)
t.test(Weight_lbs~Treatment, data=matchedData)
cohen.d(TotalPriorArrests~Treatment, data=matchedData) #multiply this by 100 to get percentage bias
cohen.d(Weight_lbs~Treatment, data=matchedData)
#prior arrests are much better, but Weight_lbs are less balanced (but still not bad at 10%)

#now estimate t-tests of mean differences and logistic regression for the outcome, anyarrests
t.test(AnyArrest~Treatment,data=ArrestData) #effect in the original sample
t.test(AnyArrest~Treatment,data=matchedData) #effect in the matched sample

#logisitic regression
logit_matched <- glm(AnyArrest ~ Treatment + Weight_lbs, data=matchedData, family="binomial")
summary(logit_matched)