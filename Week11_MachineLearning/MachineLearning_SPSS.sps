* Encoding: UTF-8.
DATASET CLOSE ALL.
OUTPUT CLOSE ALL.

*This syntax shows how to estimate several machine learning models in SPSS.
*Some of these just call the R libraries, so you need to have the R Essentials installed on the machine.

FILE HANDLE data /NAME = "C:\Users\axw161530\Box Sync\Classes\Sem_ResearchAnalysis\Code_Snippets\11_MachineLearning".

PRESERVE.
SET DECIMAL DOT.
GET DATA  /TYPE=TXT
  /FILE="data\PreppedCompas.csv"
  /ENCODING='UTF8'
  /DELCASE=LINE
  /DELIMITERS=","
  /QUALIFIER='"'
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /DATATYPEMIN PERCENTAGE=95.0
  /VARIABLES=
  person_id AUTO
  screening_date AUTO
  Recid AUTO
  Exposure AUTO
  FirstArrest_Date AUTO
  PostDays AUTO
  FirstArrest_Charge AUTO
  PostArr AUTO
  Recid30 AUTO
  Exposure30 AUTO
  FirstArrest_Date30 AUTO
  PostDays30 AUTO
  FirstArrest_Charge30 AUTO
  PostArr30 AUTO
  LastArrest_Date AUTO
  LastArrest_Charge AUTO
  PostScreen AUTO
  race AUTO
  sex AUTO
  dob AUTO
  YearsScreening AUTO
  age_cat AUTO
  marital_status AUTO
  CompScore.1 AUTO
  CompScore.2 AUTO
  CompScore.3 AUTO
  juv_fel_count AUTO
  juv_misd_count AUTO
  juv_other_count AUTO
  priors_count AUTO
  JailDays AUTO
  c_charge_degree AUTO
  c_charge_desc AUTO
  is_recid AUTO
  num_r_cases AUTO
  r_charge_degree AUTO
  r_charge_desc AUTO
  is_violent_recid AUTO
  vr_charge_degree AUTO
  vr_charge_desc AUTO
  /MAP.
RESTORE.
CACHE.
EXECUTE.
DATASET NAME CompasData.
DATASET ACTIVATE CompasData.

*Changing factor variable Set into Male dummy variable.
COMPUTE Male = (Sex = "Male").
FORMATS Male (F1.0).

*Need to set variable levels for R procedures.
VARIABLE LEVEL Recid30 (NOMINAL).
VARIABLE LEVEL Male YearsScreening CompScore.1 CompScore.2 CompScore.3 juv_fel_count (SCALE).
EXECUTE.

*Create a training and a hold out set, will use a 30% hold out set.
SHOW N.
*With 11,757 observations this is 0.3*11757 = 3528 observations.
*This randomly chooses who is in the test and who is in the training set.
*The seed will make it so you can replicate though.
SET SEED 10.
COMPUTE Rand = RV.UNIFORM(0,1).
SORT CASES BY Rand.
COMPUTE Train = ($CASENUM >= 3528).
EXECUTE.
*Make sure the test and train sets are totally different.
DATASET COPY Test.
DATASET ACTIVATE Test.
SELECT IF Train = 0.
EXECUTE.

DATASET ACTIVATE CompasData.
SELECT IF Train = 1.
EXECUTE.

*********************************************************.
*Now we can fit our models.

*Logit model.
LOGISTIC REGRESSION VARIABLES = Recid30 WITH Male YearsScreening CompScore.1 CompScore.2 CompScore.3 juv_fel_count 
  /OUTFILE = MODEL("data\Logit1.xml").

*SPSSINC RANFOR and STATS GBM might need to be installed on your machine.
*My V25 I think they were installed by default.

*Random Forest.
SPSSINC RANFOR DEPENDENT=Recid30 ENTER=Male YearsScreening CompScore.1 CompScore.2 CompScore.3 juv_fel_count UNSUPERVISED=NO
  /OPTIONS MISSING=ROUGH NUMTREES=500 
  /SAVE FOREST="data\RandFor.Rdata"
  /PRINT VARUSAGE
  /PLOT VARIABLEIMPORTANCE  MDSPLOT=NO.

