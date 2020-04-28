#!/usr/bin/python

import base64
import sys
import argparse

from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
from azure.keyvault.keys import KeyClient
from azure.identity import ClientSecretCredential


# This program is used to generate new token for databricks application. It accepts following parameters 

DOMAIN = 'centralus.azuredatabricks.net'
TOKEN = ''
VAR_COMMENTS = ""
ENTITYTYPE = ""
Operation = ""
EntityName = ""
teyVault = ""
MasterKeySecret = ""

def create_token():
    TOKEN = get_master_secret()
    response = requests.post( 'https://%s/api/2.0/token/create' % (DOMAIN), headers={'Authorization': 'Bearer %s' % TOKEN},
    json={"lifetime_seconds": 100, "comment": "Token generated and saved under Secret <"+EntityName +">" }
    )
    if response.status_code == 200:
       print("New Token value is %s" % response.json()['token_value'])
       return(response.json()['token_value'])
    else:
       print("Error launching cluster: %s: %s" % (response.json()["error_code"], response.json()["message"]))
       return -1;


def get_master_secret():
    secret_client = make_connection()
    secret = secret_client.get_secret(MasterKeySecret)
    print(secret.name)
    print(secret.value)
    return(secret.value);

def retrieve_key():
    key_client = make_connection()
    v_url = "https://" + KeyVault + ".vault.azure.net/"
    # Update existing key 
    key = key_client.get_key(EntityName)
    print(key.name,"enabled :",key.properties.enabled)

def retrieve_secret():
    secret_client = make_connection()
    v_url = "https://" + KeyVault + ".vault.azure.net/"
    # Update existing key 
    secret = secret_client.get_secret(EntityName)
    print(secret.name,"-->",secret.value)

def update_key():
    key_client = make_connection()
    v_url = "https://" + KeyVault + ".vault.azure.net/"
    # Update existing key 
    key = key_client.get_key(EntityName)
    if key.properties.enabled == False:
         new_prop = True
    else: 
         new_prop = False
    updated_key = key_client.update_key_properties(EntityName, enabled=new_prop)
    print(updated_key.name)
    print(updated_key.properties.enabled)


def update_secret():
    secret_client = make_connection()
    # Clients may specify the content type of a secret to assist in interpreting the secret data when it's retrieved
    content_type = "text/plain"
    # We will also disable the secret for further use
    secret = secret_client.get_secret(EntityName)
    curr_status = secret.properties.enabled
    if curr_status == True:
       new_status = False
    else:
       new_status = True
    updated_secret_properties = secret_client.update_secret_properties(EntityName, content_type=content_type, enabled=new_status)
    print(updated_secret_properties.updated_on)
    print(updated_secret_properties.content_type)
    print(updated_secret_properties.enabled)


def create_key():
    key_client = make_connection()
    v_url = "https://" + KeyVault + ".vault.azure.net/"
    # Create an RSA key
    key_name = "rsa" + EntityName
    rsa_key = key_client.create_rsa_key(key_name, size=2048)
    print(rsa_key.name)
    print(rsa_key.key_type)
    # Create an elliptic curve key
    key_name = "ec" + EntityName
    ec_key = key_client.create_ec_key(key_name, curve="P-256")
    print(ec_key.name)
    print(ec_key.key_type)
    return(ec_key.name);


def create_secret(new_token_value):
    secret_client = make_connection()
    secret = secret_client.set_secret(EntityName, new_token_value)
    print(secret.name)
    print(secret.value)
    print(secret.properties.version)
    return("New Secret created %s" % secret.name);

def make_connection():
    tenant_id = "bc111fcd-1154-4322-b437-799c66a7677c"
    client_id = "4ae3d5ed-bbd0-485d-956b-19c0378940a2"
    client_secret = "Rm/?G6GnHsyA?rx=q5xmOATw1gi6N]HB"
    credential = ClientSecretCredential(tenant_id, client_id, client_secret)
    client = KeyClient("https://MasterDataBricksKeyVault.vault.azure.net", credential)
    return client ;
    #credential = DefaultAzureCredential()
    #v_url = "https://" + KeyVault + ".vault.azure.net/"
    #key_client = KeyClient(vault_url="https://MasterDataBricksKeyVault.vault.azure.net/", credential=credential)
    #if ENTITYTYPE == 'Key': 
       #Key_client = KeyClient(vault_url= v_url, credential=credential)
       #return Key_client
    #else:
    #   secret_client = SecretClient(vault_url=v_url, credential=credential)
    #   return secret_client ;

def parse_argv():
    global ENTITYTYPE
    global Operation
    global EntityName
    global DOMAIN 
    global KeyVault
    global MasterKeySecret 

    list = ['C','R','U']
    et = ['Key','Secret','Token']
    parser = argparse.ArgumentParser(
    description = "Required parameters are :")
    
    # Parameter list 
    parser.add_argument('EntityType',help='Entity type could be Key or Secret or Token')
    parser.add_argument('Operation',help='Operation could be Create (C), update (U) or Retrieve (R)')
    parser.add_argument('EntityName',help='Enter Entity Name of Key or  Secret')
    parser.add_argument('Domain',help='Enter Name of the Domain')
    parser.add_argument('Keyvault',help='Enter Name of the Keyvault')
    parser.add_argument('MasterKeysecret',help='Enter Name of the Master secret')
    args = parser.parse_args()
    if (args.Operation not in list):
         print('Valid values for Operation are C - Create, R - Retrieve, U - Update')
         return -1 
    if (args.EntityType not in et):
         print('Valid values for Entity are Key or Secreti or Token ')
         return -1 
    ENTITYTYPE = args.EntityType
    Operation =  args.Operation
    EntityName = args.EntityName
    DOMAIN = args.Domain
    KeyVault = args.Keyvault
    MasterKeySecret = args.MasterKeysecret
    return 0;

def main():
    global EntityName
    ret = 0
    ret = parse_argv()
    if ret == -1:
       exit 
    if ENTITYTYPE == "Secret" and Operation == 'C':
       EntityName = "sec" +  EntityName
       create_secret("Naresh")
	#Note Add code to generate Random Password and replace "Naresh" in above statement 
    elif ENTITYTYPE == "Secret" and Operation == 'R':
       retrieve_secret()
    elif ENTITYTYPE == "Secret" and Operation == 'U':
       update_secret()
    elif ENTITYTYPE == "Token" and Operation == 'C':
       EntityName = "tok" +  EntityName
       new_token_value = create_token()              
       create_secret(new_token_value)
    elif ENTITYTYPE == "Key" and Operation == 'C':
       EntityName = "Key" +  EntityName
       create_key()
    elif ENTITYTYPE == "Key" and Operation == 'U':
       update_key()
    elif ENTITYTYPE == "Key" and Operation == 'R':
       retrieve_key()
    print(TOKEN)

if __name__ == "__main__":
    main()

