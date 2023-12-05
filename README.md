# Invocable Apex Action for Salesforce Next Best Action 

This repo contains an example of an Apex Invocable Action that can be used from a Salesforce 
Next Best Action Flow. The action returns a Recommendation based on data returned from 
DataCloud. The action is from a concrete proof-of-concept but the code shows how to convert 
from PersonAccount ID's to the PersonAccount Contact ID's to Unified Individual ID's to 
then query for engagement data and map the data back to return a recommendation record per 
queried PersonAccount ID. The data is also stored in an Org Platform Cache partition so that 
it can be easily shown (without an additional query) if the Screen Flow referenced from the 
recommendation is executed.

The repo contains the Apex classes, the Platform Cache partition and the Flows used. 

Please note the repo is shared as an example and it not necessarily deployable.