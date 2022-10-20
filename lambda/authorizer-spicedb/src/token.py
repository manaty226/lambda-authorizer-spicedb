import json
import base64

class Token:
    header = None
    payload = None
    signature = None
    
    def __init__(self, header:str, payload:str, signature:str) -> None:
        self.header = header
        self.payload = payload
        self.signature = signature
    
    @staticmethod
    def parse(bearer_token:str):
        jwt = bearer_token.split(".")
        header = json.loads(base64.b64decode(jwt[0]).decode())
        payload = json.loads(base64.b64decode(jwt[1]).decode())
        signature = jwt[2]   
        return Token(header, payload, signature)

    def user_name(self) -> str:
        return self.payload["name"]