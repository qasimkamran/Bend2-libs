import fs from "node:fs";

// Generate symbolic-fuel composition lemmas for the certified NIST J0 rounds.
// Every generated claim is an equality over the existing core implementation.
const rows = [
  "import Base",
  "import ../libs/AES256GCMCore.bend as Core",
  "import ./AES_NistKeyScheduleProof.bend as Key",
  `import ./${process.argv[3] ?? "AES_NistBlockProof.bend"} as Block`,
  "import ./AES_TraceProof.bend as Trace",
  "import ./AES_BlockBridgeProof.bend as Bridge",
  "",
  "# Symbolic remaining fuel prevents every suffix from recomputing the rounds after it.",
];
// Match the step theorem's successor form exactly. Nat.add(1n, fuel)
// is equivalent, but converting it beneath aes_rounds.go can recompute AES.
const succ = (n, fuel) => n === 0 ? fuel : `1n+(${succ(n - 1, fuel)})`;
for (let count = 1; count <= 13; count++) {
  const state = 13 - count;
  const round = 14 - count;
  const nextState = state + 1;
  const fuelCall = succ(count - 1, "fuel");
  const leftFuel = succ(count, "fuel");
  const nextRound = round + 1;
  rows.push(
    "",
    `def suffix_${count}(+fuel: Nat) ->`,
    `    {Core.aes_rounds.go(${leftFuel}, Block.state_${state}(), Key.words_60(), ${round}n) ==`,
    "     Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n) : List<&2, U32>}:",
  );
  if (count === 1) {
    rows.push(
      "    Equal.trans(List<&2, U32>,",
      `        Core.aes_rounds.go(${leftFuel}, Block.state_${state}(), Key.words_60(), ${round}n),`,
      "        Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n),",
      "        Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n),",
      "        Trace.rounds_step_at(fuel, Block.state_12(), Key.words_60(), 13n,",
      "            Block.state_13(), 14n, Block.round_13_matches(), {==}), {==})",
    );
  } else {
    rows.push(
      "    Equal.trans(List<&2, U32>,",
      `        Core.aes_rounds.go(${leftFuel}, Block.state_${state}(), Key.words_60(), ${round}n),`,
      `        Core.aes_rounds.go(${fuelCall}, Block.state_${nextState}(), Key.words_60(), ${nextRound}n),`,
      "        Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n),",
      `        Trace.rounds_step_at(${fuelCall}, Block.state_${state}(), Key.words_60(), ${round}n,`,
      `            Block.state_${nextState}(), ${nextRound}n, Block.round_${round}_matches(), {==}),`,
      `        suffix_${count - 1}(fuel))`,
    );
  }
}
for (const start of [0, 3, 6, 9]) {
  const firstRound = start + 1;
  const secondState = start + 1;
  const thirdState = start + 2;
  const endState = start + 3;
  const secondRound = firstRound + 1;
  const thirdRound = firstRound + 2;
  const endRound = firstRound + 3;
  const f1 = succ(1, "fuel");
  const f2 = succ(2, "fuel");
  const f3 = succ(3, "fuel");
  rows.push(
    "",
    `def chunk_${start}(+fuel: Nat) ->`,
    `    {Core.aes_rounds.go(${f3}, Block.state_${start}(), Key.words_60(), ${firstRound}n) ==`,
    `     Core.aes_rounds.go(fuel, Block.state_${endState}(), Key.words_60(), ${endRound}n) : List<&2, U32>}:`,
    "    Equal.trans(List<&2, U32>,",
    `        Core.aes_rounds.go(${f3}, Block.state_${start}(), Key.words_60(), ${firstRound}n),`,
    `        Core.aes_rounds.go(${f2}, Block.state_${secondState}(), Key.words_60(), ${secondRound}n),`,
    `        Core.aes_rounds.go(fuel, Block.state_${endState}(), Key.words_60(), ${endRound}n),`,
    `        Trace.rounds_step_at(${f2}, Block.state_${start}(), Key.words_60(), ${firstRound}n,`,
    `            Block.state_${secondState}(), ${secondRound}n, Block.round_${firstRound}_matches(), {==}),`,
    "        Equal.trans(List<&2, U32>,",
    `            Core.aes_rounds.go(${f2}, Block.state_${secondState}(), Key.words_60(), ${secondRound}n),`,
    `            Core.aes_rounds.go(${f1}, Block.state_${thirdState}(), Key.words_60(), ${thirdRound}n),`,
    `            Core.aes_rounds.go(fuel, Block.state_${endState}(), Key.words_60(), ${endRound}n),`,
    `            Trace.rounds_step_at(${f1}, Block.state_${secondState}(), Key.words_60(), ${secondRound}n,`,
    `                Block.state_${thirdState}(), ${thirdRound}n, Block.round_${secondRound}_matches(), {==}),`,
    `            Trace.rounds_step_at(fuel, Block.state_${thirdState}(), Key.words_60(), ${thirdRound}n,`,
    `                Block.state_${endState}(), ${endRound}n, Block.round_${thirdRound}_matches(), {==})))`,
  );
}
const plus = succ;
const endpoint = (index, fuel = "fuel") =>
  `Core.aes_rounds.go(${plus(13 - index, fuel)}, Block.state_${index}(), Key.words_60(), ${index + 1}n)`;
