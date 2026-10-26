import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { onDocumentWritten } from "firebase-functions/v2/firestore";

import { unpublishForReview } from "./approve.js";
import { wordCount } from "./gate.js";
import { llmApiKey } from "./secrets.js";

const blocked = ["fuck", "shit", "nigger", "faggot"];

function normalize(text: string): string {
  return text.toLowerCase().replace(/[^a-z0-9\s]/g, "").replace(/\s+/g, " ").trim();
}

export const onCandidateCreated = onDocumentWritten(
  { document: "items/{itemId}", secrets: [llmApiKey] },
  async (event) => {
    const after = event.data?.after;
    if (!after?.exists) return;
    const data = after.data() ?? {};
    if (data.status !== "candidate") return;
    const before = event.data?.before?.data();
    if (before?.status === "candidate" && before.text === data.text) return;

    const db = getFirestore();
    const text = String(data.text ?? "");
    const authorId = String(data.authorId ?? "");
    const warnings: string[] = [];
    const reasons: string[] = [];
    const count = wordCount(text);
    if (count > 40) warnings.push("too_long");
    if (count === 0 || !authorId) reasons.push("A candidate needs text and an author.");
    const norm = normalize(text);
    if (blocked.some((term) => norm.includes(term))) {
      reasons.push("The text matched the block list.");
    }
    const dupes = await db.collection("items").where("authorId", "==", authorId).limit(20).get();
    for (const doc of dupes.docs) {
      if (doc.id === after.id) continue;
      const other = normalize(String(doc.data().text ?? ""));
      if (other && other === norm) reasons.push("This text is already in the catalog for that author.");
      else if (other && other.slice(0, 80) === norm.slice(0, 80) && norm.length > 40) {
        warnings.push("duplicate_suspected");
      }
    }
    const watch = await db.collection("misattributionWatchlist").doc(authorId).get();
    if (watch.exists) warnings.push("misattribution_watchlist");

    let field = data.field;
    let moods = data.moods;
    const key = llmApiKey.value();
    if (key && text && authorId && !field) {
      try {
        const suggestion = await suggestTags(key, text, String(data.authorId));
        field = suggestion.field;
        moods = suggestion.moods;
        warnings.push("tags_are_suggestions");
      } catch (error) {
        console.error("tag suggestion failed", error);
      }
    }

    await after.ref.set(
      {
        status: reasons.length ? "rejected" : "needs_review",
        rejectionReason: reasons.join(" "),
        warnings,
        wordCount: count,
        field: field ?? "other",
        moods: Array.isArray(moods) ? moods : [],
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  },
);

export const onItemWritten = onDocumentWritten("items/{itemId}", async (event) => {
  const before = event.data?.before?.data();
  const after = event.data?.after?.data();
  if (!before || !after) return;
  if (before.status !== "approved") return;
  if (after.status !== "approved") return;
  const textChanged = before.text !== after.text;
  const authorChanged = before.authorId !== after.authorId;
  if (!textChanged && !authorChanged) return;
  await unpublishForReview(event.params.itemId, "edited_after_approval");
});

export const onSourceWritten = onDocumentWritten(
  "items/{itemId}/sources/{sourceId}",
  async (event) => {
    const db = getFirestore();
    const item = await db.collection("items").doc(event.params.itemId).get();
    if (item.data()?.status !== "approved") return;
    await unpublishForReview(event.params.itemId, "source_edited_after_approval");
  },
);

export const onReportCreated = onDocumentWritten("reports/{reportId}", async (event) => {
  const data = event.data?.after?.data();
  if (!data || data.status !== "open") return;
  const db = getFirestore();
  const open = await db
    .collection("reports")
    .where("itemId", "==", data.itemId)
    .where("status", "==", "open")
    .limit(5)
    .get();
  if (open.size >= 2) {
    await unpublishForReview(String(data.itemId), "reports");
  }
});

async function suggestTags(key: string, text: string, authorId: string) {
  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      model: "gpt-4o-mini",
      temperature: 0,
      messages: [
        {
          role: "system",
          content:
            "Tag a quote. Reply with JSON {\"field\":\"sports|business|science|arts|leadership|resilience|other\",\"moods\":[\"startingOver|badDay|needFocus|preWorkout|examStress|feelingStuck\"]}. Suggestions only. Do not invent facts.",
        },
        { role: "user", content: `${authorId}\n${text.slice(0, 800)}` },
      ],
    }),
  });
  if (!response.ok) throw new Error(await response.text());
  const body = (await response.json()) as { choices?: { message?: { content?: string } }[] };
  const raw = body.choices?.[0]?.message?.content ?? "{}";
  const parsed = JSON.parse(raw.replace(/```json|```/g, "")) as { field?: string; moods?: string[] };
  return { field: parsed.field ?? "other", moods: parsed.moods ?? [] };
}
