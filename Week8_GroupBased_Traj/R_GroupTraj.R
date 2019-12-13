#group based trajectory models in R
#see https://andrewpwheeler.wordpress.com/2015/09/29/some-plots-to-go-with-group-based-trajectory-models-in-r/
#for some plots and 
#https://andrewpwheeler.wordpress.com/2014/08/12/estimating-group-based-trajectory-models-using-spss-and-r/
#for using SPSS and saving the models in a loop

library(crimCV)
library(ggplot2)

#note that the slashes need to be escaped in R
mydir <- "C:\\Users\\axw161530\\Box Sync\\Classes\\Sem_ResearchAnalysis\\Code_Snippets\\9_GroupBasedTrajec" 
setwd(mydir)

#read in CSV file
GroupTraj_Data <- read.csv(file="GroupTraj_Sim.csv",header=TRUE)
summary(GroupTraj_Data)
names(GroupTraj_Data)[1] <- "MyId" #name gets messed up, probably a BOM at the beginning of the csv file


#####################################################################################
#Functions I created to help out after estimation
long_traj <- function(model,data){
  df <- data.frame(data)
  vars <- names(df)
  prob <- model['gwt'] #posterior probabilities
  df$GMax <- apply(prob$gwt,1,which.max) #which group # is the max
  df$PMax <- apply(prob$gwt,1,max)       #probability in max group
  df$Ord <- 1:dim(df)[1]                 #Order of the original data
  prob <- data.frame(prob$gwt)
  names(prob) <- paste0("G",1:dim(prob)[2]) #Group probabilities are G1, G2, etc.
  longD <- reshape(data.frame(df,prob), varying = vars, v.names = "y", 
                   timevar = "x", times = 1:length(vars), 
                   direction = "long") #Reshape to long format, time is x, y is original count data
  return(longD)                        #GMax is the classified group, PMax is the probability in that group
}

weighted_means <- function(model,long_data){
  G_names <- paste0("G",1:model$ng)
  G <- long_data[,G_names]
  W <- G*long_data$y                                    #Multiple weights by original count var
  Agg <- aggregate(W,by=list(x=long_data$x),FUN="sum")  #then sum those products
  mass <- colSums(model$gwt)                            #to get average divide by total mass of the weight
  for (i in 1:model$ng){
    Agg[,i+1] <- Agg[,i+1]/mass[i]
  }
  long_weight <- reshape(Agg, varying=G_names, v.names="w_mean",
                         timevar = "Group", times = 1:model$ng, 
                         direction = "long")           #reshape to long
  return(long_weight)
}
  
pred_means <- function(model){
    prob <- model$prob               #these are the model predicted means
    Xb <- model$X %*% model$beta     #see getAnywhere(plot.dmZIPt), near copy
    lambda <- exp(Xb)                #just returns data frame in long format
    p <- exp(-model$tau * t(Xb))
    p <- t(p)
    p <- p/(1 + p)
    mu <- (1 - p) * lambda
    t <- 1:nrow(mu)
    myDF <- data.frame(x=t,mu)
    long_pred <- reshape(myDF, varying=paste0("X",1:model$ng), v.names="pred_mean",
                         timevar = "Group", times = 1:model$ng, direction = "long")
    return(long_pred)
}

occ <- function(long_data){
  subdata <- subset(long_data,x==1)
  agg <- aggregate(subdata$PMax,by=list(group=subdata$GMax),FUN="mean")
  names(agg)[2] <- "AvePP"                         #average posterior probabilites
  agg$Freq <- as.data.frame(table(subdata$GMax))[,2]
  n <- agg$AvePP/(1 - agg$AvePP)
  p <- agg$Freq/sum(agg$Freq)
  d <- p/(1-p)
  agg$OCC <- n/d                                   #odds of correct classification
  agg$ClassProp <- p                               #observed classification proportion
  #predicted classification proportion
  agg$PredProp <- colSums(as.matrix(subdata[,grep("^[G][0-9]", names(subdata), value=TRUE)]))/sum(agg$Freq)                               
  return(agg)
}
#####################################################################################


#Now we can estimate models using the crimCV function
#needs the counts turned into a matrix

countMat <- as.matrix(GroupTraj_Data[,2:11])
#typically want init to be more, making less for time savings
Mod3 <- crimCV(countMat,3,dpolyp=2,dpolyl=1,init=3,rcv=FALSE,model="ZIPt") #setting rcv=TRUE will conduct leave one out cross validation, takes awhile though
plot(Mod3) #qualitatively similar to the output in Stata, but not quite the same

#to see the coefficients
attributes(Mod3)
Mod3$beta
#the coefficients are in the columns, so group 1 has an intercept of 2.4, -1.8*x, and -2.1*x^2 etc.
#not sure how to get the standard errors though, 
#relative fit measures, AIC and BIC
Mod3$AIC;Mod3$BIC

#now lets try the four group model
Mod4 <- crimCV(countMat,4,dpolyp=2,dpolyl=1,init=3,rcv=FALSE,model="ZIPt")
plot(Mod4) 

Mod3$AIC;Mod3$BIC
Mod4$AIC;Mod4$BIC
#the fourt group model is a better fit (smaller values) for both


#my helper functions above help to plot and calculate absolute fit statistics
longData <- long_traj(Mod4,countMat)
occ(longData) #all the absolute fit statistics

#plotting the individual trajectories in long format
p <- ggplot(data=longData, aes(x=x,y=y,group=id)) + geom_line(alpha = 0.1, position=position_jitter(w=0, h=0.1)) + facet_wrap(~GMax)
p

#see https://andrewpwheeler.wordpress.com/2015/09/29/some-plots-to-go-with-group-based-trajectory-models-in-r/
#for various other plots

