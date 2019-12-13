**************************************************************************
*START UP STUFF
*Set the working directory and plain text log file
cd "C:\Users\axw161530\Box Sync\Classes\Sem_ResearchAnalysis\Code_Snippets\5_PropensityScore"
*log the results to a text file
log using "Week5_Stata_PropScore.txt", text replace
*so the output just keeps going
set more off
*let stata know to search for a new location for stata plug ins
adopath + "C:\Users\axw161530\Documents\Stata_PlugIns"
*in this script I downloaded the matselrc plug in and the postrcspline
*to install on your own in the lab it would be
net set ado "C:\Users\axw161530\Documents\Stata_PlugIns"
*ssc install psmatch2
**************************************************************************

**************************************************************************
*PREPPING THE DATA
*Load in the csv data
import delimited Example_Dataset.csv

sort ïmyid
gen rownum = _n
**************************************************************************

**************************************************************************
*lets look at the crosstab of the outcome by treatment

tabulate treatment anyarrest, row chi2 exact
*statistically significant for chi-square or Fishers exact test

*lets look at imbalance for the treatment across the different categories
tabulate treatment race, row
tabulate treatment sex, row

by treatment, sort: summarize totalpriorarrests weight

*t-test of mean differents
ttest totalpriorarrests, by(treatment)
ttest weight_lbs, by(treatment)

*Cohen's D multiplied by 100 is the percentage bias
esize twosample totalpriorarrests, by(treatment) cohensd
*So a 36% bias with the marginal data
esize twosample weight_lbs, by(treatment) cohensd
*So a 4% bias
**************************************************************************


**************************************************************************
*now lets conduct some matching, estimate outcomes, and then check balance.

*Stata does not like my string variables
encode race, gen(race_n)
encode sex, gen(sex_n)


*lets look at the regression predicting treatment
logistic treatment i.race_n i.sex_n totalpriorarrests weight_lbs
predict treatProb

preserve

*one to one matching without replacement
psmatch2 treatment i.race_n i.sex_n totalpriorarrests weight_lbs, noreplacement neighbor(1) out(anyarrest)

*check for balance
pstest totalpriorarrests weight_lbs

*can do similar myself
replace _weight = 0 if missing(_weight)
keep if _weight >= 1

ttest totalpriorarrests, by(treatment)
ttest weight_lbs, by(treatment)
esize twosample totalpriorarrests, by(treatment) cohensd
esize twosample weight_lbs, by(treatment) cohensd

tabulate treatment race, row
tabulate treatment sex, row

*using logistic regression to assess outcomes, controlling for race and sex
logistic anyarrest i.treatment i.race_n i.sex_n
*on the probability scale
margins i.treatment

*to force exact matching, see the trick with generating new variables and use caliper
*http://www.stata.com/statalist/archive/2010-09/msg00944.html


restore
gen treatProb_wCat = treatProb + sex_n*100 + race_n*10000

psmatch2 treatment, pscore(treatProb_wCat) outcome(anyarrest) caliper(0.5) noreplacement neighbor(1)

replace _weight = 0 if missing(_weight)
keep if _weight >= 1

tabulate treatment race, row
tabulate treatment sex, row

*balance is worse on weight_lbs, but should not matter though
esize twosample totalpriorarrests, by(treatment) cohensd
esize twosample weight_lbs, by(treatment) cohensd
