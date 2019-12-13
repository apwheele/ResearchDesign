* Encoding: UTF-8.
DATASET CLOSE ALL.
OUTPUT CLOSE ALL.

FILE HANDLE data /NAME = "C:\Users\axw161530\Box Sync\Classes\Sem_ResearchAnalysis\Code_Snippets\5_PropensityScore".

*This is my macro to help estimate post balance stats.
*See https://andrewpwheeler.wordpress.com/2016/07/11/comparing-samples-post-matching-some-helper-functions-after-fuzzy-spss/.
INSERT FILE = "data\PropBalance_Macro.sps".

*Read in the data.
GET DATA  /TYPE=TXT
  /FILE="data\Example_Dataset.csv"
  /ENCODING='UTF8'
  /DELCASE=LINE
  /DELIMITERS=","
  /QUALIFIER='"'
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /DATATYPEMIN PERCENTAGE=95.0
  /VARIABLES=
  MyId AUTO
  MinDOB AUTO
  Weight_lbs AUTO
  Race AUTO
  Sex AUTO
  HZip AUTO
  Violent AUTO
  Prop AUTO
  Part2 AUTO
  Other AUTO
  Treatment AUTO
  AnyArrest AUTO
  TotalPriorArrests AUTO
  DaysOld_July15 AUTO
  /MAP.
CACHE.
EXECUTE.
DATASET NAME ExData.

*Estimate logistic regression to get the probability of selection into treatment.
*If you do not have stats for logistic, use PLUM.
LOGISTIC REGRESSION VARIABLES = Treatment WITH TotalPriorArrests, Weight_lbs, RACE, SEX 
  /SAVE PRED (PredProb).

*I need to recode the race and sex data to numerical variables for exact matching.
AUTORECODE RACE SEX /INTO RACE_N SEX_N.

*Now can use FUZZY to match variables.
*Here I am matching exactly on race and sex, but within a caliper on predicted probability.
FUZZY BY=PredProb RACE_N SEX_N SUPPLIERID=MyId NEWDEMANDERIDVARS=Match1 GROUP=Treatment
    EXACTPRIORITY=FALSE FUZZ=0.02 0 0 MATCHGROUPVAR=MGroup DRAWPOOLSIZE=CheckSize
/OPTIONS SAMPLEWITHREPLACEMENT=FALSE MINIMIZEMEMORY=TRUE SHUFFLE=TRUE SEED=10.
*If you want to draw more than 1, use "NEWDEMANDERIDVARS=Match1 Match2" to draw two controls.


*One person who was not matched, this sorts that person to the top.
 * SORT CASES BY Treatment (D) CheckSize (A).
*A white female.

*Now using my macro to estimate balance statistics.
!MatchedSample Dataset=ExData Id=MyId Case=Treatment MatchGroup=MGroup Controls=[Match1] MatchVars=[Weight_lbs TotalPriorArrests] OthVars=AnyArrest Race Sex.

*You can see the output for a table that shows the t-test of mean differences and standardized bias and bias reduction before and after matching for the continuous.
*Variables.

*Need to look at original data to see the differences in the crosstabs.
DATASET ACTIVATE ExData.
*Crosstabs in original.
CROSSTABS Race Sex BY Treatment /CELLS = COUNT COL.
*In only the matched sample.
DATASET ACTIVATE MatchedSamples.
CROSSTABS Race Sex BY Treatment /CELLS = COUNT COL.
*Balance was not too bad before, but exact matching on these.
*Shows now how it is perfect.

*Now estimate a t-test of mean differences on the OUTCOME (AnyArrest) for the original data.
DATASET ACTIVATE ExData.
T-TEST GROUPS=Treatment(0 1)
  /MISSING=ANALYSIS
  /VARIABLES=AnyArrest
  /CRITERIA=CI(.95).

*Vs the matched data.
DATASET ACTIVATE MatchedSamples.
T-TEST GROUPS=Treatment(0 1)
  /MISSING=ANALYSIS
  /VARIABLES=AnyArrest
  /CRITERIA=CI(.95).

*Comparison group changes from 0.05 to 0.08, so makes it not statistically significant anymore.

*Now can use logistic or whatever model on your matched sample.
*Can include continuous weight lbs in this example, but since exact matching on race and sex cannot include them.
*Will result in perfect separation.
DATASET ACTIVATE MatchedSamples.
LOGISTIC REGRESSION VARIABLES = AnyArrest WITH Treatment, Weight_lbs.


