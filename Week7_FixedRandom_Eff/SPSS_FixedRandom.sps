* Encoding: UTF-8.
DATASET CLOSE ALL.
OUTPUT CLOSE ALL.

*This syntax conducts negative binomial regression analysis.
*Also shows using restricted cubic splines.

FILE HANDLE data /NAME = "F:\BoxData_11182019\Classes\Sem_ResearchAnalysis\Code_Snippets\7_FixedRandom_Effects".

*******************************************************************************.
*Importing the CSV file into SPSS.
GET DATA  /TYPE=TXT
  /FILE="data\DC_Crime_withAreas.csv"
  /ENCODING='UTF8'
  /DELCASE=LINE
  /DELIMITERS=","
  /QUALIFIER='"'
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /DATATYPEMIN PERCENTAGE=95.0
  /VARIABLES=
  MarID AUTO
  XMeters AUTO
  YMeters AUTO
  FishID AUTO
  XMetFish AUTO
  YMetFish AUTO
  TotalArea AUTO
  WaterArea AUTO
  AreaMinWat AUTO
  TotalLic AUTO
  TotalCrime AUTO
  CFS1 AUTO
  CFS2 AUTO
  CFS1Neigh AUTO
  CFS2Neigh AUTO
  /MAP.
CACHE.
EXECUTE.
DATASET NAME CrimeDC.
DATASET ACTIVATE CrimeDC.


*Compute a new variable, total number of 311 calls for service.
COMPUTE CFS = CFS1 + CFS2.
EXECUTE.


VARIABLE LEVEL FishID (NOMINAL).
*Fixed effects linear regression model using dummy variables.
GENLIN TotalCrime BY FishID WITH TotalLic CFS
  /MODEL TotalLic CFS FishID.

*Now estimate the model via demeaning.
AGGREGATE OUTFILE=* MODE=ADDVARIABLES
  /BREAK FishID
  /MeanCrime = MEAN(TotalCrime)
  /MeanLic = MEAN(TotalLic)
  /MeanCFS = MEAN(CFS)
.

COMPUTE DCrime = TotalCrime - MeanCrime.
COMPUTE DLic = TotalLic - MeanLic.
COMPUTE DCFS = CFS - MeanCFS.
EXECUTE.

*See that this has the same estimated coefficients - the standard error though.
*Is not correct.
REGRESSION
  /DEPENDENT DCrime
  /METHOD=ENTER DLic DCFS.

*Fitting a fixed effects negative binomial regression model.
*Takes about a minute.
GENLIN TotalCrime BY FishID WITH TotalLic CFS
  /MODEL TotalLic CFS FishID DISTRIBUTION=NEGBIN(MLE) LINK=LOG.


*Fitting a random effects negative binomial model.
VARIABLE LEVEL TotalLic CFS (SCALE).

*Need V25 or later for the SOLUTION=TRUE to get the empirical estimes of the random intercepts.

DATASET DECLARE Catter.

OMS
  /SELECT TABLES
  /IF SUBTYPES='Empirical Best Linear Unbiased Predictions'
  /DESTINATION FORMAT=SAV OUTFILE='Catter' VIEWER=YES
  /TAG='RandTable'.

GENLINMIXED
  /FIELDS TARGET=TotalCrime
  /TARGET_OPTIONS DISTRIBUTION=NEGATIVE_BINOMIAL
  /FIXED EFFECTS=TotalLic CFS
  /RANDOM USE_INTERCEPT=TRUE SUBJECTS=FishID SOLUTION = TRUE
  /SAVE PREDICTED_VALUES(PredRanEff).

OMSEND TAG='RandTable'.
EXECUTE.
DATASET ACTIVATE Catter.


*Lets make a catterpillar plot.
FORMATS Prediction Std.Error LowerBound UpperBound (F4.2).
SORT CASES BY Prediction (D).

GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=Var1 Prediction LowerBound UpperBound
  /GRAPHSPEC SOURCE=INLINE
  /FRAME INNER=YES.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: Var1=col(source(s), name("Var1"), unit.category())
  DATA: Prediction=col(source(s), name("Prediction"))
  DATA: LowerBound=col(source(s), name("LowerBound"))
  DATA: UpperBound=col(source(s), name("UpperBound"))
  SCALE: cat(dim(1), sort.data())
  GUIDE: axis(dim(1), null())
  GUIDE: axis(dim(2), label("BLUP"))
  SCALE: linear(dim(2), include(0))
  ELEMENT: edge(position(region.spread.range(Var1*(LowerBound + UpperBound))), size(size."0.5")))
  ELEMENT: point(position(Var1*Prediction), color.interior(color.black), size(size."1"))
END GPL.

DATASET ACTIVATE CrimeDC.
DATASET CLOSE Catter.

*************************************************************************************************************************.
*For versions V24 and earlier - abit harder to make the caterpillar plot.

*Fitting a random effects negative binomial model.
 * VARIABLE LEVEL TotalLic CFS (SCALE).
*Runs the mixed effect model.
 * GENLINMIXED
  /FIELDS TARGET=TotalCrime
  /TARGET_OPTIONS DISTRIBUTION=NEGATIVE_BINOMIAL
  /FIXED EFFECTS=TotalLic CFS
  /RANDOM USE_INTERCEPT=TRUE SUBJECTS=FishID
  /SAVE PREDICTED_VALUES(PredRanEff).

*Now to estimate the random effects, I need to demean the original data.
*To do this, I am going to subtract out the prediction based on the fixed coefficients.
*The left-over is the random effect.

 * COMPUTE RandPre = LN(PredRanEff).
 * COMPUTE FixedPred = -0.238898 + TotalLic*0.471995 + CFS*0.069824.
 * EXECUTE.

*The difference between these two is the estimated random effect.
 * COMPUTE RandInt = RandPre - FixedPred.
 * SORT CASES BY FishID.
 * MATCH FILES FILE = *
  /FIRST = FlagFirst
  /BY FishID.
 * EXECUTE.

*If you look at the data you will see that they are all the same.
*The should be approximately normally distributed with a mean close to zero.
*Only need to look at one observation per FishID.
 * TEMPORARY.
 * SELECT IF FlagFirst = 1.
 * FREQ RandInt /FORMAT = NOTABLE /STATISTICS = MEAN STDDEV VAR /HISTO.
 * EXECUTE.

*Unfortunately SPSS does not allow you to estimate the standard error.
*Of these random intercepts directly with generalized linear models.
*If you use mixed you can though (linear outcome) and can make a caterpillar plot.
 * MIXED TotalCrime BY FishID WITH TotalLic CFS
  /FIXED TotalLic CFS
  /RANDOM = FishID
  /SAVE FIXPRED(FixLin) PRED(FullPred) SEFIXP(SeFix) SEPRED(SeFull).

 * COMPUTE RandEff = FullPred - FixLin.
*This assumes zero correlation between fixed effects and random effects.
 * COMPUTE RandSE = SQRT( SeFull**2 + SeFix**2).
 * EXECUTE.

*Now can make a caterpillar plot.
*Individual 95% confidence interval around the random intercept.
 * TEMPORARY.
 * SELECT IF FlagFirst = 1.
 * GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=FishID RandEff RandSE MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE.
 * BEGIN GPL
  PAGE: begin(scale(900px,600px))
  SOURCE: s=userSource(id("graphdataset"))
  DATA: FishID=col(source(s), name("FishID"), unit.category())
  DATA: RandEff=col(source(s), name("RandEff"))
  DATA: RandSE=col(source(s), name("RandSE"))
  TRANS: Low = eval(RandEff - 2*RandSE)
  TRANS: Hig = eval(RandEff + 2*RandSE)
  GUIDE: axis(dim(1), label("FishID"))
  GUIDE: axis(dim(2), label("RandEff"))
  SCALE: cat(dim(1), sort.statistic(summary.mean(RandEff)), reverse())
  SCALE: linear(dim(2), include(0))
  ELEMENT: edge(position(region.spread.range(FishID*(Low + Hig))))
  ELEMENT: point(position(FishID*RandEff), size(size."4"), color.interior(color.black), color.exterior(color.white))
  PAGE: end()
