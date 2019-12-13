**************************************************************************
*START UP STUFF
*Set the working directory and plain text log file
cd "C:\Users\axw161530\Box Sync\Classes\Sem_ResearchAnalysis\Code_Snippets\8_MissingData_Analysis"
*log the results to a text file
log using "StataMissing_Data.txt", text replace
*so the output just keeps going
set more off
*let stata know to search for a new location for stata plug ins
adopath + "C:\Users\axw161530\Documents\Stata_PlugIns"
*in this script I downloaded the matselrc plug in and the postrcspline
*to install on your own in the lab it would be
net set ado "C:\Users\axw161530\Documents\Stata_PlugIns"
**************************************************************************


*Load in the dta file
import delimited MissingData_DallasSurvey.csv, clear

rename ïsafety_violent safety_violent
summarize

*we need to specify the missing data fields.
*for Stata, set missing data to ".", not the named missing value types.
foreach i of varlist safety_violent-ownhome {
    tab `i'
}

*dont specify district
mvdecode safety_violent-race income-age ownhome, mv(9=.)
mvdecode yearsdallas, mv(999=.)
summarize

*making a variable to identify the number of missing observations
egen miscomplete = rmiss(safety_violent-ownhome)
tab miscomplete
*even though any individual question is small, in total it is around 20% of the cases

******************************************************************
*lets conduct a complete case analysis
preserve 
keep if miscomplete==0

*Effect of race and income on perceptions of safety for both property
*and violent crimes

*sureg (safety_violent income i.race)(safety_prop income i.race)
mvreg safety_violent safety_prop = income i.race
*only mvreg combines the results for you for mi estimation

*test income coefficient is equal across the two equations
lincom _b[safety_violent:income] - _b[safety_prop:income]
******************************************************************

******************************************************************
*now lets conduct imputation across the two models
restore

mi set mlong
mi register imputed safety_violent safety_prop income race
mi register regular district
preserve

*note for the ordinal data we could use censored regression and round the values.
*or use ordinal logistic regression.
*here I used truncreg for safety (so they are included as linear predictors of each other),
*but use ordinal logistic for income, so it is categorial otherwise
mi impute chained (truncreg, ll(1) ul(5) include(i.district)) safety_prop safety_violent (ologit, include(i.district)) income (mlogit, include(i.district)) race, add(5) rseed(10)		  
*note if you get perfect seperation add the augment option after rseed().
			  
*You do not need to round income for subsequent regression models
mi estimate (diff: _b[safety_violent:income] - _b[safety_prop:income]): mvreg safety_violent safety_prop = income i.race

*very similar results
******************************************************************










