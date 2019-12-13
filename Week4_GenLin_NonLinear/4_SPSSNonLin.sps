* Encoding: UTF-8.
DATASET CLOSE ALL.
OUTPUT CLOSE ALL.

*This syntax conducts negative binomial regression analysis.
*Also shows using restricted cubic splines.

FILE HANDLE data /NAME = "C:\Users\axw161530\Box Sync\Classes\Sem_ResearchAnalysis\Code_Snippets\4_NonLinearRegression".

*******************************************************************************.
*Importing the CSV file into SPSS.
GET DATA  /TYPE=TXT
  /FILE="data\DC_Crime_MicroPlaces.csv"
  /ENCODING='Locale'
  /DELCASE=LINE
  /DELIMITERS=","
  /QUALIFIER='"'
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /IMPORTCASE=ALL
  /VARIABLES=
  MarID F6.0
  Latitude F13.10
  Longitude F14.10
  TotalCrime F2.0
  OffN1 F1.0
  OffN2 F1.0
  OffN3 F1.0
  OffN4 F1.0
  OffN5 F1.0
  OffN6 F1.0
  OffN7 F1.0
  OffN8 F2.0
  OffN9 F1.0
  TypeA F1.0
  TypeANeigh F1.0
  TypeB F1.0
  TypeBNeigh F1.0
  TypeC_D F1.0
  TypeC_DNeigh F2.0
  CFS1 F1.0
  CFS1Neigh F2.0
  CFS2 F2.0
  CFS2Neigh F2.0
  LitterCans F1.0
  ToxicRelease_joinedSU F1.0
  Vacant_MergedSU F1.0
  GreenSites F1.0
  Trees_JoinedSU F2.0
  StreetLights F2.0
  BusStops F1.0
  HalfwayHouse F1.0
  HIVAids_JoinedSU F1.0
  Hospital_JoinedSU F1.0
  Library F1.0
  MetroEntr F1.0
  PlacesWorship F1.0
  PoliceStations F1.0
  ShoppingCenters F1.0
  SidewalkCafe F1.0
  WirelessHotSpot F1.0
  School F1.0
  Rec F1.0
  Univ F1.0
  PubHouse F1.0
  Park F1.0
  Intersection F1.0
  RoadAreaLn F16.14
  SidewalkAreaLn F16.14
  LnArea F16.14
  RCSLnArea1 A21
  RCSLnArea2 A21
  RCSLnArea3 A21
  RCSLnArea4 A21
  RCSLnArea5 A21
  XMeters F11.4
  XMetersScale A19
  XCor1 F16.14
  XCor2 F16.15
  XCor3 A18
  XCor4 A21
  XCor5 F16.15
  XCor6 F17.16
  YMeters F11.4
  YMetersScale A18
  YCor1 F16.13
  YCor2 F16.13
  YCor3 F16.14
  YCor4 A21
  YCor5 A21
  YCor6 F17.16
  YCor7 F16.15
  YCor8 F17.16
  XYScale F16.14
  XYRcs1 A19
  XYRcs2 A21
  XYRcs3 A21
  PredLogCrimeGen F18.16
  StdErrPredLogCrimeGen F17.16
  PredMeanCrimeGen F16.15
  CIMeanCrimeLGen A18
  CIMeanCrimeHGen F16.15
  LevValGen A19
  StdPearResidGen A18
  DevResValGen F18.16
  LikliResidGen F18.16
  CooksValGen A21.
CACHE.
EXECUTE.
DATASET NAME CrimeDC.


*Compute a new variable, total number of alcohol licenses.
COMPUTE AlcLic = TypeA + TypeB + TypeC_D.
*Case does not matter most of the time in SPSS.
*******************************************************************************.

*******************************************************************************.
*Here we are going to estimate several regression models and use those to predict.
*New data, in SPSS you do this by saving the model parameters and scoring new data.

*Linear model.
REGRESSION
  /DEPENDENT TotalCrime
  /METHOD=ENTER AlcLic CFS1 CFS2
  /OUTFILE = MODEL('data\LinModel.xml').

FREQ TotalCrime /STATISTICS = MEAN VAR.
*Variance is much higher than mean.
*Also with a mean of 1.51, you would expect there to be how many zeroes?.
IF $casenum = 1 PoissonZero = PDF.POISSON(0,1.51).
EXECUTE.
*22%, versus and observed 64%.
*So negative binomial is probably a better option than poisson.
GENLIN TotalCrime WITH AlcLic CFS1 CFS2
  /MODEL AlcLic CFS1 CFS2 DISTRIBUTION=NEGBIN(MLE) LINK=LOG
  /SAVE MEANPRED(PredMeanCrime)
  /OUTFILE MODEL = 'data\NBModel.xml'.

