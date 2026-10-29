import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import { assertEditor } from "./authz.js";
import { approvalErrors, wordCount, type ApprovalInput, type SourceDoc } from "./gate.js";
import { enforceAppCheck } from "./secrets.js";

const callable = { enforceAppCheck: enforceAppCheck(), timeoutSeconds: 60 };

export const previewApproval = onCall(callable, async (request) => {
  assertEditor(request);
  const itemId = String(request.data?.itemId ?? "").trim();
  if (!itemId) throw new HttpsError("invalid-argument", "itemId is required.");
  const input = await loadApprovalInput(itemId, String(request.data?.longQuoteOverrideReason ?? ""));
  return { errors: approvalErrors(input) };
});

export async function approveItemById(
  itemId: string,
  editor: string,
  override = "",
  options?: { recount?: boolean },
) {
  if (!itemId || itemId.length > 120) {
    throw new HttpsError("invalid-argument", "itemId is required.");
  }
  const db = getFirestore();
  const itemRef = db.collection("items").doc(itemId);
  await db.runTransaction(async (tx) => {
    const itemSnap = await tx.get(itemRef);
    if (!itemSnap.exists) throw new HttpsError("not-found", "That item does not exist.");
    const item = itemSnap.data() ?? {};
    const sourcesSnap = await tx.get(itemRef.collection("sources"));
    const deeperSnap = await tx.get(itemRef.collection("deeper").doc("main"));
    const speechSnap = await tx.get(itemRef.collection("speech").doc("main"));
    const authorSnap = await tx.get(db.collection("authors").doc(String(item.authorId ?? "")));
    const watchSnap = await tx.get(db.collection("misattributionWatchlist").doc(String(item.authorId ?? "")));
    const flagsSnap = await tx.get(db.collection("config").doc("flags"));
    const sources = sourcesSnap.docs.map((doc) => doc.data() as SourceDoc);
    const author = authorSnap.data() ?? {};
    const text = String(item.text ?? "");
    const errors = approvalErrors(approvalFrom(item, text, sources, author, speechSnap.data(), deeperSnap.data(), watchSnap.exists, flagsSnap.data()?.charactersEnabled === true, override));
    if (errors.length > 0) {
      throw new HttpsError("failed-precondition", errors.join(" "));
    }
    const primary = sources.find((source) => source.url) ?? sources[0];
    const deeper = deeperSnap.data();
    const speech = speechSnap.data();
    const published = {
      text,
      type: item.type ?? "quote",
      field: item.field ?? "other",
      moods: Array.isArray(item.moods) ? item.moods : [],
      rand: typeof item.rand === "number" ? item.rand : Math.random(),
      authorId: item.authorId ?? "",
      authorName: author.name ?? "",
      authorRole: author.role ?? "",
      authorImageUrl: author.image?.downloadUrl ?? null,
      imageCredit: author.image ?? null,
      primarySource: {
        title: primary?.title ?? "",
        year: primary?.year ?? null,
        url: primary?.url ?? "",
        pageOrTimestamp: primary?.pageOrTimestamp ?? "",
      },
      deeper: deeper
        ? {
            context: deeper.context ?? "",
            didYouKnow: deeper.didYouKnow ?? "",
            takeaway: deeper.takeaway ?? "",
          }
        : { context: "", didYouKnow: "", takeaway: "" },
      related: Array.isArray(item.related) ? item.related : [],
      speech: speech
        ? {
            durationSec: speech.durationSec ?? 0,
            watchUrl: speech.watchUrl ?? "",
            embedAllowed: speech.embedAllowed === true,
          }
        : null,
      publishedAt: FieldValue.serverTimestamp(),
    };
    tx.set(
      itemRef,
      {
        status: "approved",
        verified: true,
        approvedBy: editor,
        approvedAt: FieldValue.serverTimestamp(),
        rejectionReason: FieldValue.delete(),
        wordCount: wordCount(text),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    tx.set(db.collection("publishedItems").doc(itemId), published);
  });
  if (options?.recount !== false) await recomputeCollectionCounts();
  return { ok: true };
}

export const approveItem = onCall(callable, async (request) => {
  const editor = assertEditor(request);
  const itemId = String(request.data?.itemId ?? "").trim();
  const override = String(request.data?.longQuoteOverrideReason ?? "").trim();
  return approveItemById(itemId, editor, override);
});

export const approveBatch = onCall({ ...callable, timeoutSeconds: 300 }, async (request) => {
  const editor = assertEditor(request);
  const raw = Array.isArray(request.data?.itemIds) ? request.data.itemIds : null;
  if (!raw || raw.length === 0) {
    throw new HttpsError("invalid-argument", "Pass itemIds, up to 25.");
  }
  if (raw.length > 25) {
    throw new HttpsError("invalid-argument", "Approve at most 25 items at a time.");
  }
  const approved: string[] = [];
  const skipped: { itemId: string; reason: string }[] = [];
  for (const value of raw) {
    const itemId = String(value ?? "").trim();
    try {
      await approveItemById(itemId, editor, "", { recount: false });
      approved.push(itemId);
    } catch (error) {
      const reason = error instanceof HttpsError ? error.message : "That item could not be approved.";
      skipped.push({ itemId, reason });
    }
  }
  await recomputeCollectionCounts();
  return { approved, skipped };
});

const collectionFields = ["sports", "business", "science", "arts", "leadership", "resilience", "other"];

export async function recomputeCollectionCounts() {
  const db = getFirestore();
  const snap = await db.collection("publishedItems").get();
  const counts = new Map<string, number>(collectionFields.map((field) => [field, 0]));
  for (const doc of snap.docs) {
    const field = String(doc.data().field ?? "other");
    counts.set(field, (counts.get(field) ?? 0) + 1);
  }
  for (const [field, itemCount] of counts) {
    await db.collection("collections").doc(field).set(
      {
        title: field,
        description: "",
        coverSeed: field,
        itemCount,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }
}

export const rejectItem = onCall(callable, async (request) => {
  assertEditor(request);
  const itemId = String(request.data?.itemId ?? "").trim();
  const reason = String(request.data?.reason ?? "").trim();
  if (!itemId || !reason) {
    throw new HttpsError("invalid-argument", "itemId and a reason are required.");
  }
  const db = getFirestore();
  await db.collection("items").doc(itemId).set(
    {
      status: "rejected",
      rejectionReason: reason.slice(0, 500),
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  await db.collection("publishedItems").doc(itemId).delete();
  await recomputeCollectionCounts();
  return { ok: true };
});

export const retireItem = onCall(callable, async (request) => {
  const editor = assertEditor(request);
  const itemId = String(request.data?.itemId ?? "").trim();
  if (!itemId) throw new HttpsError("invalid-argument", "itemId is required.");
  const db = getFirestore();
  await db.collection("items").doc(itemId).set(
    {
      status: "retired",
      updatedAt: FieldValue.serverTimestamp(),
      retiredBy: editor,
    },
    { merge: true },
  );
  await db.collection("publishedItems").doc(itemId).delete();
  await recomputeCollectionCounts();
  return { ok: true };
});

export async function unpublishForReview(itemId: string, reason: string) {
  const db = getFirestore();
  await db.collection("items").doc(itemId).set(
    {
      status: "needs_review",
      verified: false,
      warnings: FieldValue.arrayUnion(reason),
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  await db.collection("publishedItems").doc(itemId).delete();
  await recomputeCollectionCounts();
}

async function loadApprovalInput(itemId: string, override: string): Promise<ApprovalInput> {
  const db = getFirestore();
  const itemRef = db.collection("items").doc(itemId);
  const itemSnap = await itemRef.get();
  if (!itemSnap.exists) throw new HttpsError("not-found", "That item does not exist.");
  const item = itemSnap.data() ?? {};
  const sourcesSnap = await itemRef.collection("sources").get();
  const deeperSnap = await itemRef.collection("deeper").doc("main").get();
  const speechSnap = await itemRef.collection("speech").doc("main").get();
  const authorSnap = await db.collection("authors").doc(String(item.authorId ?? "")).get();
  const watchSnap = await db.collection("misattributionWatchlist").doc(String(item.authorId ?? "")).get();
  const flagsSnap = await db.collection("config").doc("flags").get();
  return approvalFrom(
    item,
    String(item.text ?? ""),
    sourcesSnap.docs.map((doc) => doc.data() as SourceDoc),
    authorSnap.data() ?? {},
    speechSnap.data(),
    deeperSnap.data(),
    watchSnap.exists,
    flagsSnap.data()?.charactersEnabled === true,
    override,
  );
}

function approvalFrom(
  item: FirebaseFirestore.DocumentData,
  text: string,
  sources: SourceDoc[],
  author: FirebaseFirestore.DocumentData,
  speech: FirebaseFirestore.DocumentData | undefined,
  deeper: FirebaseFirestore.DocumentData | undefined,
  onWatchlist: boolean,
  charactersEnabled: boolean,
  override: string,
): ApprovalInput {
  return {
    type: item.type === "speech" ? "speech" : "quote",
    verified: true,
    wordCount: wordCount(text),
    longQuoteOverrideReason: override,
    sources,
    speech: speech ? { rightsStatus: speech.rightsStatus } : null,
    author: {
      isLiving: author.isLiving === true,
      speakerType: author.speakerType === "character" ? "character" : "person",
    },
    onWatchlist,
    deeper: deeper
      ? { generatedBy: deeper.generatedBy, humanReviewed: deeper.humanReviewed === true }
      : null,
    charactersEnabled,
  };
}
