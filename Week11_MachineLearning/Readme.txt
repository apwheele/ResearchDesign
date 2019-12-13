This is an example analysis of using different machine learning outcomes to predict recidivism in a sample of adults that were given the COMPAS screening in Florida. See the DataCodebook.txt file for description of the data and where it came from.

For the code snippet, I have you predict recidivism (after 30 days) based on the sex, years old when screened, three different compas scores, and the juvenile felony count. I have you use R or SPSS to estimate a logistic regression model, a random forest model, and a generalized boosted regression model based on these variables in a training sample. (SPSS also has an example neural network.) I then have you assess each model on a hold-out sample of individuals.

There are only R and SPSS code snippets as of now, as R is the only program I am aware of that you can fit random forest and gbm models in (the SPSS code just calls the R models). In the future I will update with Python programs. As far as I'm aware, options in Stata to conduct equivalent models are not currently available, nor have I seen anything to suggest they will be in the future. 

Your homework is simple: 
 1) try to estimate models predicting recidivism that improve upon the accuracy of the model shown in your code snippet. 
 2) Display a table of the area-under-the-curve statistics, and 
 3) make an ROC plot for the best model (and add in any other models you also considered). 
 
Only use information that makes sense in the future prediction. For example, using the future charge is non-sensical, as you only know that after the individual actually gets charged for a future offense.