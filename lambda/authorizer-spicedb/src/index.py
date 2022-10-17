import json
import os
import boto3
from logging import getLogger, INFO
from src.authorizer import Authorizer
from src.object import AuthzObject
from authzed.api.v1 import Client
from authzed.api.v1 import (
    CheckPermissionRequest,
    CheckPermissionResponse,
    ObjectReference,
    SubjectReference,
)
from grpcutil import bearer_token_credentials

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

    client = Client(
        host + ":" +  port,
        bearer_token_credentials("test", bytes(cert, "utf-8")),        
    )
  
    # host = os.environ["SPICE_DB_HOST"]
    # port = os.environ["SPICE_DB_PORT"]
    # secret = os.environ["SPICE_DB_PRESHARED_KEY"]
    # authorizer = Authorizer(host, port, secret)

    # token = json.loads(event['authorizationToken'])

    # object = AuthzObject(event["resource"], event["path"])
    # subject = AuthzObject("user", token["sub"])
    # permission = event["httpMethod"]

    # isAllowed = authorizer.check_permission(object, subject, permission)

    # effect = "Deny"
    # if isAllowed:
    #     effect = "Allow"


    # return {
    #     'principalId': '*',
    #     'policyDocument': {
    #         'Version': '2012-10-17',
    #         'Statement': [
    #             {
    #                 'Action': 'execute-api:Invoke',
    #                 'Effect': effect,
    #                 'Resource': event['methodArn']
    #             }
    #         ]
    #     }
    # }
