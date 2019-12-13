**************************************************************************
*START UP STUFF
*Set the working directory and plain text log file
cd "C:\Users\axw161530\Box Sync\Classes\Sem_ResearchAnalysis\Code_Snippets\7_FixedRandom_Effects"
*log the results to a text file
log using "Stata_FixedRandom.txt", text replace
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

*Load in csv file
import delimited DC_Crime_withAreas.csv

*Set the group variable
xtset fishid

*combined 311 calls for service
gen cfsAll = cfs1 + cfs2

*variable numbering within each fishid group
sort fishid
by fishid: generate group_Ord = _n
**************************************************************************

*Fixed effects linear model
xtreg totalcrime totallic cfsAll, fe

*Same as using a dummy variable
set matsize 700
reg totalcrime totallic cfsAll i.fishid

*fixed effects negative binomial model
xtnbreg totalcrime totallic cfsAll, fe

*random effects negative binomial - this allows us to actually plot the random effects
menbreg totalcrime totallic cfsAl || fishid:

preserve
keep if group_Ord==1

*lets predict and plot the random effects
predict re_means*, reses(se_means*) reffects

*this is the mean of the random effect, so to generate predictions of the counts
*need some fixed factor, like one bar and zero calls for service
gen pred_Count = exp(0.4567419 - 0.2205519 + re_means1)
*confidence intervals work because it is a monotonic transformation
gen low_CI = exp(0.4567419 - 0.2205519 + (re_means1 - 1.96*se_means1))
gen hig_CI = exp(0.4567419 - 0.2205519 + (re_means1 + 1.96*se_means1))

*generating rank
sort re_means1
gen rank_int = _n
twoway (rspike hig_CI low_CI rank_int, lwidth(0.1) lcolor(grey)) (scatter pred_Count rank_int, mcolor(black) msize(tiny))
*not super informative (Stata does not support transparency in plots)

restore

*Allow the effect of bars to vary between locations
menbreg totalcrime totallic cfsAl || fishid: totallic

*the variance is 0.05 (so the standard deviation is sqrt(0.05)=0.22, so that means the effect will have a pretty large range across the study area from the mean
*effect of 0.5

*can show this by predicting at 0 bars and then at 1 bar for each study area
keep if group_Ord==1
replace totallic = 0
replace cfsAll = 0

predict ZeroAlc
replace totallic = 1
predict OneAlc

gen Dif = OneAlc - ZeroAlc
histogram Dif
*in some areas one bar increases crimes by around 0.4, in others by alittle over 1


