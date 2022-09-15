import pytest
from src.index import lambda_handler

@pytest.mark.parametrize(
  "event, expected",
  [
    (
      {
        "authorizationToken": "",
        "methodArn": ""
      },
      {
        'principalId': '*',
        'policyDocument': {
            'Version': '2012-10-17',
            'Statement': [
                {
                    'Action': 'execute-api:Invoke',
                    'Effect': "Deny",
                    'Resource': ""
                }
            ]
        }
      }
    )
  ]
)

def test_authorizer(event, expected):
  got = lambda_handler(event, context=None)
  assert got == expected