END GPL.
 * EXECUTE.

*************************************************************************************************************************.

DATASET DECLARE Catter.

OMS
  /SELECT TABLES
  /IF SUBTYPES='Empirical Best Linear Unbiased Predictions'
  /DESTINATION FORMAT=SAV OUTFILE='Catter' VIEWER=YES
  /TAG='RandTable'.

*Now lets have the effect of alcohol outlets vary by neighborhood, using negative binomial model.
GENLINMIXED
  /FIELDS TARGET=TotalCrime
  /TARGET_OPTIONS DISTRIBUTION=NEGATIVE_BINOMIAL
  /FIXED EFFECTS=TotalLic CFS
  /RANDOM EFFECTS=TotalLic USE_INTERCEPT=TRUE SUBJECTS=FishID SOLUTION=TRUE
  /OUTFILE MODEL='data\NegBin.zip'.

OMSEND TAG='RandTable'.
EXECUTE.
DATASET ACTIVATE Catter.

*Lets make a catterpillar plot.
FORMATS Prediction Std.Error LowerBound UpperBound (F4.2).
SORT CASES BY Prediction (D).

*Same, just with variance of license effects.
TEMPORARY.
SELECT IF Var2="TotalLic".
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=Var1 Prediction LowerBound UpperBound
  /GRAPHSPEC SOURCE=INLINE
  /FRAME INNER=YES.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: Var1=col(source(s), name("Var1"), unit.category())
  DATA: Prediction=col(source(s), name("Prediction"))
  DATA: LowerBound=col(source(s), name("LowerBound"))
  DATA: UpperBound=col(source(s), name("UpperBound"))
  SCALE: cat(dim(1), sort.data())
  GUIDE: axis(dim(1), null())
  GUIDE: axis(dim(2), label("Random Effects Alcohol"))
  SCALE: linear(dim(2), include(0))
  ELEMENT: edge(position(region.spread.range(Var1*(LowerBound + UpperBound))), size(size."0.5")))
  ELEMENT: point(position(Var1*Prediction), color.interior(color.black), size(size."1"))
END GPL.
EXECUTE.


*Dont worry about the convergence error.
*Lets do a hypothetical now, the first leve is:
*Count crime = exp( -0.247 + 0.766*AlcLic + 0.07*CFS)

*But the variance around the AlcLic effect is 1.811.
*So the standard deviation of the effect is sqrt(1.811) ~= 1.3.

*So 2*SD = 2.6, so the high effect will be 2.6+0.8 = 3.4.
*And the low effect will then be          -2.6+0.8= -1.8.
*So the effect varies quite a bit by neighborhood in this example.

*If you want to look at the correlation between the two.
SORT CASES BY Var1 Var2.
CASESTOVARS /ID=Var1 /INDEX=Var2 /SEPARATOR="_".

GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=Prediction_Intercept Prediction_TotalLic 
    MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE
  /FRAME INNER=YES.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: Prediction_Intercept=col(source(s), name("Prediction_Intercept"))
  DATA: Prediction_TotalLic=col(source(s), name("Prediction_TotalLic"))
  GUIDE: axis(dim(1), label("Random Intercept"))
  GUIDE: axis(dim(2), label("Random Alcohol Effect"))
  ELEMENT: point(position(Prediction_Intercept*Prediction_TotalLic))
END GPL.

OUTPUT EXPORT /PNG IMAGEROOT="C:\Users\apwhe\Dropbox\Documents\BLOG\Caterpillar_SPSS\Catplot.PNG".
*******************************************************************************.






