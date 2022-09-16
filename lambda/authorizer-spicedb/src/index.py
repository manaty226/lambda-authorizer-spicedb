import json
import os
from logging import getLogger, INFO
from src.authorizer import Authorizer
from src.object import AuthzObject

logger = getLogger(__name__)
logger.setLevel(INFO)



def lambda_handler(event, context):
    logger.info(event)

    host = os.environ["SPICE_DB_HOST"]
    port = os.environ["SPICE_DB_PORT"]
    secret = os.environ["SPICE_DB_PRESHARED_KEY"]

    token = json.loads(event['authorizationToken'])
    authorizer = Authorizer(host, port, secret)

    object = AuthzObject(event["resource"], event["path"])
    subject = AuthzObject("user", token["sub"])
    permission = event["httpMethod"]

    isAllowed = authorizer.check_permission(object, subject, permission)

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
