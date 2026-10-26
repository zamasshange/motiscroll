import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { onDocumentWritten } from "firebase-functions/v2/firestore";

import { llmApiKey } from "./secrets.js";

export const draftDeeper = onDocumentWritten(
  { document: "items/{itemId}", secrets: [llmApiKey], timeoutSeconds: 120 },
  async (event) => {
    const after = event.data?.after;
    if (!after?.exists) return;
    const data = after.data() ?? {};
    if (data.status !== "needs_review") return;
    const key = llmApiKey.value();
    if (!key) return;
    const deeperRef = after.ref.collection("deeper").doc("main");
    const existing = await deeperRef.get();
    if (existing.exists) return;
    const sources = await after.ref.collection("sources").limit(3).get();
    if (sources.empty) return;
    const sourceText = sources.docs
      .map((doc) => `${doc.data().title ?? ""} ${doc.data().url ?? ""} ${doc.data().pageOrTimestamp ?? ""}`)
      .join("\n");
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
              "Write Go deeper notes as JSON {context, didYouKnow, takeaway}. Use only facts supported by the provided source. If you do not know, write \"unknown\". Never invent dates, places, quotes, or events.",
          },
          {
            role: "user",
            content: `Quote: ${String(data.text ?? "").slice(0, 1200)}\nAuthor: ${data.authorId}\nSource:\n${sourceText.slice(0, 1500)}`,
          },
        ],
      }),
    });
    if (!response.ok) {
      console.error("draftDeeper failed", await response.text());
      return;
    }
    const body = (await response.json()) as { choices?: { message?: { content?: string } }[] };
    const raw = body.choices?.[0]?.message?.content ?? "{}";
    let parsed: { context?: string; didYouKnow?: string; takeaway?: string } = {};
    try {
      parsed = JSON.parse(raw.replace(/```json|```/g, ""));
    } catch {
      return;
    }
    await deeperRef.set({
      context: String(parsed.context ?? "unknown").slice(0, 1200),
      didYouKnow: String(parsed.didYouKnow ?? "unknown").slice(0, 800),
      takeaway: String(parsed.takeaway ?? "unknown").slice(0, 400),
      generatedBy: "ai",
      aiModel: "gpt-4o-mini",
      humanReviewed: false,
      reviewedBy: null,
      createdAt: FieldValue.serverTimestamp(),
    });
  },
);
