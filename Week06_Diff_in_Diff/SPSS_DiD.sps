* Encoding: UTF-8.
DATASET CLOSE ALL.
OUTPUT CLOSE ALL.

FILE HANDLE data /NAME = "C:\Users\axw161530\Box Sync\Classes\Sem_ResearchAnalysis\Code_Snippets\6_Diff_in_Diff".

GET FILE = "data\Monthly_Sim_Data.sav".
DATASET NAME Shootings.

*Look at the pre-post mean tables I suggested.
DATASET ACTIVATE Shootings.
MEANS TABLES=Y BY Exper BY Post
  /CELLS=MEAN STDDEV.

***********************************************************************************************.
*Now calculate the linear regression.
*Easier to generate hypothetical outcome later on if you generate interaction yourself.
COMPUTE PostExper = Exper*Post.
EXECUTE.

*Linear model.
GENLIN Y WITH Exper Post PostExper
  /MODEL Exper Post PostExper DISTRIBUTION=NORMAL LINK=IDENTITY
  /OUTFILE MODEL='data\LinModel.xml'.

*Poisson model.
GENLIN Y WITH Exper Post PostExper
  /MODEL Post Exper PostExper DISTRIBUTION=POISSON LINK=LOG
  /OUTFILE MODEL='data\PoisModel.xml'.


*Now can look at the expected hypothetical outcomes under the different models.
*First four rows are actual data -- last row is hypothetical.
DATA LIST FREE /Exper Post PostExper.
BEGIN DATA
0 0 0
0 1 0
1 0 0
1 1 1
1 1 0
END DATA.
DATASET NAME PredProb.

*Applying the predictions.
MODEL HANDLE NAME=LinModel FILE='data\LinModel.xml'.
COMPUTE PredLin=APPLYMODEL(LinModel, 'PREDICT').
COMPUTE LinSE=APPLYMODEL(LinModel, 'STDDEV').
EXECUTE.
MODEL CLOSE NAME=LinModel.

MODEL HANDLE NAME=PoisModel FILE='data\PoisModel.xml'.
COMPUTE PredPois=APPLYMODEL(PoisModel, 'PREDICT').
COMPUTE PoisSE=APPLYMODEL(PoisModel, 'STDDEV').
EXECUTE.
MODEL CLOSE NAME=PoisModel.

*Make a nice graph showing the hypothetical differences.
COMPUTE Type = Exper.
IF Exper = 1 AND Post = 1 AND PostExper = 0 Type = 2.
VALUE LABELS Type
 0 'Control'
 1 'Experiment'
 2 'Hypothetical without Treatment'
.
FORMATS Type Post Exper PostExper (F1.0) PredLin LinSE (F2.0).
VALUE LABELS Post 0 'Pre' 1 'Post'.
EXECUTE.

*Linear model.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=Post PredLin Type LinSE MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: Post=col(source(s), name("Post"), unit.category())
  DATA: PredLin=col(source(s), name("PredLin"))
  DATA: LinSE=col(source(s), name("LinSE"))
  DATA: Type=col(source(s), name("Type"), unit.category())
  TRANS: low = eval(PredLin - 2*LinSE)
  TRANS: hig = eval(PredLin + 2*LinSE)
  COORD: rect(dim(1,2), cluster(3,0))
  GUIDE: axis(dim(3))
  GUIDE: axis(dim(2), label("Predicted Means (Linear Model)"))
  GUIDE: legend(aesthetic(aesthetic.color.interior))
  SCALE: linear(dim(2), include(0))
  ELEMENT: edge(position(region.spread.range(Type*(low+hig)*Post)), color.interior(Type))
  ELEMENT: point(position(Type*PredLin*Post), color.interior(Type), color.exterior(color.white))
END GPL.

*Poisson model.
*Use the delta method to get standard errors for the predicted means from Poisson reg.
*What SPSS gives you are the standard errors for the linear model.
*Pretty easy with Poisson models, see https://stats.idre.ucla.edu/r/faq/how-can-i-estimate-the-standard-error-of-transformed-regression-parameters-in-r-using-the-delta-method/.
*For the example with exponentiated coefficients.

*Note the more complicated.
*COMPUTE PoisSEDelta = SQRT(PredPois*(PoisSE**2)*PredPois).
*Is equivalent to.
COMPUTE PoisSEDelta = PredPois*PoisSE.
FORMATS PredPois PoisSEDelta (F2.0).
EXECUTE.

GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=Post PredPois Type PoisSEDelta MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: Post=col(source(s), name("Post"), unit.category())
  DATA: PredPois=col(source(s), name("PredPois"))
  DATA: PoisSEDelta=col(source(s), name("PoisSEDelta"))
  DATA: Type=col(source(s), name("Type"), unit.category())
  TRANS: low = eval(PredPois - 2*PoisSEDelta)
  TRANS: hig = eval(PredPois + 2*PoisSEDelta)
  COORD: rect(dim(1,2), cluster(3,0))
  GUIDE: axis(dim(3))
  GUIDE: axis(dim(2), label("Predicted Means (Poisson Model)"))
  GUIDE: legend(aesthetic(aesthetic.color.interior))
  SCALE: linear(dim(2), include(0))
  ELEMENT: edge(position(region.spread.range(Type*(low+hig)*Post)), color.interior(Type))
  ELEMENT: point(position(Type*PredPois*Post), color.interior(Type), color.exterior(color.white))
END GPL.

*May be better to estimate confidence intervals on the linear scale and then exponentiate.
*I'm guessing that is what Stata does, because their confidence intervals are not symmetric on the linear scale.
