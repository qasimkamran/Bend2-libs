import Base

# Specification only: the API laws below intentionally have no implementations.
# Bytes use U32 storage, with erased certificates excluding values above 255.
def bytes_valid(bytes: List<&2, U32>) -> Bool:
    match bytes:
        case Nil{}: True{}
        case head <> tail:
            U32.is_lt(head, 256) && bytes_valid(tail)

# GCM permits at most 2^39 - 256 plaintext bits and fewer than 2^64 AAD bits.
def plaintext_valid(+bytes: List<&2, U32>) -> Bool:
    bytes_valid(bytes) && Nat.is_le(List.length(&2, U32, bytes),
        Nat.sub(Nat.mul(4294967295n, 16n), 16n))

def aad_valid(+bytes: List<&2, U32>) -> Bool:
    bytes_valid(bytes) && Nat.is_le(List.length(&2, U32, bytes),
        Nat.sub(Nat.mul(2147483648n, 1073741824n), 1n))

type SecretKey is Data:
    SecretKey{
        bytes: List<&2, U32>,
        -size: {List.length(&2, U32, bytes) == 32n : Nat},
        -valid: {bytes_valid(bytes) == True{} : Bool}
    }

type Nonce is Data:
    Nonce{
        bytes: List<&2, U32>,
        -size: {List.length(&2, U32, bytes) == 12n : Nat},
        -valid: {bytes_valid(bytes) == True{} : Bool}
    }

type Tag is Data:
    Tag{
        bytes: List<&2, U32>,
        -size: {List.length(&2, U32, bytes) == 16n : Nat},
        -valid: {bytes_valid(bytes) == True{} : Bool}
    }

type Envelope is Data:
    Envelope{
        nonce: Nonce,
        ciphertext: List<&2, U32>,
        tag: Tag,
        -valid: {bytes_valid(ciphertext) == True{} : Bool}
    }

type Error is Data:
    InvalidKey{}
    InvalidNonce{}
    InvalidBytes{}
    InvalidEnvelope{}
    AuthenticationFailed{}

# Constructors validate raw input; SecretKey/Nonce/Tag certificates enforce sizes.
law key:
    for bytes: List<&2, U32>
    Result<&2, &2, Error, SecretKey>

law nonce:
    for bytes: List<&2, U32>
    Result<&2, &2, Error, Nonce>

# Deterministic primitive: the caller supplies a nonce unique for this key.
# The eventual effectful wrapper must generate nonces using an OS CSPRNG.
law encrypt:
    for key: SecretKey
    for nonce: Nonce
    for aad: List<&2, U32>
    for plaintext: List<&2, U32>
    Result<&2, &2, Error, Envelope>

# Fail contains only an Error, never unauthenticated or partial plaintext.
law decrypt:
    for key: SecretKey
    for aad: List<&2, U32>
    for envelope: Envelope
    Result<&2, &2, Error, List<&2, U32>>

# Canonical envelope: v1.<lowercase nonce hex>.<lowercase tag hex>.<ciphertext hex>.
# The nonce has 24 hex characters, the tag 32, ciphertext an even number (or 0).
# AAD is external and must be supplied unchanged when decrypting.
law encode:
    for envelope: Envelope
    String

law parse:
    for text: String
    Result<&2, &2, Error, Envelope>

# Read-only projections needed to state the contract.
def nonce_bytes(nonce: Nonce) -> List<&2, U32>:
    match nonce:
        case Nonce{bytes, size, valid}: bytes

def tag_bytes(tag: Tag) -> List<&2, U32>:
    match tag:
        case Tag{bytes, size, valid}: bytes

def ciphertext(envelope: Envelope) -> List<&2, U32>:
    match envelope:
        case Envelope{nonce, ciphertext, tag, valid}: ciphertext

def envelope_nonce(envelope: Envelope) -> Nonce:
    match envelope:
        case Envelope{nonce, ciphertext, tag, valid}: nonce

def envelope_tag(envelope: Envelope) -> Tag:
    match envelope:
        case Envelope{nonce, ciphertext, tag, valid}: tag
