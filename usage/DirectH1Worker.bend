# Private subprocess entry point for cancellable DNS/decoding. No listener.
import Base
import ../libs/wire/dns.bend as Dns
import 0x1f2d80f53f971b16c6de6a65cb1918ae/url.bend as Url
import 0x2ef00d214bb4173160420b61a1472572/http.bend as Http
import 0x49814d83de8f70993a43e1002be29ecd/bytes.bend as Bytes

@unsafe
def input.loop(file: File, +left: U32, parts: List<&2, String>) -> IO(String):
    match left:
        case 0: IO.die(String, 2, "DirectH1 helper input limit")
        case other:
            do IO<String>:
                pair : File & Result<&1, &1, U32 & String, String> <- File.read(file, U32.min(left, 65536))
                input.piece(left, parts, pair)

@unsafe
def input.piece(left: U32, parts: List<&2, String>, pair: File & Result<&1, &1, U32 & String, String>) -> IO(String):
    (file, result) = pair
    match result:
        case Fail{_}: IO.die(String, 2, "DirectH1 helper input failed")
        case Done{+chunk}: input.more(String.is_empty(chunk), file, left, parts, chunk)

@unsafe
def input.more(done: Bool, file: File, left: U32, parts: List<&2, String>, +chunk: String) -> IO(String):
    match done:
        case True{}:
            do IO<String>:
                File.close(file)
                return String.join(List.reverse(&2, String, parts), "")
        case False{}: input.loop(file, (left - U32.from_nat(String.length(chunk)) : U32), chunk <> parts)

def input() -> IO(String):
    do IO<String>:
        file : File <- IO.try(File, File.open("/dev/stdin", "r"))
        input.loop(file, 22370624, Nil{})

def decode.print(result: Result<&1, &1, Http.Err, Http.Res>) -> IO(Unit):
    match result:
        case Fail{_}: IO.die(Unit, 2, "DirectH1 helper decoding failed")
        case Done{Http.Res{_, _, body}}: IO.print(Bytes.to_base64(body))

def decode.bytes(enc: String, coding: String, body: Maybe<&1, Bytes.Bytes>) -> IO(Unit):
    match body:
        case None{}: IO.die(Unit, 2, "DirectH1 helper invalid bytes")
        case Some{bytes}:
            do IO<Unit>:
                result : Result<&1, &1, Http.Err, Http.Res> <-
                    Http.fetch.final(enc, Done{Http.Res{200, Http.set(Http.empty(), "content-encoding", coding), bytes}})
                decode.print(result)

def decode.parts(enc: String, pair: String & String) -> IO(Unit):
    (coding, body) = pair
    decode.bytes(enc, coding, Bytes.from_base64(body))

def decode(text: String & String) -> IO(Unit):
    (enc, rest) = text
    decode.parts(enc, Url.take_to(rest, 10))

def dispatch(job: String, text: String) -> IO(Unit):
    match job:
        case "dns":
            do IO<Unit>:
                addresses : List<&2, String> <- Dns.resolve.all(text)
                IO.print(String.join(addresses, "\n"))
        case "decode": decode(Url.take_to(text, 10))
        case other: IO.die(Unit, 2, "DirectH1 helper invalid operation")

def configured(args: List<String>) -> IO(Unit):
    match args:
        case _ <> job <> Nil{}:
            do IO<Unit>:
                text : String <- input()
                dispatch(job, text)
        case other: IO.die(Unit, 2, "DirectH1 helper expects one operation")

def main() -> IO(Unit):
    do IO<Unit>:
        args : List<String> <- IO.args()
        configured(args)
