import globus_sdk

class client_authorizer(object):
    """This class contains all the necessary methods to get and save
        token acces to Globus. This is for tutorial purposes ONLY."
##################################################

    def __init__(self):
        self.clientID = $ID
        self.clientSecret = $Secret
        #Step 1- Get information about the client, make sure it exists and is registered with Globus
        self.client = None
        self.__getclient()
        #Step 2- Verify access to Globus
        self.tokenResponse = None
        self.tokens = None
        self.__getTokenResponse()
        #Step 3- Get information about authorization/ transfer capabilities of App (i.e. endpoint permissions)
        self.auth_data = None
        self.auth_token = None
        self.transfer_data = None
        self.transfer_token = None
        self.__gettokens()
        #Step 4- Register all this stuff we just did with Globus so we can actually transfer things!
        self.authorizer = None
        self.__getauthorizer()
        self.AuthClient = None
        self.__getAuthClient()
        self.transferClient = None
        self.__getTransferClient()

##################################################

    def __getclient(self):
        self.client = globus_sdk.ConfidentialAppAuthClient(self.clientID,self.clientSecret)

##################################################

    def __getTokenResponse(self):
        self.tokenResponse = self.client.oauth2_client_credentials_tokens()
        self.tokens = self.tokenResponse.by_resource_server
###################################################

    def __gettokens(self):
        self.auth_data = self.tokens['auth.globus.org']
        self.auth_token = self.auth_data['access_token']
        self.transfer_data = self.tokens['transfer.api.globus.org']
        self.transfer_token = self.transfer_data['access_token']

####################################################

    def __getauthorizer(self):
        self.authorizer = globus_sdk.AccessTokenAuthorizer(self.transfer_token)

###################################################

    def __getAuthClient(self):
        self.AuthClient = globus_sdk.AuthClient(authorizer = self.authorizer)
###################################################

    def __getTransferClient(self):
        self.transferClient = globus_sdk.TransferClient(authorizer=self.authorizer)

####################################################
