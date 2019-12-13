These are code snippets in R and Python. These are example gang networks I have worked with for a focussed deterrence intervention.

This is the first python code snippet I have shown. For my windows machine I have found it easiest to download the Anaconda distribution of python, https://www.continuum.io/downloads. Then I use Rodeo to interactively run python code, https://www.yhat.com/products/rodeo. (Anaconda makes it easier to install new modules.) To run python on the web you can try Wakari, https://wakari.io/wakari, a free Ananconda service (you need to sign up for an account though).

I have several other code snippets showing some simple network analysis in SPSS and Excel/Access. In particular how to take typical police data and convert it into an edge list necessary to create a network. SPSS can call python and R code, (and draw graphs in native SPSS code) so I've used it in tandem with networkx for several projects. See the links below:

 - https://andrewpwheeler.wordpress.com/2016/02/10/making-and-exploring-crime-networks-access-and-excel/
 - https://andrewpwheeler.wordpress.com/2014/04/22/finding-subgroups-in-a-graph-using-networkx-and-spss/
 - https://andrewpwheeler.wordpress.com/2013/12/19/network-xmas-tree-in-spss/
 - https://andrewpwheeler.wordpress.com/2013/07/19/querying-graph-neighbors-in-spss/
 - https://andrewpwheeler.wordpress.com/2013/06/30/making-an-edge-list-in-spss/
 - https://andrewpwheeler.wordpress.com/2014/04/22/finding-subgroups-in-a-graph-using-networkx-and-spss/

You are on your own if you feel compelled to use Stata for this!

These networks are described via two files, a set of Nodes and their attributes, and a set of Edges showing who are connected. These are actual gang networks, determined by coarrests and/or whether two individuals were stopped at the same time. This was used in an evaluation of a focussed deterrence intiative.

The node attributes contains the columns:

 - Id - unique ID value that maps to the edge dataset
 - TotalInc - the total number of incidents that offender was involved in in the prior 3 years
 - Attended - whether they attended an offender notification forum
 - Impact - whether they were listed by the PD as an "impact" player (just an analyst assessment)
 - Prob_or_Par - whether the individual was on probation or parole around the time of the call-in

---------------------

For your homework import Edges2.csv and Nodes2.csv into either python or R. Create a network graph that shows what individuals have been called in via color. Create a table with the Id, Total Incidents, Degree centrality, one other centrality measure, and whether they have been called in. (Remember how to make a nice table!) Write a quick summary of whether you would have chosen to call in a different node and why. Extra credit (5 points) if you can figure out how to change the shape of the nodes to distinguish between those on parole and probation.