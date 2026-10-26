import assert from "node:assert/strict";
import test from "node:test";

import { approvalErrors, isWikiUrl, wordCount } from "../lib/gate.js";

const base = {
  type: "quote",
  verified: true,
  wordCount: 8,
  sources: [
    {
      title: "A printed book",
      url: "https://archive.org/details/example",
      sourceType: "primary",
      confidence: "confirmed",
      pageOrTimestamp: "p. 12",
    },
  ],
  speech: null,
  author: { isLiving: false, speakerType: "person" },
  onWatchlist: false,
  deeper: { generatedBy: "human", humanReviewed: true },
  charactersEnabled: false,
};

test("a sourced public-domain quote passes", () => {
  assert.deepEqual(approvalErrors(base), []);
});

test("refuses an item the editor has not marked verified", () => {
  const errors = approvalErrors({ ...base, verified: false });
  assert.ok(errors.some((error) => error.includes("verified")));
});

test("refuses a missing source", () => {
  const errors = approvalErrors({ ...base, sources: [] });
  assert.ok(errors.some((error) => error.includes("source")));
});

test("refuses wiki domains as the approving source", () => {
  for (const url of [
    "https://en.wikiquote.org/wiki/Example",
    "https://en.wikipedia.org/wiki/Example",
    "https://en.wikisource.org/wiki/Example",
  ]) {
    assert.equal(isWikiUrl(url), true);
    const errors = approvalErrors({
      ...base,
      sources: [{ ...base.sources[0], url }],
    });
    assert.ok(errors.some((error) => error.includes("wiki")));
  }
});

test("refuses a speech with unknown rights", () => {
  const errors = approvalErrors({
    ...base,
    type: "speech",
    speech: { rightsStatus: "unknown" },
  });
  assert.ok(errors.some((error) => error.includes("rightsStatus")));
});

test("a living author needs a primary page or timestamp", () => {
  const errors = approvalErrors({
    ...base,
    author: { isLiving: true, speakerType: "person" },
    sources: [{ ...base.sources[0], sourceType: "secondary", pageOrTimestamp: "" }],
  });
  assert.ok(errors.some((error) => error.includes("living")));
});

test("a watchlist author needs a confirmed primary source", () => {
  const errors = approvalErrors({
    ...base,
    onWatchlist: true,
    sources: [{ ...base.sources[0], confidence: "probable", sourceType: "secondary" }],
  });
  assert.ok(errors.some((error) => error.includes("watchlist")));
});

test("AI deeper text cannot publish until a human reviews it", () => {
  const errors = approvalErrors({
    ...base,
    deeper: { generatedBy: "ai", humanReviewed: false },
  });
  assert.ok(errors.some((error) => error.includes("humanReviewed")));
});

test("quotes over 40 words need an override reason", () => {
  const errors = approvalErrors({ ...base, wordCount: 41 });
  assert.ok(errors.some((error) => error.includes("40")));
  assert.deepEqual(approvalErrors({ ...base, wordCount: 41, longQuoteOverrideReason: "The sentence is one passage." }), []);
});

test("characters stay off until the flag is enabled", () => {
  const errors = approvalErrors({
    ...base,
    author: { isLiving: false, speakerType: "character" },
  });
  assert.ok(errors.some((error) => error.includes("Characters")));
  assert.deepEqual(
    approvalErrors({
      ...base,
      author: { isLiving: false, speakerType: "character" },
      charactersEnabled: true,
    }),
    [],
  );
});

test("word count splits on whitespace", () => {
  assert.equal(wordCount("  one   two three "), 3);
});
