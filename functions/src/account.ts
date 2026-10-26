import { getAuth } from "firebase-admin/auth";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import { assertSignedIn } from "./authz.js";
import { enforceAppCheck } from "./secrets.js";

const callable = { enforceAppCheck: enforceAppCheck() };

export const deleteAccount = onCall(callable, async (request) => {
  const uid = assertSignedIn(request);
  const db = getFirestore();
  await db.recursiveDelete(db.collection("users").doc(uid));
  await getAuth().deleteUser(uid);
  return { ok: true };
});

export const recordView = onCall(callable, async (request) => {
  const uid = assertSignedIn(request);
  const itemId = String(request.data?.itemId ?? "").trim();
  if (!itemId) throw new HttpsError("invalid-argument", "itemId is required.");
  const db = getFirestore();
  const ref = db.collection("users").doc(uid);
  const snap = await ref.get();
  const data = snap.data() ?? {};
  const timezone = String(data.timezone ?? "UTC");
  const today = localDay(timezone);
  const last = String(data.lastActiveDate ?? "");
  let streak = Number(data.streakCount ?? 0);
  if (last !== today) {
    const yesterday = localDay(timezone, -1);
    streak = last === yesterday ? streak + 1 : 1;
    await ref.set(
      {
        streakCount: streak,
        lastActiveDate: today,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }
  await ref.collection("progress").doc(itemId).set(
    { viewed: true, updatedAt: FieldValue.serverTimestamp() },
    { merge: true },
  );
  return { streakCount: streak, lastActiveDate: today };
});

function localDay(timeZone: string, offsetDays = 0): string {
  const shifted = new Date(Date.now() + offsetDays * 86_400_000);
  try {
    const parts = new Intl.DateTimeFormat("en-CA", {
      timeZone,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    }).format(shifted);
    return parts;
  } catch {
    return shifted.toISOString().slice(0, 10);
  }
}
