import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";

const email = process.argv[2];
if (!email) {
  console.error("Usage: npm run grant-editor -- <email>");
  process.exit(1);
}

initializeApp({ projectId: process.env.GCLOUD_PROJECT || "motiscroll" });
const auth = getAuth();
const user = await auth.getUserByEmail(email);
await auth.setCustomUserClaims(user.uid, { ...(user.customClaims ?? {}), editor: true });
console.log(`editor claim set for ${email} (${user.uid}). The user must sign in again before the claim is visible.`);
