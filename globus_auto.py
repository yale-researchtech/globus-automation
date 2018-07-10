#!/usr/bin/env python

from __future__ import print_function
from client_authorizer import *
from native_authorizer import *
from globus_transfer_data import *
import os
import sys
import argparse
import webbrowser
import json
import globus_sdk
from globus_sdk.exc import TransferAPIError

def __find_endpoint(t_data,auths):
        eps = auths.transferClient.endpoint_search(filter_fulltext =t_data.endpoint_search,filter_scope = t_data.endpoint_scope)
        for e in eps:
            print('{0} has ID {1}'.format(ep['display_name'], ep['id']))

        ep_id = raw_input('Copy and paste ID of desired endpoint or Enter to quit:')

        if not ep_id: exit(1)

        t_data.shared_endpoint = ep_id
        return t_data


def share_data_native(t_data):

        #Get all authorizer (auth & transfer client) data
        authorizer = native_authorizer.client_authorizer()
        if t_data.endpoint_search: t_data = __find_endpoint(t_data,authorizer)
        __setup_all(t_data,authorizer)


def share_data_client(t_data):

        #Get all authorizer (auth & transfer client) data
        authorizer = client_authorizer.client_authorizer()
        if t_data.endpoint_search: t_data = __find_endpoint(t_data,authorizer)
        __setup_all(t_data,authorizer)


def __setup_all(t_data,auths):

    #Fix source/destination paths
    if not t_data.source_path.startswith('/'): t_data.source_path = '/' + t_data.source_path
    if not t_data.dest_path.startswith('/'): t_data.dest_path = '/' + t_data.dest_path

    #Delete dest. directory if it exists & flagged delete
    if t_data.dest_path != '/':
        try:
            auths.transferClient.operation_ls(t_data.shared_endpoint, path=t_data.dest_path)
        except TransferAPIError as e:
            print(e)
            sys.exit(1)

        try:
            auths.transferClient.operation_ls(t_data.shared_endpoint, path=t_data.dest_path)
            if not t_data.dodelete:
                print('Destination directory exists. Delete the directory or ''use --delete option')
                sys.exit(1)

            ddata = globus_sdk.DeleteData(auths.transferClient,t_data.shared_endpoint,label='Share Data Example',recursive=True)
            ddata.add_item(t_data.dest_path)
            #delete task
            task = auths.transferClient.submit_delete(ddata)
            auths.transferClient.task_wait(task['task_id'])
        except TransferAPIError as e:
            if e.code != u'ClientError.NotFound':
                print(e)
                sys.exit(1)

    #Create destination
        try:
            auths.transferClient.operation_mkdir(t_data.shared_endpoint, t_data.dest_path)
        except TransferAPIError as e:
            print(e)

    # grant group/user (read-only) access to the dest directory
    if t_data.user_uuid:
        rule_data = {"DATA_TYPE": "access","principal_type": "identity","principal": t_data.user_uuid,"path":t_data.dest_path,"permissions": "r",}

        try:
            auths.transferClient.add_endpoint_acl_rule(t_data.shared_endpoint, rule_data)
        except TransferAPIError as e:
            if e.code != u'Exists':
                print(e)
                sys.exit(1)

    if t_data.group_uuid:
        rule_data = {"DATA_TYPE": "access","principal_type": "identity","principal": t_data.group_uuid,"path":t_data.dest_path,"permissions": "r",}

        try:
            auths.transferClient.add_endpoint_acl_rule(t_data.shared_endpoint, rule_data)
        except TransferAPIError as e:
            if e.code != u'Exists':
                print(e)
                sys.exit(1)

    if t_data.username:
        r = auths.AuthClient.get_identities(usernames=t_data.username)
        if len(r['identities']):
            username_uuid = r['identities'][0]['id']
            rule_data = {"DATA_TYPE": "access","principal_type": "identity","principal": username_uuid,"path":t_data.dest_path,"permissions": "r",}
            try:
                auths.transferClient.add_endpoint_acl_rule(t_data.shared_endpoint, rule_data)
            except TransferAPIError as e:
                if e.code != u'Exists':
                    print(e)
                    sys.exit(1)

    #do the actual transferring and stuffs
    transfer = globus_sdk.TransferData(
            auths.transferClient,
            t_data.source_endpoint,
            t_data.shared_endpoint,
            label='Share Data Example')
    transfer.add_item(t_data.source_path, t_data.dest_path, recursive=True)
    try:
        transfer_task = auths.transferClient.submit_transfer(transfer)
    except TransferAPIError as e:
        print(e)
        sys.exit(1)
    print(transfer_task)

if __name__ == '__main__':

    #######################################
    #get all dem args
    parser = argparse.ArgumentParser(
        description='Copy data from your private endpoint to a shared one for'
        'other people to access. You can share data with both individual users'
        ' and groups.'
    )
    parser.add_argument(
        '-native','--native-app', action='store_true',
        help='Will open web browser to login. Client ID should be coded into program.'
    )
    parser.add_argument(
        '-client','--client-app', action='store_true',
        help='Will not open web browser to login. Client ID and Secret should be coded into program.'
    )
    parser.add_argument(
    '-findep','--find-endpoint',
    help='Search your endpoints to find a match to given destination name (string).'
    )
    parser.add_argument(
    '-epscope','--endpoint-scope=recently-used',
    help='Scope to find endpoint. Default is recently-used. More info: https://docs.globus.org/api/transfer/endpoint_search/'
    )

    parser.add_argument(
        '-source','--source-endpoint',
        help='Source Endpoint UUID where your data is stored.'
    )
    parser.add_argument(
        '-shared','--shared-endpoint',
        help='The place you will share your data. Create a shared endpoint '
             'by going to globus.org/app/transfer, navigating to your endpoint'
             ' and clicking "share" on a folder.'
    )
    parser.add_argument(
        '-s','--source-path',
    )
    parser.add_argument(
        '-d','--destination-path',
    )
    parser.add_argument(
            '--group-uuid',
            help='UUID of a group transferred data will be shared with')
    parser.add_argument(
            '--user-uuid',
            help='UUID of a user transferred data will be shared with')
    parser.add_argument(
            '--username',
            help='Identity username of a user transferred data will be shared '
            'with, e.g. johndoe@uchicago.edu')
    parser.add_argument(
            '-del','--delete', action='store_true',
            help='Delete a destination directory if already exists before '
            'transferring data')
    ###################################################
    #do the stuff!!!!
    args = parser.parse_args()
    transfer_data = globus_transfer_info(args)
    if transfer_data.valid:
        if transfer_data.client: share_data_client(transfer_data)
        elif transfer_data.native: share_data_native(transfer_data)
    else: exit(1)
