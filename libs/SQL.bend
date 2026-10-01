import Base
import ./HTTPClient.bend as HttpClient
import ./JSON.bend as Json

# Datasette's JSON API over the HTTP client. The base URL must not end in '/'.
type SQL.Client is Data:
    Client{base_url: String, database: String, api_token: String}

type SQL.Error is Data:
    Transport{error: HttpClient.Error}
    InvalidJson{status: U32}
    InvalidParameters{}
    HttpStatus{status: U32, body: Json.Value}

def hex_digit_kind(n: U32, decimal: Bool) -> U32:
    match decimal:
        case True{}: (48 + n : U32)
        case False{}: (55 + n : U32)

def hex_digit(+n: U32) -> U32:
    hex_digit_kind(n, U32.is_lt(n, 10))

def percent_byte(+byte: U32) -> String:
    SCon{Chr{37}, SCon{Chr{hex_digit(U32.div(byte, 16))}, SCon{Chr{hex_digit(U32.mod(byte, 16))}, SNil{}}}}

def percent_bytes(bytes: List<&2, U32>) -> String:
    match bytes:
        case Nil{}: ""
        case head <> tail: percent_byte(head) ++ percent_bytes(tail)

def percent_component(text: String) -> String:
    percent_bytes(HttpClient.utf8(text))

def query_suffix(query: String, has_query: Bool) -> String:
    match has_query:
        case True{}: "?" ++ query
        case False{}: ""

def datasette_url(base_url: String,
                  database: String,
                  path: String,
                  query: String,
                  has_query: Bool) -> String:
    base_url ++ "/" ++ percent_component(database) ++ path ++ query_suffix(query, has_query)

def sql_header(name: String, value: String) -> HttpClient.Header:
    HttpClient.Header{name, HttpClient.utf8(value)}

def unauthenticated_headers(json_body: Bool) -> List<&2, HttpClient.Header>:
    match json_body:
        case True{}: [sql_header("Accept", "application/json"), sql_header("Content-Type", "application/json")]
        case False{}: [sql_header("Accept", "application/json")]

def authenticated_headers(+api_token: String, json_body: Bool) -> List<&2, HttpClient.Header>:
    match json_body:
        case True{}:
            [sql_header("Accept", "application/json"), sql_header("Content-Type", "application/json"), sql_header("Authorization", "Bearer " ++ api_token)]
        case False{}:
            [sql_header("Accept", "application/json"), sql_header("Authorization", "Bearer " ++ api_token)]

def datasette_headers_kind(+api_token: String,
                           json_body: Bool,
                           empty_token: Bool) -> List<&2, HttpClient.Header>:
    match empty_token:
        case True{}: unauthenticated_headers(json_body)
        case False{}: authenticated_headers(api_token, json_body)

def datasette_headers(+api_token: String, json_body: Bool) -> List<&2, HttpClient.Header>:
    datasette_headers_kind(api_token, json_body, String.is_empty(api_token))

def parameter_bool(value: Bool) -> String:
    match value:
        case True{}: "1"
        case False{}: "0"

def parameter_value(value: Json.Value) -> String:
    match value:
        case Json.Str{text}: text
        case Json.Bool{value}: parameter_bool(value)
        case Json.Null{}: ""
        case _: Json.stringify(value)

def encode_parameters(fields: List<&2, Sigma<&2, &2, String, _ => Json.Value>>) -> String:
    match fields:
        case Nil{}: ""
        case (name, value) <> tail:
            "&" ++ percent_component(name) ++ "=" ++ percent_component(parameter_value(value)) ++ encode_parameters(tail)

def query_request(client: SQL.Client, sql: String) -> HttpClient.Request:
    Client{base_url, database, api_token} = client
    HttpClient.Request{
        "GET",
        datasette_url(base_url, database, "/-/query.json", "sql=" ++ percent_component(sql), True{}),
        datasette_headers(api_token, False{}),
        Nil{}}

