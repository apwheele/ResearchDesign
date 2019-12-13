**************************************************************************
*START UP STUFF
*Set the working directory and plain text log file
cd "C:\Users\axw161530\Box Sync\Classes\Sem_ResearchAnalysis\Code_Snippets\4_NonLinearRegression"
*log the results to a text file
log using "Week4_Stata_GenLinReg.txt", text replace
*so the output just keeps going
set more off
*let stata know to search for a new location for stata plug ins
adopath + "C:\Users\axw161530\Documents\Stata_PlugIns"
*in this script I downloaded the matselrc plug in and the postrcspline
*to install on your own in the lab it would be
*net set ado "C:\Users\axw161530\Documents\Stata_PlugIns"
*findit matselrc
*and then install
*for splines it is 
*ssc install postrcspline
**************************************************************************

**************************************************************************
*PREPPING THE DATA
*Load in the csv data
import delimited DC_Crime_MicroPlaces.csv

*generate variable for all alcohol licenses
gen AlcLic = typea + typeb + typec_d
**************************************************************************

**************************************************************************
*LINEAR REGRESSION

*linear regression model
regress totalcrime AlcLic cfs1 cfs2

*Lets look at the marginal predictions with the linear model for cfs2, other variables are at the mean
margins , at(cfs1=(1(1)10) AlcLic=0 cfs2 = 5)
matrix lin = r(table)'
**************************************************************************

**************************************************************************
*POISSON REGRESSION

*Now lets compare to a Poisson regression model
*but should we use Poisson or negative binomial - lets check zeroes
summarize totalcrime
scalar mu = r(mean)
scalar nobs = r(N)

tabulate totalcrime

*what should the number of zeroes be with this mean if the data are poisson distributed?
display poissonp(mu,0)
*only 22%, compared to 64% observed, so lets go with negative binomial

nbreg totalcrime AlcLic cfs1 cfs2

*margins again
margins , at(cfs1=(1(1)10) AlcLic=0 cfs2 = 5)
matrix Pois = r(table)'

*lets see how well this predicts zeros
predict model0prob, pr(0)
quietly summarize model0prob  
display r(sum)
*the fit for zeroes is very good!

*Lets compare the predictions for the two models
*matselrc is a special command via 
matselrc Pois PoisSub, c(1/2)
matselrc lin LinSub, c(1/2)
matrix Mods = LinSub,PoisSub
matrix colnames Mods = LinB LinSE PoisB PoisSE
matrix list Mods
*Those marginal effect estimates are very similar

*now lets graph these effects
*save the original dataset though
preserve
clear 

svmat Mods, names(col)
gen CFS1 = _n - 1
label variable LinB "Linear Effect"
label variable PoisB "Negative Binomial"
label variable CFS1 "Calls for Service (Detritus)"
line LinB PoisB CFS1, ytitle("Predicted Crimes per Street Unit") xlabel(1(1)10) scheme(sj)

restore
**************************************************************************



**************************************************************************
*NON-LINEAR EFFECTS
*Now lets do non-linear predictions of the log of the land area

summarize lnarea

lowess totalcrime lnarea, bwidth(0.1)
*not very informative, zoomed out so much

*creating restricted cubic splines
*original Stata command
*mkspline areaSP=lnarea, cubic nknots(7)
*user written command, useful for post-estimation
mkspline2 sp_area = lnarea, cubic nknots(7)

reg totalcrime AlcLic cfs1 cfs2 sp_area*
adjustrcspline , at(AlcLic=0 cfs1=0 cfs2 = 5)

*how about with poisson regression
glm totalcrime AlcLic cfs1 cfs2 sp_area* , family(nbinomial ml)
adjustrcspline , at(AlcLic=0 cfs1=0 cfs2 = 5)

*similar non-linear effect estimated in both the linear and the generalized linear model
**************************************************************************