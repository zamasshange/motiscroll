import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { initializeApp } from "firebase-admin/app";

initializeApp();

const watchlist = [
  ["albert-einstein", "Einstein quotations are widely misattributed."],
  ["mark-twain", "Twain quotations are widely misattributed."],
  ["winston-churchill", "Churchill quotations are widely misattributed."],
  ["mahatma-gandhi", "Gandhi quotations are widely misattributed."],
  ["abraham-lincoln", "Lincoln quotations need a confirmed primary text."],
  ["marilyn-monroe", "Monroe quotations are widely misattributed."],
  ["buddha", "Buddha quotations are widely misattributed."],
  ["nelson-mandela", "Mandela quotations are widely misattributed."],
  ["maya-angelou", "Angelou quotations are widely misattributed."],
  ["steve-jobs", "Jobs quotations are widely misattributed."],
] as const;

const db = getFirestore();
const batch = db.batch();
batch.set(
  db.collection("config").doc("flags"),
  {
    charactersEnabled: false,
    livingFiguresEnabled: true,
    updatedAt: FieldValue.serverTimestamp(),
  },
  { merge: true },
);
for (const [id, note] of watchlist) {
  batch.set(db.collection("misattributionWatchlist").doc(id), { note }, { merge: true });
}
batch.commit().then(() => {
  console.log("Wrote config/flags and the misattribution watchlist. Quotes are loaded by npm run bootstrap.");
});