*Need to define some additional functions to tell whether this provides good predictions.
*******************************************************************************.


*******************************************************************************.
*MACROS for use in negative binomial predictions.
*See https://andrewpwheeler.wordpress.com/2014/02/17/negative-binomial-regression-and-predicted-probabilities-in-spss/.
*For discussion.
*See also https://andrewpwheeler.wordpress.com/2015/01/03/translating-between-the-dispersion-term-in-a-negative-binomial-regression-and-random-variables-in-spss/.

*Factorial.
DEFINE !FACT (!POSITIONAL = !ENCLOSE("(",")"))
( EXP(LNGAMMA((!1)+1)) )
!ENDDEFINE.

*Complete Gamma.
DEFINE !GAMMAF (!POSITIONAL = !ENCLOSE("(",")"))
( EXP(-1)/(!1)/(CDF.GAMMA(1,(!1),1) - CDF.GAMMA(1,(!1)+1,1)) )
!ENDDEFINE.

*Predict negative binomial probability for given integer.
*Out is new variable name - gives the probability for that particular integer.
*PredN is the predicted mean.
*Disp is the estimate of the dispersion.
*Int is the integer value being predicted.
DEFINE !PredNB (Out = !TOKENS(1)
               /PredN = !TOKENS(1)
                        /Disp = !TOKENS(1)
                        /Int = !TOKENS(1) )
COMPUTE #a = (!Disp)**(-1).
COMPUTE #mu = !PredN.
COMPUTE #Y = !Int.
COMPUTE #1 = (!GAMMAF(#Y + #a))/(!FACT(#Y)*!GAMMAF(#a)).
COMPUTE #2 = (#a/(#a+#mu))**#a.
COMPUTE #3 =  (#mu/(#a + #mu))**#Y.
COMPUTE !Out =  #1*#2*#3.
!ENDDEFINE.

*This gives a range of predictions from 0 to Num.
*So produces predictions over many integers.
DEFINE !PredNBRange (Num = !TOKENS(1)
                    /Mean = !TOKENS(1)
                    /Disp = !TOKENS(1)
                    /Stub = !TOKENS(1) )
!DO !I = 0 !TO !Num
  !LET !Base = !CONCAT(!Stub,!I)
  !PredNB Out = !Base PredN = !Mean Disp = !Disp Int = !I.
!DOEND 
!ENDDEFINE.
*******************************************************************************.


*Now we can see how well the estimated proportions of our negative binomial model fits the actual data.
*Take dispersion from the regression output.
*Lets see how well this model predicts zeroes.

SET MPRINT ON.
!PredNB Out = NB_0 PredN = PredMeanCrime Disp = 4.139833 Int = 0.
FREQ NB_0 /FORMAT = NOTABLE /STATISTICS = SUM.
SET MPRINT OFF.
*it is a predicted total of 13,774.77 zeroes, which is.
*13774.77/21506 = 0.64.
*Basically spot on with the observed 64% zeroes in the sample.

**************.
*Now I am going to make a new dataset and graph some of the predicted responses given different inputs.
*This way I can compare predictions for linear regression versus negative binomial.

INPUT PROGRAM.
LOOP #i = 0 TO 10.
  COMPUTE CFS1 = #i.
  END CASE.
END LOOP.
END FILE.
END INPUT PROGRAM.
DATASET NAME Predictions.
DATASET ACTIVATE Predictions.
*Fixing the other covariate values.
COMPUTE CFS2 = 5.
COMPUTE AlcLic = 0.
FORMATS CFS1 CFS2 AlcLic (F1.0).

*Now this is how you apply prior models to new data in SPSS.
MODEL HANDLE NAME=LinearMod FILE='data\LinModel.xml'.
COMPUTE PredLinMod=APPLYMODEL(LinearMod, 'PREDICT').
COMPUTE SELinMod=APPLYMODEL(LinearMod, 'STDDEV').
EXECUTE.
MODEL CLOSE NAME=LinearMod.

MODEL HANDLE NAME=NBMod FILE='data\NBModel.xml'.
COMPUTE PredNBMod=APPLYMODEL(NBMod, 'PREDICT').
COMPUTE SENBMod=APPLYMODEL(NBMod, 'STDDEV').
EXECUTE.
MODEL CLOSE NAME=NBMod.

