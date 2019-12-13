This is a set of data simulated to look very much like a focussed deterrence intervention I was involved in. The data are monthly counts of shootings, and the treatment series are gang shootings, and the control series are non-gang shootings. See the "SimPanel.sps" syntax to see how the data were simulated. 

For your code snippet, I show how to estimate the difference in difference model, and then how to construct the hypothetical predicted mean based on the model for both a linear and a Poisson regression. 

For your homework 

1) fit a linear model or a Poisson model, but include a set of dummy variables to control for month. (This should help account for potential seasonality in shootings, such as fewer shootings in the winter time.) Be able to write down the equation for the model you are estimating.
2) Make a regression table showing the coefficients and their standard errors for the treatment, post, and treatment multiplied by post coefficients. (Feel free to omit the dummy variables for months.)
3) Make a table showing the pre and post treatment means for each group, and also include an estimate for the hypothetical post treatment mean if the intervention did not take place. 
4) In text describe how many shootings would have been expected to occur per month had the Ceasefire intervention not taken place under this new model, and also describe why you chose the Poisson or the linear model.

Variables

 - Month - variables 1 to 12 indicating the month of the year (Jan=1,Feb=2, etc)
 - Year - variable indicating the year
 - Ord - a counter variable starting at 1 and ending at 132 (11 years)
 - Post - a dummy variable equal to 1 after the intervention (at Ord>=64, April-2008)
 - Exper - a dummy variable equal to 0 for the control series (non-gang shootings), and 1 for the treatment series (gang shootings)
 - Y - simulated counts of shootings (a poisson distributed random variable)