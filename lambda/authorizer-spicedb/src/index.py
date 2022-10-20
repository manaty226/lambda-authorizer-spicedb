import json
import os
import boto3
import base64
from logging import getLogger, INFO
from src.authorizer import Authorizer
from src.object import AuthzObject
from src.token import Token

logger = getLogger(__name__)
logger.setLevel(INFO)

def lambda_handler(event, context):
    logger.info(event)

    # extract token from header
    token = Token.parse(event["headers"]["authorization"].split(" ")[1])
    
    # get root certification for SpiceDB
    client = boto3.client("acm")
    response = client.get_certificate(
        CertificateArn=os.environ["ACM_CERT_ARN"]
    )
    cert = response["CertificateChain"]

    # create authorizer
    host = os.environ["SPICE_DB_HOST"]
    port = os.environ["SPICE_DB_PORT"]
    authorizer = Authorizer(host, port, "test", bytes(cert, "utf-8"))
    

    # extract resource and user information
    resource_id = event["path"].split("/")[-1]
    method = event["httpMethod"]
    name = token.user_name()

    # create Authorization Object
    user = AuthzObject("user", name)
    resource = AuthzObject("blog", resource_id)
    permission = "read" if method == "GET" else "write"
    
    # check permission via SpiceDB
    isAllowed = authorizer.check_permission(resource, user, permission)
    
    effect = "Deny"
    if isAllowed:
        effect = "Allow"

    return {
        'principalId': '*',
        'policyDocument': {
            'Version': '2012-10-17',
            'Statement': [
                {
                    'Action': 'execute-api:Invoke',
                    'Effect': effect,
                    'Resource': event['methodArn']
                }
            ]
        }
    }
