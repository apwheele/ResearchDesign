This dataset was constructed from the arrests and arrest charges dataset that can be downloaded from the Dallas Open data. 

The hypothetical treatment is whether an offender had a resisting arrest charge in the period of 6/1/14 until 6/30/15. This I am taking as an indicator that the arrest was not "procedurally just", and I hypothesize that they are more likely to offend in the future.

I show an example of individuals matched based on prior characteristics of: 

 - Weight (Continuous)
 - Race (Categorical)
 - Sex (Categorical)
 - Prior arrests for violent, property, part2, and other charges (took the top charge per arrest)
 
For your example code snippet I show matching on Weight, Race, Sex, and *total* number of prior arrests. Then I show how to assess balance for weight and prior arrests, comparing to full sample to the matched sample. (I force exact matching on race and sex).

For your homework
1) I want you to re-generate the propensity score, using the DaysOld_July15 variable and dropping the weight_lbs variable. Also use the individual level crime types, not just the aggregated crime variable. Be able to write out this model in your homework.
2) Try to draw two matches for each case. 
3) Create a table that shows bias reduction in the original compared to the control sample for the continuous variables, and a table showing percents for the categorical variables
4) then make a two crosstab tables showing the percent rearrested for the original sample versus the matched sample. Use a chi-square test to see if the arrest rates are different. 
5) Interpret the balance statistics and the differences in rearrests for the original and the matched data.

-----------------------


The variable descriptions are:

 - MyId: a unique ID I assigned based on the name field (arrest file)
 - MinDOB: based on arrests the minimum date of birth the offender could have
 - Weight: Weight variable from the arrest dataset (those below 80 lbs recoded to 80)
 - Race: Other, White, Hispanic, or Black
 - Sex: Male or Female (this who were missing I changed to Male)
 - HZip: Zip code of the home address, those zip codes with less than 50 cases I recoded to 0
 - Violent: Count of violent Part 1 arrests, 6/1/14 until 6/30/15
 - Prop: Count of Part 1 property arrests, 6/1/14 until 6/30/15
 - Part2: Count of Part 2 arrests, 6/1/14 until 6/30/15
 - Other: Count of arrests for other crimes, 6/1/14 until 6/30/15
 - Treatment: An indicator saying whether the individual had a charge for resisting arrest
 - AnyArrest: The outcome, whether they had any post arrest in the period 7/1/15 through 9/16/15
 - TotalPriorArrests: The sum of violent, prop, part2, and other
 - DaysOld_July15: the number of days old the person is (based on the MinDOB) as of 7/1/15

