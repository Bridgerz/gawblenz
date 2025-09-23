#!/usr/bin/env ts-node

import * as dotenv from "dotenv";
dotenv.config();
import { SuiClient } from "@mysten/sui/client";
import { Transaction } from "@mysten/sui/transactions";
import * as fs from "fs";

import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";

import { isValidSuiAddress } from "@mysten/sui/utils";
import {
  KioskClient,
  Network,
  percentageToBasisPoints,
  TransferPolicyTransaction,
} from "@mysten/kiosk";

async function main() {
  const RPC_URL = process.env.RPC_URL!;
  const PRIVATE_KEY_BASE64 = process.env.PRIVATE_KEY_BASE64!;
  const COLLECTION_PACKAGE_ID = process.env.COLLECTION_PACKAGE_ID!;
  const PUBLISHER_ID = process.env.PUBLISHER_ID!;

  // create a client connected to RPC
  const client = new SuiClient({ url: RPC_URL });

  const kioskClient = new KioskClient({
    client,
    network: RPC_URL.includes("testnet") ? Network.TESTNET : Network.MAINNET,
  });

  // Create a keypair:
  const keypair = Ed25519Keypair.fromSecretKey(PRIVATE_KEY_BASE64);
  const signer_address = keypair.getPublicKey().toSuiAddress();

  console.log("Using signer address: ", signer_address);

  const tx = new Transaction();
  const tpTx = new TransferPolicyTransaction({ kioskClient, transaction: tx });
  // This is an async call, as the SDK protects from accidentally creating
  // a second transfer policy.
  // You can skip this check by passing `skipCheck: true`.
  await tpTx.create({
    type: `${COLLECTION_PACKAGE_ID}::gawblenz::Gawblen`,
    publisher: PUBLISHER_ID,
  });

  tpTx
    .addLockRule()
    .addRoyaltyRule(percentageToBasisPoints(5), 0)
    .shareAndTransferCap(signer_address);

  tpTx.transaction.setGasBudget(3000000000);

  // Sign and execute transaction.
  let res = await client.signAndExecuteTransaction({
    signer: keypair,
    transaction: tpTx.transaction,
  });

  console.log(res);

  console.log("All done.");
  process.exit(0);
}

// Run the script
main().catch((e) => {
  console.error("Script failed:", e);
  process.exit(1);
});

function cleanList(list: Array<string>): Array<string> {
  const cleanedList: Array<string> = Array.from(new Set(list));
  const invalidAddresses: Array<string> = cleanedList.filter(
    (address: string) => !isValidSuiAddress(address)
  );

  // for all invalid addresses prepend a 0 after 0x (ie. 0x123123 => 0x0123123),
  // reverify them, add the good ones, and store only the bad ones
  const recovered: Array<string> = [];
  const stillInvalid: Array<string> = [];
  for (const address of invalidAddresses as Array<string>) {
    if (!address.startsWith("0x")) {
      stillInvalid.push(address);
      continue;
    }
    const fixedOneZero = "0x0" + address.slice(2);
    if (isValidSuiAddress(fixedOneZero)) {
      recovered.push(fixedOneZero);
    } else {
      const fixedTwoZeros = "0x00" + address.slice(2);
      if (isValidSuiAddress(fixedTwoZeros)) {
        recovered.push(fixedTwoZeros);
      } else {
        stillInvalid.push(address);
      }
    }
  }

  // Keep only originally valid entries, plus recovered ones; ensure dedupe
  const finalCleaned = Array.from(
    new Set([...cleanedList.filter((a) => isValidSuiAddress(a)), ...recovered])
  );

  if (stillInvalid.length > 0) {
    fs.writeFileSync(
      "invalid_og_addresses.json",
      JSON.stringify(stillInvalid, null, 2)
    );
  }
  return finalCleaned;
}
