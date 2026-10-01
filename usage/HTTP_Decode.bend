import Base
import ../libs/HTTPClient.bend as HttpClient

def main() -> HttpClient.Decode:
    HttpClient.decode("GET",
        HttpClient.Limits{16384, 100, 1048576, 8192, 50, 8, 1024, 2097152},
        HttpClient.utf8("HTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\nready"),
        False{})
