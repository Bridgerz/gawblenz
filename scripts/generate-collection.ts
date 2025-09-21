#!/usr/bin/env ts-node

import * as dotenv from "dotenv";
dotenv.config();
import { SuiClient } from "@mysten/sui/client";
import { Transaction } from "@mysten/sui/transactions";
import * as fs from "fs";

import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";

import collectionData from "./collection.json";
import path from "path";

async function main() {
  const RPC_URL = process.env.RPC_URL!;
  const PRIVATE_KEY_BASE64 = process.env.PRIVATE_KEY_BASE64!;
  const COLLECTION_PACKAGE_ID = process.env.COLLECTION_PACKAGE_ID!;
  const DISTRIBUTION_ID = process.env.DISTRIBUTION_ID!;
  const ADMIN_CAP_ID = process.env.ADMIN_CAP_ID!;

  // create a client connected to RPC
  const client = new SuiClient({ url: RPC_URL });

  // Create a keypair:
  const keypair = Ed25519Keypair.fromSecretKey(PRIVATE_KEY_BASE64);
  const signer_address = keypair.getPublicKey().toSuiAddress();

  console.log("Using signer address: ", signer_address);

  // create an progress file (process.json) to track creation process
  const progressFilePath = path.join(__dirname, "progress.json");
  let progressData = {};
  if (fs.existsSync(progressFilePath)) {
    progressData = JSON.parse(fs.readFileSync(progressFilePath, "utf8"));
  } else {
    fs.writeFileSync(progressFilePath, JSON.stringify({}));
  }

  // Looping and batching: mint 333 NFTs per iteration, persisting progress
  const BATCH_SIZE = 100;

  // Normalize collection items: expect an array of items with image_url and optional traits
  type CollectionItem = {
    image?: string;
    attributes?: Array<Record<string, string>>;
  };
  const items: CollectionItem[] = Array.isArray(collectionData)
    ? (collectionData as unknown as CollectionItem[])
    : (collectionData as any)?.items ?? [];

  if (!Array.isArray(items) || items.length === 0) {
    console.error(
      "No collection items found in collection.json (expected an array or { items: [] })."
    );
    process.exit(1);
  }

  // Initialize or resume progress
  const currentIndex: number = (progressData as any).nextIndex ?? 0;
  let nextIndex = currentIndex;

  while (nextIndex < items.length) {
    const start = nextIndex;
    const end = Math.min(nextIndex + BATCH_SIZE, items.length);
    const batchCount = end - start;

    console.log(`Preparing batch: ${start}..${end - 1} (${batchCount} mints)`);

    const tx = new Transaction();

    // Build create calls for this batch
    for (let i = start; i < end; i++) {
      const item = items[i] ?? {};
      const imageUrl = `https://gawblenz.s3.us-east-1.amazonaws.com/images/${
        item?.image ?? ""
      }`;

      const attributes = item.attributes ?? [];
      const keys = attributes.map((attribute) => attribute.trait_type);
      const values = attributes.map((attribute) => attribute.value);

      const traits = tx.moveCall({
        target: `0x2::vec_map::from_keys_values`,
        arguments: [
          tx.pure.vector("string", keys),
          tx.pure.vector("string", values),
        ],
        typeArguments: ["0x1::string::String", "0x1::string::String"],
      });

      tx.moveCall({
        target: `${COLLECTION_PACKAGE_ID}::gawblenz::create`,
        arguments: [
          tx.object(ADMIN_CAP_ID),
          tx.object(DISTRIBUTION_ID),
          tx.pure.string(imageUrl),
          traits,
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
    (progressData as any).total = items.length;
    fs.writeFileSync(progressFilePath, JSON.stringify(progressData, null, 2));
    console.log(`Progress saved: nextIndex=${nextIndex}/${items.length}`);

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