*Now make a nice graph of these differences.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=CFS1 PredLinMod PredNBMod MISSING=LISTWISE 
    REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: CFS1=col(source(s), name("CFS1"))
  DATA: PredLinMod=col(source(s), name("PredLinMod"))
  DATA: PredNBMod=col(source(s), name("PredNBMod"))
  GUIDE: axis(dim(1), label("CFS1"), delta(1))
  GUIDE: axis(dim(2), label("Predicted Number of Crimes per Street Unit"))
  GUIDE: text.footnote(label("Holding CFS2 at 5 and Alcohol Licenses at 0"))
  ELEMENT: line(position(CFS1*PredLinMod), color(color.black))
  ELEMENT: line(position(CFS1*PredNBMod), color(color.red))
END GPL.

*******************************************************************************.
*NON-LINEAR EFFECTS IN LINEAR AND GENLIN MODELS.

DATASET ACTIVATE CrimeDC.
DATASET CLOSE Predictions.

*This is my macro to estimate restricted cubic splines, see.
*https://andrewpwheeler.wordpress.com/2013/06/06/restricted-cubic-splines-in-spss/.
INSERT FILE = "data\MACRO_RCS.sps".

*If you do it this way, the knot locations are set at specific quantiles.
*Harder to do the predictions later on.
*rcs x = LnArea n = 7.
*So lets just do it this was so it is easier.
!rcs x = LnArea Loc = [6.759710  7.872095  8.230873  8.499696  8.774815  9.159635 10.343298].
*Knot locations are at the 0.025, 0.1833, 0.3417, 0.5, 0.6583, 0.8167, and 0.975 quantiles.
*For comparison to R results.

*Now lets include these spline factors on the right hand side of the regression model.
REGRESSION
  /DEPENDENT TotalCrime
  /METHOD=ENTER AlcLic CFS1 CFS2 splinex1 splinex2 splinex3 splinex4 splinex5
  /OUTFILE = MODEL('data\LinModel_wSplines.xml').

GENLIN TotalCrime WITH AlcLic CFS1 CFS2 splinex1 splinex2 splinex3 splinex4 splinex5
  /MODEL AlcLic CFS1 CFS2 splinex1 splinex2 splinex3 splinex4 splinex5 DISTRIBUTION=NEGBIN(MLE) LINK=LOG
  /OUTFILE MODEL = 'data\NBModel_wSplines.xml'.

*Now we want to interpret that non-linearity.
*We should graph the predictions!.
*Looking at the coefficients is not very informative.

*Now lets do a set of predictions varying the area parameter, to see the non-linear effect.
INPUT PROGRAM.
LOOP #i = 0 TO 130.
  COMPUTE LnArea = #i/10.
  END CASE.
END LOOP.
END FILE.
END INPUT PROGRAM.
DATASET NAME Predictions.
DATASET ACTIVATE Predictions.
*Fixing the other covariate values.
COMPUTE CFS1 = 0.
COMPUTE CFS2 = 5.
COMPUTE AlcLic = 0.
FORMATS CFS1 CFS2 AlcLic (F1.0).
*Creating the splines.
!rcs x = LnArea Loc = [6.759710  7.872095  8.230873  8.499696  8.774815  9.159635 10.343298].


*Now this is how you apply prior models to new data in SPSS.
MODEL HANDLE NAME=LinearMod FILE='data\LinModel_wSplines.xml'.
COMPUTE PredLinMod=APPLYMODEL(LinearMod, 'PREDICT').
COMPUTE SELinMod=APPLYMODEL(LinearMod, 'STDDEV').
EXECUTE.
MODEL CLOSE NAME=LinearMod.

MODEL HANDLE NAME=NBMod FILE='data\NBModel_wSplines.xml'.
COMPUTE PredNBMod=APPLYMODEL(NBMod, 'PREDICT').
COMPUTE SENBMod=APPLYMODEL(NBMod, 'STDDEV').
EXECUTE.
MODEL CLOSE NAME=NBMod.

*Now make a graph of these differences.
FORMATS LnArea PredLinMod PredNBMod (F2.0).
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=LnArea PredLinMod PredNBMod MISSING=LISTWISE 
    REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: LnArea=col(source(s), name("LnArea"))
  DATA: PredLinMod=col(source(s), name("PredLinMod"))
  DATA: PredNBMod=col(source(s), name("PredNBMod"))
  GUIDE: axis(dim(1), label("Log Area"), delta(1))
  GUIDE: axis(dim(2), label("Predicted Number of Crimes per Street Unit"))
  GUIDE: text.footnote(label("Holding CFS1 at 0, CFS2 at 5, and Alcohol Licenses at 0"))
  ELEMENT: line(position(LnArea*PredLinMod), color(color.black))
  ELEMENT: line(position(LnArea*PredNBMod), color(color.red))
END GPL.

*You can see that each model is highly non-linear and produces quite similar predictions.

