import networkx as nx
import pandas as pd
import matplotlib.pyplot as plt

#using r before the string in python means interpret it literally, else would need to escape the slashes, same as in R
wd = r'C:\Users\axw161530\Box Sync\Classes\Sem_ResearchAnalysis\Code_Snippets\10_SocialNetworks'

#read in graph edges
Gang_edges = pd.read_csv(wd + r'\Edges.csv')
Gang_nodes = pd.read_csv(wd + r'\Nodes.csv')

#the node file contains
#Id - 1 to 97, same ids as in the edge dataset
#TotalInc - the total number of police contacts in the prior 3 years (e.g. arrests, stops, victims)
#Attended - 1 means they attended a call-in, zero means they did not
#Impact - 1 equals designated by the PD as an important gang member
#Prob_or_Parole - 1 means they were on probation or parole when the call-ins were taking place

#the edge file is undirected and has no attributes


#create the graph
GangNet = nx.from_pandas_dataframe(df=Gang_edges,source='Source',target='Target')
print nx.nodes(GangNet)

#add node attributes to the graph
Gang_nodes = Gang_nodes.set_index('Id')
node_dict = Gang_nodes.to_dict()
for i in node_dict:
    nx.set_node_attributes(GangNet,i,node_dict[i])

#creating red for those who were called in, grey for those who were not
call_in_col = []
for i in Gang_nodes['Attended']:
    if i:
        call_in_col.append('red')
    else:
        call_in_col.append('grey')

#plot graph
pos = nx.spring_layout(GangNet) #positions for all nodes
nx.draw(GangNet,pos,node_size=0,width=0)  #empty plot with no axes 
nx.draw_networkx_edges(GangNet,pos, width=0.2,edge_color='grey')
nx.draw_networkx_nodes(GangNet,pos, node_size=Gang_nodes['TotalInc']*5, node_color=call_in_col)
#nx.draw_networkx_labels(GangNet,pos=pos) #to label the nodes with Id
plt.savefig(wd + r"\Python_network.png", formant="PNG", dpi=300) #have to save before "show"
plt.show()

############################################################################
#calculate centrality metrics, add to nodes pandas data frame
eigen_cent = nx.eigenvector_centrality_numpy(GangNet)
e_cent_pd = pd.DataFrame.from_dict(eigen_cent, orient='index')
e_cent_pd.columns = ['eigen_vect']

degree_cent = nx.degree_centrality(GangNet)
d_cent_pd = pd.DataFrame.from_dict(degree_cent, orient='index')
d_cent_pd.columns = ['degree_cent']


Nodes_w_cent = pd.concat([Gang_nodes,e_cent_pd,d_cent_pd],axis=1)
print Nodes_w_cent

#note degree centrality is different in python, it is the total number of edges 
#divided by the max possible degree, n-1, so it is always fractional
############################################################################
