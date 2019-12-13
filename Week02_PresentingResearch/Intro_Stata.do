*This is an introduction to reproducible analysis in Stata.
*Comments in Stata start with an asterisk, 
*but do not need to end with a period

*See these cheatsheets for advice in Stata, https://geocenter.github.io/StataTraining/portfolio/01_resource/

*Set the working directory and plain text log file
cd "C:\Users\axw161530\Dropbox\Classes\Sem_ResearchAnalysis\Code_Snippets\2_Reproducible_Descriptives"
*log the results to a text file
log using "Week2_Stata.txt", text replace
*so the output just keeps going
set more off

*Load in the csv data
import delimited DC_Crime_MicroPlaces.csv

*generate variable for all alcohol licenses
gen AlcLic = typea + typeb + typec_d

*descriptive statistics
summarize totalcrime AlcLic, detail

*histogram of crimes
histogram totalcrime

*scatterplot of alcohol licenses vs crimes
scatter totalcrime AlcLic

*not too informative

*Here I will aggregate the data to make a summarized chart for street units
*save the original dataset though
preserve

collapse (mean) MeanCrime=totalcrime (semean) se_crime=totalcrime (count) totalN=totalcrime , by(AlcLic)
gen Lowcrime = MeanCrime - 2*se_crime
gen Highcrime = MeanCrime + 2*se_crime
*lets make a nicer graph this time
graph twoway (rspike Lowcrime Highcrime AlcLic, lcolor(black) legend(off) ytitle("Mean Crime per Street Unit [+/- 2 Standard Errors]") xtitle("Alcohol Licenses") xlabel(0(1)20) ) (scatter MeanCrime AlcLic, mfcolor(black) mlcolor(white) legend(off) mlabel(totalN) mlabsize(tiny) mlabcolor(black) mlabposition(1) ), scheme(sj)
*save the graph as a PNG file
graph export Stata_SEGraph.png, replace

*I know more about making nice graphs is SPSS and R, do not ask me about nice graphs in Stata.
*I will not have any good advice.

*if you wanted to restore the main dataset
restore

**************.
*Finish the script.
drop _all 
exit, clear
**************.
