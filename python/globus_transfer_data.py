## Create instance of all transfer information to be shared. Also make sure it's all there.

import os

class globus_transfer_info(object):

    def __init__(self,args):
        self.valid = True
        self.client = args.client_app or False
        self.native = args.native_app or False
        self.endpoint_search = args.find_endpoint or None
        self.endpoint_scope = args.endpoint_scope
        self.source_endpoint = args.source_endpoint or None
        self.shared_endpoint = args.shared_endpoint or None
        self.source_path = args.source_path or None
        self.source_name = self.__splt()
        self.dest_path = args.destination_path or None
        self.user_uuid = args.user_uuid or None
        self.username = args.username or None
        self.dodelete = args.delete
        self.group_uuid = args.group_uuid or None
        self.__validate()

#############################################

    def __validate(self):
        if self.source_endpoint == None & self.endpoint_search == None: self.valid = False
        elif self.shared_endpoint == None: self.valid = False
        elif self.source_path == None: self.valid = False
        elif self.source_endpoint == None: self.valid = False
        if not self.client or not self.native: self.valid = False

#############################################

    def __splt(self):
         dirname, leaf = os.path.split(self.source_path)
         if leaf == '':
            _, leaf = os.path.split(dirname)
         return leaf
