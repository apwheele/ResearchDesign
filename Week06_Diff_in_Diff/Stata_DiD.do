**************************************************************************
*START UP STUFF
*Set the working directory and plain text log file
cd "C:\Users\axw161530\Box Sync\Classes\Sem_ResearchAnalysis\Code_Snippets\6_Diff_in_Diff"
*log the results to a text file
log using "Week6_Stata_DiD.txt", text replace
*so the output just keeps going
set more off
*let stata know to search for a new location for stata plug ins
adopath + "C:\Users\axw161530\Documents\Stata_PlugIns"
*in this script I downloaded the matselrc plug in and the postrcspline
*to install on your own in the lab it would be
net set ado "C:\Users\axw161530\Documents\Stata_PlugIns"
**************************************************************************

**************************************************************************
*PREPPING THE DATA
*Load in the dta file
use "Monthly_Sim_Data.dta", clear 

*Set the panel vars
tsset Exper Ord
**************************************************************************


*************************************************
*Example panel data difference in differences.

************************************************
*linear model
regress Y i.Exper i.Post Exper#Post

*predicted margins
margins Post#Exper

*the hypothetical outcome
lincom _cons + 1.Exper + 1.Post
************************************************


************************************************
*Poisson model, using gee to account for correlated errors (could do the same for the linear model)
*note the tsset was necessary to do this

xtgee Y i.Exper i.Post Exper#Post, family(poisson) corr(ar1)

*predicted margins
margins Post#Exper

*the hypothetical outcome
nlcom exp(_b[1.Exper] + _b[1.Post]  + _b[_cons])
************************************************

*Note in Stata to force the month variable to be a dummy variable, can use either
* i.Month [or generate a set of dummy variables using]
* tabulate Month, gen(m)
*see https://andrewpwheeler.wordpress.com/2016/05/12/some-stata-notes-difference-in-difference-models-and-postestimation-commands/


**************.
*Finish the script.

drop _all 
exit, clear
**************.
