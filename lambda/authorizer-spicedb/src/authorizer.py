from authzed.api.v1 import Client
from authzed.api.v1 import (
    CheckPermissionRequest,
    CheckPermissionResponse,
    ObjectReference,
    SubjectReference,
)
from grpcutil import bearer_token_credentials
from src.object import AuthzObject

class Authorizer:
  client = None

  def __init__(self, host:str, port:int, secret:str, cert:bytes) -> None:
    self.client = Client(
        host + ":" +  port,
        bearer_token_credentials(secret, cert),
    )

  def check_permission(self, resource:AuthzObject, user:AuthzObject, permission:str) -> bool:
    spice_object = ObjectReference(
        object_type=resource.object_type,
        object_id=resource.object_id,
    )
    spice_subject = SubjectReference(
      object=ObjectReference(
        object_type=user.object_type,
        object_id=user.object_id,
      )
    )
    resp = self.client.CheckPermission(
        CheckPermissionRequest(
            resource=spice_object,
            permission="read",
            subject=spice_subject,
        )
    )
    return resp.permissionship == CheckPermissionResponse.Permissionship.PERMISSIONSHIP_HAS_PERMISSION