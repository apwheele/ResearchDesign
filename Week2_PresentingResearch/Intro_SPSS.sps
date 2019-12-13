* Encoding: UTF-8.
*This code snippet shows how to create a reproducible data analysis in SPSS.
*Comments in SPSS start with an asterisk and need to end with a period.

*Clearing any prior SPSS datasets and output windows that are open.
DATASET CLOSE ALL.
OUTPUT CLOSE ALL.

*path where data is located.
FILE HANDLE data /NAME = "C:\Users\axw161530\Dropbox\Classes\Sem_ResearchAnalysis\Code_Snippets\2_Reproducible_Descriptives".

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
COMPUTE AlcLic = TypeA + TypeB + tYpec_D.
*Case does not matter most of the time in SPSS.

*Descriptive statistics for all Crimes and Alcohol licenses on the street plus a histogram.
FREQUENCIES VARIABLES= AlcLic TotalCrime /FORMAT = NOTABLE /STATISTICS = MIN MAX MEAN STDDEV /NTILES = 4 /HISTO.

*Scatterplot copy-pasted from output.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=AlcLic[LEVEL=SCALE] TotalCrime MISSING=LISTWISE 
    REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: AlcLic=col(source(s), name("AlcLic"))
  DATA: TotalCrime=col(source(s), name("TotalCrime"))
  GUIDE: axis(dim(1), label("AlcLic"))
  GUIDE: axis(dim(2), label("TotalCrime"))
  ELEMENT: point(position(AlcLic*TotalCrime))
END GPL.

*Scatterplot updated with transparency and smaller points.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=AlcLic[LEVEL=SCALE] TotalCrime MISSING=LISTWISE 
    REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: AlcLic=col(source(s), name("AlcLic"))
  DATA: TotalCrime=col(source(s), name("TotalCrime"))
  GUIDE: axis(dim(1), label("AlcLic"))
  GUIDE: axis(dim(2), label("TotalCrime"))
  ELEMENT: point(position(AlcLic*TotalCrime), size(size."4"), transparency.exterior(transparency."0.85"))
END GPL.

*Binned scatterplot showing effects for 0 through 10 licenses on the street.
FORMATS AlcLic (F2.0).
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=AlcLic[LEVEL=SCALE] MEANSE(TotalCrime, 
    2)[name="MEAN_TotalCrime" LOW="MEAN_TotalCrime_LOW" HIGH="MEAN_TotalCrime_HIGH"] COUNT() MISSING=LISTWISE 
    REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: AlcLic=col(source(s), name("AlcLic"))
  DATA: MEAN_TotalCrime=col(source(s), name("MEAN_TotalCrime"))
  DATA: LOW=col(source(s), name("MEAN_TotalCrime_LOW"))
  DATA: HIGH=col(source(s), name("MEAN_TotalCrime_HIGH"))
  DATA: COUNT=col(source(s), name("COUNT"))
  GUIDE: axis(dim(1), label("Alcohol Licenses"), delta(1))
  GUIDE: axis(dim(2), label("Mean Crime"))
  GUIDE: text.footnote(label("Error Bars: +/- 2 SE"))
  SCALE: linear(dim(1), min(0.5), max(19.5))
  ELEMENT: edge(position(region.spread.range(AlcLic*(LOW+HIGH))))
  ELEMENT: point(position(AlcLic*MEAN_TotalCrime), color.interior(color.black), color.exterior(color.white))
END GPL.
*can add "label(COUNT) into point element to show total counts.

*This will save the output.
OUTPUT SAVE OUTFILE='data\Week2_SPSSOutput.spv'.

*This will export any figures to PNG.
OUTPUT EXPORT /PNG IMAGEROOT="data\Week2_SPSS.png".

*Can export the output to a PDF file as well.
OUTPUT EXPORT /PDF DOCUMENTFILE="data\Week2_SPSS.pdf".


