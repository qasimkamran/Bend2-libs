// Select the complete syntactic dependency closure of proof roots. This does
// not assume excluded proofs: every referenced definition and constructor's
// datatype is retained and checked before the roots.
export function proofScope(B: any, book: any, roots: string[]): void {
  const owners = new Map<string, string>();
  for (const [key, tld] of Object.entries(book.tlds) as [string, any][]) {
    if (tld.$ === "ADT") for (const ctr of tld.c) owners.set(ctr.k, key);
  }
  const needed = new Set<string>();
  function add(key: string): void {
    key = owners.get(key) ?? key;
    if (needed.has(key) || !book.tlds[key]) return;
    needed.add(key);
    const tld = book.tlds[key];
    scan(B.term_lower(tld.T));
    if (tld.v) scan(B.term_lower(tld.v));
    if (tld.$ === "ADT") for (const ctr of tld.c) scan(B.term_lower(ctr.T));
  }
  function scan(term: any): void {
    if (!term || typeof term !== "object") return;
    if (["Ref", "ADT", "Ctr", "Mat"].includes(term.$)) add(term.k);
    for (const [key, value] of Object.entries(term)) {
      if (key === "s") continue; // source locations contain the entire book
      if (Array.isArray(value)) value.forEach(scan);
      else if (value && typeof value === "object") scan(value);
    }
  }
  for (const root of roots) {
    const key = book.order.find((key: string) => (B.name_key?.(key) ?? key) === root);
    if (!key) throw new Error(`Missing proof root: ${root}`);
    add(key);
  }
  book.order = book.order.filter((key: string) => needed.has(key));
  console.log(`Proof scope: ${roots.length} roots, ${needed.size} required definitions.`);
}

export function checkWithProgress(B: any, book: any): void {
  const order = book.order;
  let previous = -1;
  let checking = false;
  book.order = new Proxy(order, {
    get(target, property, receiver) {
      if (typeof property === "string" && /^\d+$/.test(property)) {
        const index = Number(property);
        if (index === 0 && previous === order.length - 1) checking = true;
        previous = index;
        const name = B.name_key(target[index]);
        if (checking && /AES_NistTagProof\.|AES_BlockBridgeProof\.|gcm_tag_output_impl|checkpoint_|full_rounds_match|full_nist_rounds_match|expanded_block_matches|key_schedule_matches|LAWS\.aes256gcm_nist_/.test(name)) {
          console.log(`Typechecking ${index + 1}/${order.length}: ${name}`);
        }
      }
      return Reflect.get(target, property, receiver);
    },
  });
  try { B.book_valid(book); }
  finally { book.order = order; }
}
