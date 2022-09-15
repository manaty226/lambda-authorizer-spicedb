import json
from logging import getLogger, INFO

logger = getLogger(__name__)
logger.setLevel(INFO)

def lambda_handler(event, context):
  isAllowed = False

  token = event['authorizationToken']

  logger.info(event)

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