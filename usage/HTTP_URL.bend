import Base
import ../libs/HTTPClient.bend as HttpClient

# URL parsing uses the pinned pure Bend URL parser, then applies HTTP client
# restrictions and constructs the authority used by the request encoder.
def main() -> Result<&2, &2, HttpClient.Error, HttpClient.Target>:
    HttpClient.parse_url("https://Example.com/v1/responses?x=%2F&x=2#local")
