import Base
import ../libs/HTTPClient.bend as HttpClient

def main() -> Result<&2, &2, HttpClient.Error, List<&2, U32>>:
    HttpClient.encode(HttpClient.Request{"POST", "https://example.com:8443/a?x=1&x=2",
        [HttpClient.Header{"Authorization", HttpClient.utf8("Bearer sample")},
          HttpClient.Header{"Content-Type", HttpClient.utf8("application/json")}],
        HttpClient.utf8("é")})
