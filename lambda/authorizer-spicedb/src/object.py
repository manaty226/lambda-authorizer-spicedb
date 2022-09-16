
class AuthzObject:
  object_type:str = None
  object_id:str = None

  def __init__(self, object_type:str, object_id:str) -> None:
    self.object_id = object_id
    self.object_type = object_type