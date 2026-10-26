import { getMessaging } from "firebase-admin/messaging";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";

export const writeDaily = onSchedule("every day 00:05", async () => {
  const day = new Date().toISOString().slice(0, 10);
  const db = getFirestore();
  const ref = db.collection("daily").doc(day);
  if ((await ref.get()).exists) return;
  const snap = await db.collection("publishedItems").where("type", "==", "quote").limit(30).get();
  if (snap.empty) return;
  const index = [...day].reduce((sum, char) => sum + char.charCodeAt(0), 0) % snap.size;
  const pick = snap.docs[index];
  await ref.set({
    itemId: pick.id,
    publishedItemSnapshot: pick.data(),
    createdAt: FieldValue.serverTimestamp(),
  });
});

export const syncReminderBucket = onDocumentWritten("users/{uid}", async (event) => {
  const after = event.data?.after;
  if (!after?.exists) return;
  const data = after.data() ?? {};
  const bucket = utcBucket(String(data.reminderTime ?? ""), String(data.timezone ?? "UTC"));
  if (data.reminderUtcBucket === bucket) return;
  await after.ref.set({ reminderUtcBucket: bucket }, { merge: true });
});

export const sendReminderBucket = onSchedule("every 15 minutes", async () => {
  const now = new Date();
  const bucket = Math.floor((now.getUTCHours() * 60 + now.getUTCMinutes()) / 15) * 15;
  const day = now.toISOString().slice(0, 10);
  const db = getFirestore();
  const daily = await db.collection("daily").doc(day).get();
  const quote = String(daily.data()?.publishedItemSnapshot?.text ?? "");
  if (!quote) return;
  const users = await db.collection("users").where("reminderUtcBucket", "==", bucket).limit(200).get();
  for (const user of users.docs) {
    const data = user.data();
    if (data.lastPushDate === day || data.reminderLocal === true) continue;
    const tokens = Array.isArray(data.fcmTokens) ? data.fcmTokens.map(String) : [];
    if (tokens.length === 0) continue;
    const response = await getMessaging().sendEachForMulticast({
      tokens,
      notification: { title: "Moti Scroll", body: quote.slice(0, 140) },
      data: { itemId: String(daily.data()?.itemId ?? "") },
    });
    const invalid: string[] = [];
    response.responses.forEach((entry, index) => {
      const code = entry.error?.code ?? "";
      if (code.includes("registration-token-not-registered") || code.includes("invalid-argument")) {
        invalid.push(tokens[index]);
      }
    });
    await user.ref.set(
      {
        lastPushDate: day,
        fcmTokens: tokens.filter((token) => !invalid.includes(token)),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }
});

function utcBucket(time: string, timeZone: string): number {
  const match = /^(\d{1,2}):(\d{2})$/.exec(time.trim());
  if (!match) return -1;
  const hour = Number(match[1]);
  const minute = Number(match[2]);
  if (hour > 23 || minute > 59) return -1;
  const now = new Date();
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone: timeZone || "UTC",
    hour12: false,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  }).formatToParts(now);
  const value = (type: string) => Number(parts.find((part) => part.type === type)?.value ?? "0");
  const asUtc = Date.UTC(value("year"), value("month") - 1, value("day"), value("hour") % 24, value("minute"));
  const offset = Math.round((asUtc - now.getTime()) / 60000);
  const utcMinutes = (((hour * 60 + minute - offset) % 1440) + 1440) % 1440;
  return Math.floor(utcMinutes / 15) * 15;
}
