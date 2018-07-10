import globus_sdk
import webbrowser

class client_authorizer(object):
    """This class contains all the necessary methods to get and save
        token acces to Globus. It assumes that you have already created a OAUTH2
        app and have registered it with Globus. The Client ID
        should be hard-coded into the program. This will NOT handle token
        expiration, and should be used with scripts taking < 1 day.
        It is intended fo NATIVE APPS and will open a web browser."""
##################################################

    def __init__(self):
        self.clientID = $SECRET
        self.clientSecret = None
        self.redirect_uri = $REDIRECT
        #Step 1- Find client, get info from Globus
        self.client = None
        self.__getclient()
        #Step 2- Do (user) login, give permission to App
        self.url = None
        self.__doLogin()
        #Step 2.5- Get authorization code provided to user (after successful login/permission). Get tokens
        self.authcode = None
        self.tokenResponse = None
        self.tokens = None
        self.__getTokenResponse()
        #Step 3- Get necessary data about the authorization and transfer capabilities of user (i.e. endpoint permissions)
        self.auth_data = None
        self.auth_token = None
        self.transfer_data = None
        self.transfer_token = None
        self.__gettokens()
        #Step 4- Register all that stuff we just did with Globus
        self.authorizer = None
        self.__getauthorizer()
        self.AuthClient = None
        self.__getAuthClient()
        self.transferClient = None
        self.__getTransferClient()

##################################################

    def __getclient(self):
        self.client = globus_sdk.NativeAppAuthClient(self.clientID)

###################################################

    def __getscopes(self):
        scopes = []
        print("When finished, type 'done'.")
        while True:
            inpt = raw_input("Enter scope:")
            if inpt == 'done': break
            else: scopes.append(inpt)
        if scopes:
            scopes = ' '.join(scopes)
            self.scopes = scopes

##################################################
    def __doLogin(self):
        self.client.oauth2_start_flow(redirect_uri = self.redirect_uri)
        self.url = self.client.oauth2_get_authorize_url()
        webbrowser.open(self.url, new=1)
##################################################

    def __getTokenResponse(self):
        self.authcode = raw_input('Enter the auth code:').strip()
        self.tokenResponse = self.client.oauth2_exchange_code_for_tokens(self.authcode)
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
