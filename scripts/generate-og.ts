#!/usr/bin/env ts-node

import * as dotenv from "dotenv";
dotenv.config();
import { SuiClient } from "@mysten/sui/client";
import { Transaction } from "@mysten/sui/transactions";
import * as fs from "fs";

import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";

import ogData from "./og.json";
import path from "path";
import { isValidSuiAddress } from "@mysten/sui/utils";

async function main() {
  const RPC_URL = process.env.RPC_URL!;
  const PRIVATE_KEY_BASE64 = process.env.PRIVATE_KEY_BASE64!;
  const COLLECTION_PACKAGE_ID = process.env.COLLECTION_PACKAGE_ID!;
  const DISTRIBUTION_CAP_ID = process.env.DISTRIBUTION_CAP_ID!;

  // create a client connected to RPC
  const client = new SuiClient({ url: RPC_URL });

  // Create a keypair:
  const keypair = Ed25519Keypair.fromSecretKey(PRIVATE_KEY_BASE64);
  const signer_address = keypair.getPublicKey().toSuiAddress();

  console.log("Using signer address: ", signer_address);

  // create an progress file (process.json) to track creation process
  const progressFilePath = path.join(__dirname, "og-progress.json");
  let progressData = {};
  if (fs.existsSync(progressFilePath)) {
    progressData = JSON.parse(fs.readFileSync(progressFilePath, "utf8"));
  } else {
    fs.writeFileSync(progressFilePath, JSON.stringify({}));
  }

  // Looping and batching: mint 1000 addresses per iteration, persisting progress
  const BATCH_SIZE = 1000;

  const ogList = cleanList(ogData as Array<string>);

  // Initialize or resume progress
  const currentIndex: number = (progressData as any).nextIndex ?? 0;
  let nextIndex = currentIndex;

  while (nextIndex < ogList.length) {
    const start = nextIndex;
    const end = Math.min(nextIndex + BATCH_SIZE, ogList.length);
    const batchCount = end - start;

    console.log(`Preparing batch: ${start}..${end - 1} (${batchCount} mints)`);

    const tx = new Transaction();

    // Build create calls for this batch
    for (let i = start; i < end; i++) {
      const og_address = ogList[i];

      tx.moveCall({
        target: `${COLLECTION_PACKAGE_ID}::distribution::new_og_cap`,
        arguments: [
          tx.object(DISTRIBUTION_CAP_ID),
          tx.pure.u64(10),
          tx.pure.address(og_address),
        ],
      });
    }

    // Dry run
    const txResult = await client.devInspectTransactionBlock({
      sender: signer_address,
      transactionBlock: tx,
    });

    if (txResult.effects?.abortError) {
      console.error(
        "Transaction failed during devInspect:",
        txResult.effects.abortError
      );
      process.exit(1);
    }

    // Execute
    console.log(`Executing batch ${start}..${end - 1}`);
    await client.signAndExecuteTransaction({
      signer: keypair,
      transaction: tx,
    });

    // Persist progress
    nextIndex = end;
    (progressData as any).nextIndex = nextIndex;
    (progressData as any).total = ogList.length;
    fs.writeFileSync(progressFilePath, JSON.stringify(progressData, null, 2));
    console.log(`Progress saved: nextIndex=${nextIndex}/${ogList.length}`);

    await new Promise((resolve) => setTimeout(resolve, 1000));
  }

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
