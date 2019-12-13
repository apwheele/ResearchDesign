#comments in R start with a pound 

#note that the slashes need to be escaped in R
mydir <- "C:\\Users\\axw161530\\Dropbox\\Classes\\Sem_ResearchAnalysis\\Code_Snippets\\2_Reproducible_Descriptives" 
setwd(mydir)

#read in the csv file
CrimeData <- read.csv(file="DC_Crime_MicroPlaces.csv")

#add a new variable to the data frame, R is case sensitive
CrimeData$AlcLic <- CrimeData$TypeA + CrimeData$TypeB + CrimeData$TypeC_D

#get summaries of specific variables
vars <- c("AlcLic","TotalCrime")
summary(CrimeData[,vars])

#Standard deviations
sd(CrimeData$AlcLic)
sd(CrimeData$TotalCrime)

#histogram of crime
hist(CrimeData$TotalCrime)

#scatterplot of crime and alcohol licenses
plot(CrimeData$AlcLic,CrimeData$TotalCrime)


#to load a libary of interest
#install.packages('ggplot2'); install.packages('plyr') #uncomment this line if you need to install, note installing on lab machines may need to specify a personal library location
library(ggplot2)
library(plyr)

#creating an aggregate data frame with means and standard errors
#now making the error bar plot to superimpose, I'm too lazy to write my own function, stealing from webpage listed below
#very good webpage by the way, helpful tutorials in making ggplot2 graphs
#http://wiki.stdout.org/rcookbook/Graphs/Plotting%20means%20and%20error%20bars%20(ggplot2)/

##################################################################################
## Summarizes data.
## Gives count, mean, standard deviation, standard error of the mean, and confidence interval (default 95%).
##   data: a data frame.
##   measurevar: the name of a column that contains the variable to be summariezed
##   groupvars: a vector containing names of columns that contain grouping variables
##   na.rm: a boolean that indicates whether to ignore NA's
##   conf.interval: the percent range of the confidence interval (default is 95%)
summarySE <- function(data=NULL, measurevar, groupvars=NULL, na.rm=FALSE, conf.interval=.95, .drop=TRUE) {
    require(plyr)

    # New version of length which can handle NA's: if na.rm==T, don't count them
    length2 <- function (x, na.rm=FALSE) {
        if (na.rm) sum(!is.na(x))
        else       length(x)
    }

    # This is does the summary; it's not easy to understand...
    datac <- ddply(data, groupvars, .drop=.drop,
                   .fun= function(xx, col, na.rm) {
                           c( N    = length2(xx[,col], na.rm=na.rm),
                              mean = mean   (xx[,col], na.rm=na.rm),
                              sd   = sd     (xx[,col], na.rm=na.rm)
                              )
                          },
                    measurevar,
                    na.rm
             )

    # Rename the "mean" column
    datac <- rename(datac, c("mean"=measurevar))

    datac$se <- datac$sd / sqrt(datac$N)  # Calculate standard error of the mean

    # Confidence interval multiplier for standard error
    # Calculate t-statistic for confidence interval:
    # e.g., if conf.interval is .95, use .975 (above/below), and use df=N-1
    ciMult <- qt(conf.interval/2 + .5, datac$N-1)
    datac$ci <- datac$se * ciMult

    return(datac)
}
##################################################################################

summary_crime <- summarySE(CrimeData,measurevar="TotalCrime",groupvars="AlcLic")
#lets just print out this data frame to check it out
summary_crime
summary_crime$low <- summary_crime$TotalCrime - 2*summary_crime$se
summary_crime$high <- summary_crime$TotalCrime + 2*summary_crime$se

#now can make our nice plot
p <- ggplot(data=summary_crime, aes(x = AlcLic, y=TotalCrime, ymax=high, ymin=low, label=N)) + geom_linerange() + geom_point(fill='black',color='white',pch=21) +
     labs(x='Alcohol Licenses',y='Mean Crime per Street Unit [+/- two standard errors]') + theme_bw()
p

#to save a png plot in R
png('R_ggplot_examp.png')
p
dev.off()

