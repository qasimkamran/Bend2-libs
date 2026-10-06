import fs from "node:fs";

// The expected output bytes come from the existing NIST law fixtures.
// Generated computational claims are candidates until independently checked.
const source = fs.readFileSync("LAWS.bend", "utf8");
const vectors = ["empty", "multiblock", "aad_only", "aad_and_multiblock", "partial_block"];
const rows = ["import Base", "import ../LAWS.bend as L", "import ../libs/AES256GCM.bend as AES",
  "import ../libs/AES256GCMCore.bend as Core", "import ./AES_NistKeyScheduleProof.bend as Key",
  "import ./AES_NistObservationProof.bend as Obs", "import ./AES_NistTagProof.bend as TagProof",
  "import ./AES_NistHashBlockProof.bend as Hash", "import ./AES_NistCtrProof.bend as Ctr",
  "import ./AES_NistCtr2BlockProof.bend as Ctr2", ""];
const constant = (name, bytes) => rows.push(`def ${name}() -> List<&2, U32>:`, `    ${bytes}`, "");
rows.push("def checkpoint_nist_schedule() ->",
  "    {Core.aes256_expand(AES.secret_key_bytes(L.aes256gcm_nist_key())) == Key.words_60() : List<&2, U32>}:",
  "    Obs.schedule_input_matches(L.aes256gcm_nist_key(), Key.key_bytes(), Key.words_60(), {==}, Key.key_schedule_matches())", "");
