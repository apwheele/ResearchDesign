We are back to using the dataset of crime reported at street units in DC. This dataset contains a neighborhood level variable, FishID that the street units are nested within. This is a regular grid over DC meant to represent neighborhoods, see https://andrewpwheeler.wordpress.com/2015/04/30/new-paper-the-effect-of-311-calls-for-service-on-crime-in-d-c-at-micro-places/ for a map of those variables.

The homework shows you how to estimate fixed effect and random effect models. For your homework 

1) I want you to estimate two models. The first is simply the negative binomial regression of:

log(E[Crime]) = Intercept + B0*Alcohol Licenses + B1*Calls For Service

The second is the negative binomial regression including fixed effects for the FishID variable,

log(E[Crime]) = Intercept + B0*Alcohol Licenses + B1*Calls For Service + [Fixed Effects for FishId]

2) Place these two coefficients estimates in a table side by side. (You do not need to include the fixed effect coefficient estimates for FishID).
3) Generate predicted outcomes for 0, 1, and 2 bars per street unit (holding calls for service at zero) for each model, and place them in a table or a graph.