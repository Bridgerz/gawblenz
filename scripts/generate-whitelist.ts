#!/usr/bin/env ts-node

import * as dotenv from "dotenv";
dotenv.config();
import { SuiClient } from "@mysten/sui/client";
import { Transaction } from "@mysten/sui/transactions";
import * as fs from "fs";

import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";

import whiteListData from "./whitelist.json";
import path from "path";

async function main() {
  const RPC_URL = process.env.RPC_URL!;
  const PRIVATE_KEY_BASE64 = process.env.PRIVATE_KEY_BASE64!;
  const COLLECTION_PACKAGE_ID = process.env.COLLECTION_PACKAGE_ID!;
  const DISTRUBTION_CAP_ID = process.env.DISTRUBTION_CAP_ID!;

  // create a client connected to RPC
  const client = new SuiClient({ url: RPC_URL });

  // Create a keypair:
  const keypair = Ed25519Keypair.fromSecretKey(PRIVATE_KEY_BASE64);
  const signer_address = keypair.getPublicKey().toSuiAddress();

  console.log("Using signer address: ", signer_address);

  // create an progress file (process.json) to track creation process
  const progressFilePath = path.join(__dirname, "wl-og-progress.json");
  let progressData = {};
  if (fs.existsSync(progressFilePath)) {
    progressData = JSON.parse(fs.readFileSync(progressFilePath, "utf8"));
  } else {
    fs.writeFileSync(progressFilePath, JSON.stringify({}));
  }

  // Looping and batching: mint 1000 addresses per iteration, persisting progress
  const BATCH_SIZE = 1000;

  // fix this: ogData will be an object with two fields that are array's of
  const whitelist = whiteListData as Array<string>;

  // Initialize or resume progress
  const currentIndex: number = (progressData as any).nextIndex ?? 0;
  let nextIndex = currentIndex;

  while (nextIndex < whitelist.length) {
    const start = nextIndex;
    const end = Math.min(nextIndex + BATCH_SIZE, whitelist.length);
    const batchCount = end - start;

    console.log(`Preparing batch: ${start}..${end - 1} (${batchCount} mints)`);

    const tx = new Transaction();

    // Build create calls for this batch
    for (let i = start; i < end; i++) {
      const whitelist_address = whitelist[i];

      tx.moveCall({
        target: `${COLLECTION_PACKAGE_ID}::distribution::new_whitelist_cap`,
        arguments: [
          tx.object(DISTRUBTION_CAP_ID),
          tx.pure.u64(10),
          tx.pure.address(whitelist_address),
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
    (progressData as any).total = whitelist.length;
    fs.writeFileSync(progressFilePath, JSON.stringify(progressData, null, 2));
    console.log(`Progress saved: nextIndex=${nextIndex}/${whitelist.length}`);

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
