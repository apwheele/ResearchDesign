* Encoding: UTF-8.
*Multiple imputation in SPSS.

DATASET CLOSE ALL.
OUTPUT CLOSE ALL.

FILE HANDLE data /NAME = "C:\Users\axw161530\Box Sync\Classes\Sem_ResearchAnalysis\Code_Snippets\8_MissingData_Analysis".

GET FILE = "data\MissingData_DallasSurv16.sav".
DATASET NAME MissData.

*Check percent of missing across all variables.
FREQ All /FORMAT = NOTABLE.
*All missing some except for District - this was not an answer someone filled out!.

*Lets make a variable that signifies if a case is missing across any variable.
COUNT MisComplete = Safety_Violent Safety_Prop Gender Race Income Edu Age YearsDallas OwnHome (MISSING).
FREQ MisComplete.
*1223 have complete cases, just under 81%, even though any one variable has a bit less missing.

*************************************************************************.
*Now lets do linear regressions with complete case dataset.
COMPUTE CompleteCase = (MisComplete = 0).
FILTER BY CompleteCase.

*This treats the different income categories as a continuous variable.
*Can use GLM to estimate seemingly unrelated regression in SPSS and test.
*equality of the two coefficients.
GLM Safety_Violent Safety_Prop BY Race WITH Income
  /DESIGN=Income Race
  /PRINT PARAMETER
  /LMATRIX Income 1
  /MMATRIX ALL 1 -1.

*If you have the R extension installed can check with the R package systemfit and seemingly unrelated regression.
*STATS EQNSYSTEM Violent: Safety_Violent = Income Race Prop: Safety_Violent = Income Race
*/OPTIONS METHOD=SUR COVMETHOD=GEOMEAN MAXITER=1 TOL=.00001
*/PRINT RESIDCOV=NO RESIDCOR=NO
*/SAVE RESIDUALS.
  
FILTER OFF.

*Both have similar effects, higher incomes result in less fear, even for property crime.
*But the effect is larger for property crime than it is for violent crime.
*************************************************************************.


*************************************************************************.
*Now lets conduct a multiple imputation analysis, SPSS needs the variables set to the right.
*Scale before conducting the analysis, so will turn the ordinal variables to SCALE.
*Otherwise it treats them like unique categories and predicts using multinomial logistic regression.

VARIABLE LEVEL Safety_Violent Safety_Prop Income (SCALE)
  /Race (NOMINAL).

*Note even though District does not have any missing data, can use it in the multiple imputation process.
*For homework setting MAXMODELPARAM to higher levels may be necessary.
DATASET DECLARE MultImput.
MULTIPLE IMPUTATION District Income Safety_Violent Safety_Prop Race
  /IMPUTE METHOD=AUTO NIMPUTATIONS=5 MAXMODELPARAM=200
  /CONSTRAINTS Safety_Violent (MIN=1 MAX=5 RND=1)
  /CONSTRAINTS Safety_Prop (MIN=1 MAX=5 RND=1)
  /CONSTRAINTS Income (MIN=1 MAX=5 RND=1)
  /OUTFILE IMPUTATIONS=MultImput.
*Notice the constraints on the outcomes, since it will use linear regression.
*Set the min/max, and set to rounding for integers.


*Now we can do analysis on our multiple imputed datasets.
DATASET ACTIVATE MultImput.  

GLM Safety_Violent Safety_Prop BY Race WITH Income
  /DESIGN=Income Race
  /PRINT PARAMETER
  /LMATRIX Income 1
  /MMATRIX ALL 1 -1.

*We can see that the differences are very similar across each of the models.
*This does not pool the results for you though.

*Can get pooled results for each individual equation, but this ignores the correlation between equations.
GENLIN Safety_Violent BY Race WITH Income
  /MODEL Income Race DISTRIBUTION=NORMAL LINK=IDENTITY.
  
GENLIN Safety_Prop BY Race WITH Income
  /MODEL Income Race DISTRIBUTION=NORMAL LINK=IDENTITY.

*Or you can stack the equations and estimate the interactions.
VARSTOCASES /MAKE Safety FROM Safety_Violent Safety_Prop /INDEX SafetyType.
RECODE SafetyType (2 = 0).
VALUE LABELS SafetyType 0 'Property' 1 'Violent'.

GENLIN Safety BY Race SafetyType WITH Income
  /MODEL SafetyType Income Income*SafetyType Race Race*SafetyType DISTRIBUTION=NORMAL LINK=IDENTITY.

*The interaction of SafetyType and Income is the difference between effect of Income on violent and property crime.
*************************************************************************.



