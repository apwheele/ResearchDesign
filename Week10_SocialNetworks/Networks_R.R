#This code snippet uses the igraph package to do some exploratory analysis of a social network
#the example is taken from one gang in a city, it was following a focussed deterrence intiative

#the Edge file is undirected, and two gang members are connected if they were co-arrested or co-stopped in the prior
#three years

#the node file contains
#Id - 1 to 97, same ids as in the edge dataset
#TotalInc - the total number of police contacts in the prior 3 years (e.g. arrests, stops, victims)
#Attended - 1 means they attended a call-in, zero means they did not
#Impact - 1 equals designated by the PD as an important gang member
#Prob_or_Parole - 1 means they were on probation or parole when the call-ins were taking place


library(igraph)  #for centrality and clustering metrics

mydir <- "C:\\Users\\axw161530\\Box Sync\\Classes\\Sem_ResearchAnalysis\\Code_Snippets\\10_SocialNetworks" 
setwd(mydir)

#read in the edges and nodes
Edges <- read.csv(file="Edges.csv")
Nodes <- read.csv(file="Nodes.csv")

###########################################################################
#Examples in igraph
gang_network <- graph_from_edgelist(as.matrix(Edges), directed=FALSE)
#plot the network
plot(gang_network)
#lets try to make alittle nicer, color is by whether attended, size is total incidents
NodeColor <- ifelse(Nodes$Attended==1,"red","grey")
plot(gang_network, vertex.label=NA, layout=layout_with_fr, edge.curved=FALSE, vertex.size=Nodes$TotalInc/2, vertex.color=NodeColor)
#calculating different centrality metrics, adding back into the Nodes data.frame
#note these are masked if you have imported the network package
Nodes$close_cent <- closeness(gang_network) #closeness centrality
Nodes$betwe_cent <- betweenness(gang_network) #between centrality
Nodes$degre_cent <- degree(gang_network) #degree centrality
#correlations between centralities and total incidents
cor(Nodes[,c("TotalInc","close_cent","betwe_cent","degre_cent")]) #pretty high correlations
#igraph is also very nice for clustering pretty large networks, see cluster_fast_greedy function for one example, a network this small though not really needed
###########################################################################

###########################################################################
#Examples in network and ggnet2 (via GGally)

library(network) #better for exponential random graph models, see work by Carter Butts (and the sna library)
library(ggplot2)
library(GGally)  #for ggplot2 like network plots (uses network objects), see https://briatte.github.io/ggnet/

gang_n2 <- network(Edges,directed=F,vertex.attr=Nodes)
ggnet2(gang_n2)

#lets make a plot with size by betweeness centrality and colors are impact players
gang_n2 %v% "impact_flag" = ifelse(Nodes$impact==1,"Impact","Not Impact")
MyPal <- c("Impact" = "red", "Not Impact" = "grey")
p <- ggnet2(gang_n2, size="betwe_cent", min_size=1, max_size=9, size.cut=5, size.legend="Betweenness Centrality", color="impact_flag", palette=MyPal, color.legend="", alpha=0.8) +
     geom_point(aes(size=size),color='black',shape=1, alpha=0.5)
p

#save file, this looks nicer in vector format
pdf('R_graphNetwork.pdf')
p
dev.off()