rows.push(
  "",
  "def rounds_0_to_6(+fuel: Nat) ->",
 `    {${endpoint(0)} == ${endpoint(6)} : List<&2, U32>}:`,
  "    Equal.trans(List<&2, U32>,",
  `        ${endpoint(0)}, ${endpoint(3)}, ${endpoint(6)},`,
  `        chunk_0(${plus(10, "fuel")}),`,
  `        chunk_3(${plus(7, "fuel")}))`,
  "",
  "def rounds_6_to_12(+fuel: Nat) ->",
  `    {${endpoint(6)} == ${endpoint(12)} : List<&2, U32>}:`,
  "    Equal.trans(List<&2, U32>,",
  `        ${endpoint(6)}, ${endpoint(9)}, ${endpoint(12)},`,
  `        chunk_6(${plus(4, "fuel")}),`,
  `        chunk_9(${plus(1, "fuel")}))`,
  "",
  "def full_rounds_match(+fuel: Nat) ->",
  `    {${endpoint(0)} == Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n) : List<&2, U32>}:`,
  "    Equal.trans(List<&2, U32>,",
  `        ${endpoint(0)}, ${endpoint(12)}, Core.aes_rounds.go(fuel, Block.state_13(), Key.words_60(), 14n),`,
  "        Equal.trans(List<&2, U32>,",
  `            ${endpoint(0)}, ${endpoint(6)}, ${endpoint(12)}, rounds_0_to_6(fuel), rounds_6_to_12(fuel)),`,
  `        suffix_1(fuel))`,
  "",
  "def full_nist_rounds_match() ->",
  "    {Core.aes_rounds.go(13n, Block.state_0(), Key.words_60(), 1n) == Core.aes_rounds.go(0n, Block.state_13(), Key.words_60(), 14n) : List<&2, U32>}:",
  "    Equal.trans(List<&2, U32>,",
  "        Core.aes_rounds.go(13n, Block.state_0(), Key.words_60(), 1n),",
  `        Core.aes_rounds.go(${succ(13, "0n")}, Block.state_0(), Key.words_60(), 1n),`,
  "        Core.aes_rounds.go(0n, Block.state_13(), Key.words_60(), 14n),",
  `        Trace.rounds_fuel_matches(13n, ${succ(13, "0n")}, Block.state_0(), Key.words_60(), 1n, {==}), full_rounds_match(0n))`,
  "",
  "def final_nist_block_match() ->",
  "    {Core.aes_rounds.go(13n, Block.state_0(), Key.words_60(), 1n) == Block.result() : List<&2, U32>}:",
  "    Equal.trans(List<&2, U32>,",
  "        Core.aes_rounds.go(13n, Block.state_0(), Key.words_60(), 1n),",
  "        Core.aes_rounds.go(0n, Block.state_13(), Key.words_60(), 14n),",
  "        Block.result(), full_nist_rounds_match(), Block.final_matches())",
  "",
  "def expanded_block_matches() ->",
  "    {Core.aes256_encrypt_expanded(Key.words_60(), Block.block()) == Block.result() : List<&2, U32>}:",
  "    Bridge.expanded_block_from_initial(Key.words_60(), Block.block(), Block.state_0(),",
  "        Block.result(), Block.initial_matches(), final_nist_block_match())",
  "",
);
const output = process.argv[2] ?? "proof/AES_NistBlockComposeProof.bend";
fs.writeFileSync(output, rows.join("\n"));
console.log(`Generated symbolic-fuel NIST composition proofs at ${output}.`);
