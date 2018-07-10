Globus Automation Examples
----------------------------------------
    This section is for example Globus automation scripts. For more information about Globus as a service or documentation:
    https://www.globus.org/
    https://docs.globus.org/
----------------------------------------
PYTHON

   Python for Globus requires installation of the Globus Python SDK. Installation instructions can be found at:
   https://globus-sdk-python.readthedocs.io/en/stable/installation/
    
 The Python folder contains two examples of client authorizations: Native and Client Credentials.
 
     Native:
        Native apps open a web browser to verify your identity within Globus. All authorizations, transfers, 
        and activity will be visible from your Globus account. The only required value for Native apps is a client ID,
        which can be coded into the program in 'native_authorizer.py'. More info about setting up your own practice Native App:
        
        https://globus-sdk-python.readthedocs.io/en/stable/tutorial/ 
        (Step 1)
      
        'native_authorizer.py' is the helper class for Native App authorizations. All neccessary authorizations, tokens, and 
        variables are automatically defined and created. 
      
    Client Credentials:
        Client Credentials apps are more complicated. They require a Client ID and Secret, and typically depend on an outside
        authorization resource. Client Credientials do not open a web browser and do not require any input from the user. All
        transfers made will be traced to the Client, which acts on behalf of the user. As a result, you must give the Client
        permissions to read and write to your desired source/destination endpoints. To simulate the flow, use this:
        
        https://github.com/globus/globus-sample-data-portal
        (Note: this will not actually complete any transfers, but is good for understanding the Client Credential process)
      
        'client_authorizer.py' is the helper class for Client Credentials authorizations. All neccessary authorizations, tokens, and 
        variables are automatically defined and created. 
  
  Both types of authorizations can be executed from ''. Give it executable permissions.
   
    Usage:
        ./'' 
  
    (Note: it is NECESSARY to use double quotes [""])
    For full options, use -h.

----------------------------------------
BASH

  The bash script uses Globus CLI (Command Line Interface) to complete transfers. Installation instructions:
    https://docs.globus.org/cli/installation/
        
   After logging in, give the script executable permissions.
   
      Usage:
      ./''
     For full options, use -h
    