for (const name of vectors) {
  const law = source.split(`law aes256gcm_nist_${name}_encrypt:`)[1].split(/\nlaw /)[0];
  const inputs = law.match(/\[[\d,\s]*\]/g);
  const fixture = source.split(`def aes256gcm_nist_${name}() -> AES.Envelope:`)[1].split(/\n(?:law|def) /)[0];
  const outputs = fixture.match(/\[[\d,\s]*\]/g);
  if (inputs.length !== 2 || outputs.length !== 2) throw new Error(`Invalid fixture shape: ${name}`);
  for (const [field, value] of [["aad", inputs[0]], ["plaintext", inputs[1]], ["ciphertext", outputs[0]], ["tag", outputs[1]]]) constant(`${name}_${field}`, value);
  const mask = [253,44,170,22,165,131,46,118,170,19,44,20,83,238,218,126];
  constant(`${name}_auth`, JSON.stringify(JSON.parse(outputs[1]).map((byte, i) => byte ^ mask[i])));
  const ct = `Obs.ciphertext(Core.gcm_ctr_encrypt(Key.words_60(), AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), ${name}_plaintext()))`;
  const tag = `Core.gcm_tag_bytes(Core.gcm_tag_output(Key.words_60(), AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), ${name}_aad(), ${name}_ciphertext()))`;
  const size = JSON.parse(inputs[1]).length;
  if (size) for (const field of ["plaintext", "ciphertext"]) rows.push(
    `def checkpoint_${name}_${field}_stream() ->`,
    `    {Core.gcm_ctr_stream_exact(List.length(&2, U32, ${name}_${field}()), Key.words_60(), Core.gcm_inc32(Core.gcm_j0(AES.raw_nonce_bytes(L.aes256gcm_nist_nonce())))) == Ctr.stream_${size}() : List<&2, U32>}:`,
    `    Obs.stream_parameters(List.length(&2, U32, ${name}_${field}()), Key.words_60(),`,
    `        Core.gcm_inc32(Core.gcm_j0(AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()))), ${size}n, Ctr2.block(), Ctr.stream_${size}(),`,
    `        {==}, {==}, Ctr.checkpoint_stream_${size}())`, "");
  const cipherBody = size ? `Obs.finish_cipher(Key.words_60(), AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), ${name}_plaintext(), Ctr.stream_${size}(), ${name}_ciphertext(), checkpoint_${name}_plaintext_stream(), {==})` : "{==}";
  rows.push(`def checkpoint_${name}_ciphertext() ->`, `    {${ct} == ${name}_ciphertext() : List<&2, U32>}:`, `    ${cipherBody}`, "",
    `def checkpoint_${name}_ghash() ->`,
    `    {TagProof.auth_from_hash(Hash.result(), ${name}_aad(), ${name}_ciphertext()) == ${name}_auth() : List<&2, U32>}:`, "    {==}", "",
    `def checkpoint_${name}_tag() ->`, `    {${tag} == ${name}_tag() : List<&2, U32>}:`,
    `    TagProof.nist_tag(AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), ${name}_aad(), ${name}_ciphertext(),`,
    `        ${name}_auth(), ${name}_tag(), {==}, checkpoint_${name}_ghash(), {==})`, "",
    `def ${name}_encrypt() ->`,
    `    {L.aes256gcm_nist_encrypt_observation(AES.encrypt(L.aes256gcm_nist_key(), L.aes256gcm_nist_nonce(), ${name}_aad(), ${name}_plaintext())) ==`,
    `     L.aes256gcm_nist_encrypt_observation(Done{L.aes256gcm_nist_${name}()}) : List<&2, U32>}:`,
    "    Obs.finish_encrypt(L.aes256gcm_nist_key(), L.aes256gcm_nist_nonce(),",
    `        ${name}_aad(), ${name}_plaintext(), Key.words_60(), ${name}_ciphertext(), ${name}_tag(),`,
    `        {==}, {==}, checkpoint_nist_schedule(), checkpoint_${name}_ciphertext(), checkpoint_${name}_tag())`, "");
  const decrypted = `Core.gcm_decrypt_expanded(Key.words_60(), AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), ${name}_ciphertext())`;
  const plaintextBody = size ? `Equal.trans(List<&2, U32>, ${decrypted}, Core.gcm_zip_xor(${name}_ciphertext(), Ctr.stream_${size}()), ${name}_plaintext(), Obs.xor_from_stream(Key.words_60(), AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), ${name}_ciphertext(), Ctr.stream_${size}(), checkpoint_${name}_ciphertext_stream()), {==})` : "{==}";
  rows.push(`def checkpoint_${name}_plaintext() ->`,
    `    {${decrypted} == ${name}_plaintext() : List<&2, U32>}:`, `    ${plaintextBody}`, "",
    `def checkpoint_${name}_authenticated() ->`,
    `    {Obs.decrypt_expanded(Key.words_60(), ${name}_aad(), L.aes256gcm_nist_${name}()) == Done{${name}_plaintext()} : Result<&2, &2, AES.Error, List<&2, U32>>}:`,
    `    Obs.finish_auth(Key.words_60(), ${name}_aad(), L.aes256gcm_nist_${name}(),`,
    `        ${name}_tag(), True{}, Done{${name}_plaintext()},`,
    `        Obs.tag_parameters(Key.words_60(), ${name}_aad(), L.aes256gcm_nist_${name}(),`,
    `            AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), ${name}_ciphertext(), ${name}_tag(),`,
    `            {==}, {==}, checkpoint_${name}_tag()), {==},`,
    `        Obs.payload_parameters(Key.words_60(), L.aes256gcm_nist_${name}(),`,
    `            AES.raw_nonce_bytes(L.aes256gcm_nist_nonce()), ${name}_ciphertext(), ${name}_plaintext(),`,
    `            {==}, {==}, checkpoint_${name}_plaintext()))`, "",
    `def ${name}_decrypt() ->`,
    `    {AES.decrypt(L.aes256gcm_nist_key(), ${name}_aad(), L.aes256gcm_nist_${name}()) == Done{${name}_plaintext()} : Result<&2, &2, AES.Error, List<&2, U32>>}:`,
    `    Obs.finish_decrypt(L.aes256gcm_nist_key(), ${name}_aad(), L.aes256gcm_nist_${name}(),`,
    `        Key.words_60(), Done{${name}_plaintext()}, {==}, {==}, checkpoint_nist_schedule(),`,
    `        checkpoint_${name}_authenticated())`, "");
}
fs.writeFileSync("proof/AES_NistVectorProof.bend", rows.join("\n"));
console.log("Generated five NIST vector checkpoint compositions; independent verification required.");
