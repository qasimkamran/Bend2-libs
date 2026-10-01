import Base
import ../libs/HTTPClient.bend as HttpClient

def example_request() -> HttpClient.Request:
    HttpClient.Request{"GET", "https://example.com/status", Nil{}, Nil{}}

# Run with `bend usage/HTTP.bend` to encode a simple GET request.
def main() -> Result<&2, &2, HttpClient.Error, List<&2, U32>>:
    HttpClient.encode(example_request())
