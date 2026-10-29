import { initializeApp } from "firebase-admin/app";

import { useFirebaseCliCredential } from "./cliCredential.js";
import { fetchMissingAuthorImages } from "./images.js";

async function main(): Promise<void> {
  useFirebaseCliCredential();
  initializeApp({
    projectId: "motiscroll",
    storageBucket: "motiscroll.firebasestorage.app",
  });
  const stored = await fetchMissingAuthorImages();
  console.log(`Author images stored: ${stored}`);
}

main().catch((error: unknown) => {
  console.error(error);
  process.exit(1);
});