VARIABLE LEVEL Recid30 (SCALE).
*Gen Boosted.
STATS GBM DISTRIBUTION=bernoulli DEPENDENT=Recid30 INDEPENDENT=Male YearsScreening CompScore.1 CompScore.2 CompScore.3 juv_fel_count INTERACTIONS=3
  /OPTIONS NTREES=100 MINNODESIZE=10 SHRINKAGE=.005 CVFOLDS=0 BAGFRAC=.5 TRAINFRAC=1.0 CVSTRAT=YES
  /OUTPUT RELIMP=YES MARGINALPLOTCOUNT=3 BOOSTPLOT=YES BOOSTPLOTMETHOD=oob 
  /SAVE MODELFILE="data\GBM_Mod.Rdata".

*Neural Network.
*Multilayer Perceptron Network.
MLP Recid30 (MLEVEL=N) WITH Male YearsScreening CompScore.1 CompScore.2 CompScore.3 juv_fel_count
 /RESCALE COVARIATE=STANDARDIZED 
  /PARTITION  TRAINING=7  TESTING=3  HOLDOUT=0
  /ARCHITECTURE   AUTOMATIC=YES (MINUNITS=1 MAXUNITS=50) 
  /CRITERIA TRAINING=BATCH OPTIMIZATION=SCALEDCONJUGATE LAMBDAINITIAL=0.0000005 
    SIGMAINITIAL=0.00005 INTERVALCENTER=0 INTERVALOFFSET=0.5 MEMSIZE=1000 
  /PRINT CPS NETWORKINFO SUMMARY 
  /PLOT NETWORK   
  /OUTFILE MODEL='data\NeuralNet.xml'   
  /STOPPINGRULES ERRORSTEPS= 1 (DATA=AUTO) TRAININGTIMER=ON (MAXTIME=15) MAXEPOCHS=AUTO 
    ERRORCHANGE=1.0E-4 ERRORRATIO=0.001 
 /MISSING USERMISSING=EXCLUDE .
*Dont be concerned with so much syntax -- most of this is the default in SPSS.
*********************************************************.

*********************************************************.
*Now generate predictions on our new set of data.

DATASET ACTIVATE Test.
DATASET CLOSE CompasData.

SORT CASES BY person_id.

*Scoring for logit model.
MODEL HANDLE NAME=LogitMod FILE='data\Logit1.xml'.
COMPUTE ProbL=APPLYMODEL(LogitMod, 'PROBABILITY', 1).
EXECUTE.
MODEL CLOSE NAME=LogitMod.

*Scoring for Neural Network.
MODEL HANDLE NAME=NN FILE='data\NeuralNet.xml'.
COMPUTE ProbNN=APPLYMODEL(NN, 'PROBABILITY', 1).
EXECUTE.
MODEL CLOSE NAME=NN.

SPSSINC RANPRED FOREST="data\RandFor.Rdata" PREDTYPE=PROBABILITIES CHECKMISSING=NO ID=person_id
  /SAVE PREDVALUES=RandFor.

VARIABLE LEVEL Recid30 (SCALE).
STATS GBMPRED MODELFILE="data\GBM_Mod.Rdata" ID=person_id
  /SAVE DATASET=GBM_Pred INCLUDEIND=NO
  /OPTIONS NTREES=100 BESTTREES=NO PREDSCALE=RESPONSE.

*Now merge those back into the main SPSS dataset.
DATASET ACTIVATE Test.
MATCH FILES FILE = *
  /FILE = 'RandFor'
  /FILE = 'GBM_Pred'.

DATASET CLOSE RandFor.
DATASET CLOSE GBM_Pred.

*Now lets look at the ROC curve for the different predictions.
*See also https://andrewpwheeler.wordpress.com/2015/03/09/roc-and-precision-recall-curves-in-spss/
*For precision-recall curces in SPSS.

VARIABLE LABELS
  ProbL 'Logistic Model'
  ProbNN 'Neural Network'
  Recid30_2 'Random Forest'
  Recid30_100 'GBM'
. 

ROC ProbL ProbNN Recid30_2 Recid30_100 BY Recid30 (1)
  /PLOT CURVE(REFERENCE)
  /PRINT SE.

*You can see the out of sample predictions are nearly equivalent between the different models.
*********************************************************.
