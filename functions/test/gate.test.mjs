import assert from "node:assert/strict";
import test from "node:test";

import { approvalErrors, wordCount } from "../lib/gate.js";

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

test("the approval gate does not block publishing", () => {
  const cases = [
    base,
    { ...base, verified: false },
    { ...base, sources: [] },
    { ...base, sources: [{ ...base.sources[0], url: "https://en.wikiquote.org/wiki/Example" }] },
    { ...base, sources: [{ ...base.sources[0], url: "https://www.goodreads.com/quotes" }] },
    { ...base, type: "speech", speech: { rightsStatus: "unknown" } },
    {
      ...base,
      author: { isLiving: true, speakerType: "person" },
      sources: [{ ...base.sources[0], sourceType: "secondary", pageOrTimestamp: "" }],
    },
    {
      ...base,
      onWatchlist: true,
      sources: [{ ...base.sources[0], confidence: "probable", sourceType: "secondary" }],
    },
    { ...base, deeper: { generatedBy: "ai", humanReviewed: false } },
    { ...base, wordCount: 41 },
    { ...base, author: { isLiving: false, speakerType: "character" } },
  ];
  for (const input of cases) assert.deepEqual(approvalErrors(input), []);
});

test("word count splits on whitespace", () => {
  assert.equal(wordCount("  one   two three "), 3);
});