def query_request_with_params(client: SQL.Client,
                              sql: String,
                              params: Json.Value) -> Result<&1, &1, SQL.Error, HttpClient.Request>:
    Client{base_url, database, api_token} = client
    match params:
        case Json.Obj{fields}:
            Done{HttpClient.Request{
                "GET",
                datasette_url(base_url, database, "/-/query.json", "sql=" ++ percent_component(sql) ++ encode_parameters(fields), True{}),
                datasette_headers(api_token, False{}),
                Nil{}}}
        case _: Fail{InvalidParameters{}}

def write_body(sql: String, params: Json.Value) -> String:
    Json.stringify(Json.Obj{
        ("sql", Json.Str{sql}) <>
        ("params", params) <>
        Nil{}})

def execute_write_request(client: SQL.Client,
                          sql: String,
                          params: Json.Value) -> HttpClient.Request:
    Client{base_url, database, api_token} = client
    HttpClient.Request{
        "POST",
        datasette_url(base_url, database, "/-/execute-write", "", False{}),
        datasette_headers(api_token, True{}),
        HttpClient.utf8(write_body(sql, params))}

def datasette_status_ok(+status: U32) -> Bool:
    Bool.and(U32.is_le(200, status), U32.is_lt(status, 300))

def parsed_value_response(status: U32,
                          value: Json.Value,
                          success: Bool) -> Result<&1, &1, SQL.Error, Json.Value>:
    match success:
        case True{}: Done{value}
        case False{}: Fail{HttpStatus{status, value}}

def parsed_response_kind(status: U32,
                         parsed: Result<&1, &1, HttpClient.Error, Json.Value>,
                         success: Bool) -> Result<&1, &1, SQL.Error, Json.Value>:
    match parsed:
        case Fail{_}: Fail{InvalidJson{status}}
        case Done{value}: parsed_value_response(status, value, success)

def parsed_response(+status: U32,
                    parsed: Result<&1, &1, HttpClient.Error, Json.Value>) -> Result<&1, &1, SQL.Error, Json.Value>:
    parsed_response_kind(status, parsed, datasette_status_ok(status))

def response_json(response: HttpClient.Response) -> Result<&1, &1, SQL.Error, Json.Value>:
    HttpClient.Response{+status, headers, body, trailers} = response
    parsed_response(status, HttpClient.read_json(response))

def response_result(result: Result<&1, &1, HttpClient.Error, HttpClient.Response>) -> Result<&1, &1, SQL.Error, Json.Value>:
    match result:
        case Fail{error}: Fail{Transport{error}}
        case Done{response}: response_json(response)

def query(+client: SQL.Client,
          +sql: String,
          +options: HttpClient.Options) -> IO(Result<&1, &1, SQL.Error, Json.Value>):
    do IO<Result<&1, &1, SQL.Error, Json.Value>>:
        response : Result<&1, &1, HttpClient.Error, HttpClient.Response>
            <- HttpClient.send(query_request(client, sql), options)
        return response_result(response)

def query_with_params_io(request: Result<&1, &1, SQL.Error, HttpClient.Request>,
                         +options: HttpClient.Options) -> IO(Result<&1, &1, SQL.Error, Json.Value>):
    match request:
        case Fail{error}: IO.pure(Result<&1, &1, SQL.Error, Json.Value>, Fail{error})
        case Done{value}:
            do IO<Result<&1, &1, SQL.Error, Json.Value>>:
                response : Result<&1, &1, HttpClient.Error, HttpClient.Response>
                    <- HttpClient.send(value, options)
                return response_result(response)

def query_with_params(+client: SQL.Client,
                      +sql: String,
                      +params: Json.Value,
                      +options: HttpClient.Options) -> IO(Result<&1, &1, SQL.Error, Json.Value>):
    query_with_params_io(query_request_with_params(client, sql, params), options)

def execute_write(+client: SQL.Client,
                  +sql: String,
                  +params: Json.Value,
                  +options: HttpClient.Options) -> IO(Result<&1, &1, SQL.Error, Json.Value>):
    do IO<Result<&1, &1, SQL.Error, Json.Value>>:
        response : Result<&1, &1, HttpClient.Error, HttpClient.Response>
            <- HttpClient.send(execute_write_request(client, sql, params), options)
        return response_result(response)
