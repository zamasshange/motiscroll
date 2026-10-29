import assert from "node:assert/strict";
import test from "node:test";

import {
  parseAddicted2Success,
  parseEfQuotes,
  parseMyPicture,
  parseReadersDigest,
  parseShakespeare,
} from "../lib/importLists.js";

test("parses a Reader's Digest line and its speaker", () => {
  const quotes = parseReadersDigest(
    '1\\. “Always forgive your enemies; nothing annoys them so much.”—_Oscar Wilde (June 1954)_',
  );
  assert.equal(quotes.length, 1);
  assert.equal(quotes[0].author, "Oscar Wilde");
  assert.match(quotes[0].text, /forgive your enemies/);
  assert.equal(quotes[0].url.includes("rd.com"), true);
});

test("parses an Addicted2Success line", () => {
  const quotes = parseAddicted2Success(
    '**1**. “Be humble, hungry, and always be the hardest worker in the room.” – **Dwayne ‘The Rock’ Johnson**',
  );
  assert.equal(quotes[0].author, "Dwayne ‘The Rock’ Johnson");
});

test("parses a MYPICTURE line and drops the attributed note from the name", () => {
  const quotes = parseMyPicture(
    '* "In a time of deceit, telling the truth is a revolutionary act." — George Orwell (attributed)\n',
  );
  assert.equal(quotes[0].author, "George Orwell");
});

test("parses the EF table and skips characters", () => {
  const html = `<table><tr><td>Quote</td><td>Who</td></tr>
    <tr><td>Knowledge is power.</td><td>Sir Francis Bacon</td><td>Latin</td></tr>
    <tr><td>I'll be back.</td><td>Terminator (character)</td><td>English</td></tr></table>`;
  const quotes = parseEfQuotes(html);
  assert.equal(quotes.length, 1);
  assert.equal(quotes[0].author, "Sir Francis Bacon");
});

test("attributes a Shakespeare Birthplace Trust quote to Shakespeare and keeps the scene", () => {
  const html = `<blockquote class="blockquote"><p class="blockquote-text">To be, or not to be, that is the question</p>
    <cite class="blockquote-cite">— Hamlet, Act 3 Scene 1, lines 56-83; Hamlet</cite></blockquote>`;
  const quotes = parseShakespeare(html);
  assert.equal(quotes[0].author, "William Shakespeare");
  assert.match(quotes[0].sourceTitle, /Hamlet, Act 3 Scene 1/);
});
