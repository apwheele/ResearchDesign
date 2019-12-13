This weeks dataset is a simplified version of the Dallas community survey in 2016. See below for the codebook and value labels. Note that the age variable is my best guess is likely wrong (they binned it in the released survey, but there is no meta-data on what the bin ranges are) - but I'm guessing the ordinal order is correct. For your code snippet I have you do multiple imputation of the safety variables, income, and race (including district as a predictor as well, even though it has no missing data) - then conduct two regression equations, predicting perceptions of violent and property safety as a function of income, and then test if the income coefficient is equal across the two models. The idea is those with more income (and likely more property) may have more fear of their stuff being stolen, so the income coefficient should be negative or at least smaller than violent.

For your homework, I want you to include more of the variables in the multiple imputation process. Include gender, edu, age, and yearsdallas in the equation. Remember to keep the prediction equations realistic (e.g. yearsdallas is effectively a continuous variable). Also continue to include district to help predict the imputations. 

For your homework, I want you to make a regression table that compares the coefficient estimates for the complete cases versus the regression estimates based on 5 multiple imputations. Based on this, interpret whether there are substantive differences in your interpretation of the income estimates on perceptions of safety for the complete case analysis versus the multiple imputed dataset.

------------------------------------
CODEBOOK FOR THIS DALLAS CITY SURVEY SUBSET, 2016

Safety_Violent	Q6, How safe do you feel: From violent crime (rape, assault, robbery)
Safety_Prop		Q6, How safe do you feel: From property crime (burglary, theft)
Gender			Q47, What is your gender? [Other listed as missing]
Race			Combined race and hispanic origin, Q39 & Q40
District		District survey was from
Income			Your total annual household income
Edu				Q43, Your highest degree or level of education
Age				Q35, What is your age (binned) - these bins are probably not right!
YearsDallas		Q33, How many years have you lived in Dallas?
OwnHome			Q37, Do you own or rent your home?

Safety_Violent	
	1	Very Unsafe
	2	Unsafe
	3	Neither Safe or Unsafe
	4	Safe
	5	Very Safe
	9	Do not know or Missing
Safety_Prop	
	1	Very Unsafe
	2	Unsafe
	3	Neither Safe or Unsafe
	4	Safe
	5	Very Safe
	9	Do not know or Missing
Gender	
	1	Male
	2	Female
	9	Missing
Race	
	1	Black
	2	White
	3	Hispanic
	4	Other
	9	Missing
Income	
	1	Less than 25k
	2	25k to 50k
	3	50k to 75k
	4	75k to 100k
	5	over 100k
	9	Missing
Edu	
	1	Less than High School
	2	High School
	3	Some above High School
	9	Missing
Age	
	1	18-24
	2	25-34
	3	35-44
	4	45-54
	5	55+
	9	Missing
OwnHome	
	1	Own
	2	Rent
	9	Missing
YearsDallas
	999	Missing


Original data can be found at http://dallascityhall.com/government/citymanager/CPE/Pages/Community-Survey.aspx
Original instrument can be found at http://dallascityhall.com/government/citymanager/CPE/_layouts/15/WopiFrame.aspx?sourcedoc=/government/citymanager/CPE/DCH%20Documents/Dallas%202016%20DF%20Survey%20Findings%20Report%20-%20June%209%2c%202016.pdf&action=default