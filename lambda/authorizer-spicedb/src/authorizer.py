
from src.object import AuthzObject

class Authorizer:
  endpoint = None
  secret = None

  def __init__(self, host:str, port:int, secret:str) -> None:
    self.endpoint = host + ":" + str(port)
    self.secret = secret

  def check_permission(self, object:AuthzObject, subject:AuthzObject, permission:str) -> bool:
    return True
