import json
import os
import boto3
from logging import getLogger, INFO
from src.authorizer import Authorizer
from src.object import AuthzObject

logger = getLogger(__name__)
logger.setLevel(INFO)



def lambda_handler(event, context):
    logger.info(event)

    client = boto3.client("acm")
    response = client.get_certificate(
        CertificateArn=os.environ["ACM_CERT_ARN"]
    )
    cert = response["CertificateChain"]

    host = os.environ["SPICE_DB_HOST"]
    port = os.environ["SPICE_DB_PORT"]
    
    authorizer = Authorizer(host, port, "test", bytes(cert, "utf-8"))
    
    user = AuthzObject("user", "Taro")
    resource = AuthzObject("blog", "1")
    permission = "read"
    
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
