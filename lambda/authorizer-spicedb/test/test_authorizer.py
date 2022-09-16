import os
import json
from xmlrpc.client import boolean
import pytest
from src.index import lambda_handler

@pytest.fixture(scope="module", autouse=True)
def set_environment():
  os.environ["SPICE_DB_HOST"] = "test"
  os.environ["SPICE_DB_PORT"] = "8080"
  os.environ["SPICE_DB_PRESHARED_KEY"] = "test"

def return_val(is_allowed: boolean):
  effect = "Deny"
  if is_allowed:
    effect = "Allow"  
  return {
        'principalId': '*',
        'policyDocument': {
            'Version': '2012-10-17',
            'Statement': [
                {
                    'Action': 'execute-api:Invoke',
                    'Effect': effect,
                    'Resource': ""
                }
            ]
        }
  }

@pytest.mark.parametrize(
  "event, expected",
  [
    (
      {
        "authorizationToken": json.dumps({
          "sub": ""
        }),
        "methodArn": "",
        "resource": "",
        "path": "",
        "httpMethod": ""
      },
      return_val(is_allowed=True)
    )
  ]
)
def test_authorizer(event, expected):
  got = lambda_handler(event, context=None)
  assert got == expected

