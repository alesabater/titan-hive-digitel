titan-hive-digitel
==================

Project to recreate the mobile network of a important telecommunications company using titan and hive

HIVE directory > Contains a file with the different queries made in hive to shape the data as it was needed.

TITAN directory > Contains the scripts necessary to create the titan nodes and relations. There are 2 files, one to create the graph in localhost and the other one to create the graph in the cluster.

SQL directory > Contains a file showing how to partitionate the data based on the date the event occurred.

DOCUMENTS directory > contains samples of the data used for this project.

WEB directory > Contains two different views (Bayesian_NET.html, digitel1.html) showing the results obtained.
    
    Bayesian_NET.html > Shows the equiments that could get affected in the case that a fail occurs.
    digitel1.html > Shows how many events happen by each severity(how critical the fail is) and provider. It is possible to arrange the visualization to see it by provider or severity using the top left buttons. The intensity of the colors refer to how critical the fail is. More intense > Critival, less intense > minor fail. 

