import Base
import ../libs/JSON.bend as Json
import ../libs/HTTPClient.bend as HttpClient

def main() -> Result<&1, &1, HttpClient.Error, Json.Value>:
    HttpClient.read_json(HttpClient.Response{200, Nil{}, HttpClient.utf8("{\"ok\":true}"), Nil{}})
