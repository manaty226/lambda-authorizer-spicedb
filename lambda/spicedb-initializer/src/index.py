import json
import os
import boto3
from logging import getLogger, INFO
from src.authorizer import Authorizer
from src.object import AuthzObject
from authzed.api.v1 import (
    Client,
    WriteSchemaRequest,
    WriteRelationshipsRequest,
    ObjectReference,
    Relationship,
    RelationshipUpdate,
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
    
    SCHEMA = """
    definition user{}

    definition blog {
      relation reader: user | user:*
      relation writer: user
    
      permission write = writer
      permission read = reader + writer
    }
    """
    
    resp = client.WriteSchema(WriteSchemaRequest(schema=SCHEMA))
    
    resp = client.WriteRelationships(
        WriteRelationshipsRequest(
            updates=[
                # Taro is a Writer on Blog 1
                RelationshipUpdate(
                    operation=RelationshipUpdate.Operation.OPERATION_CREATE,
                    relationship=Relationship(
                        resource=ObjectReference(object_type="blog", object_id="1"),
                        relation="writer",
                        subject=SubjectReference(
                            object=ObjectReference(
                                object_type="user",
                                object_id="Taro",
                            )
                        ),
                    ),
                ),
            ]
        )
    )
  
