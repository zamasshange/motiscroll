import assert from "node:assert/strict";
import test from "node:test";

import { parseGoodreadsQuotes } from "../lib/importGoodreads.js";

test("parses a Goodreads quote block", () => {
  const html = `
    <div class='quote'>
      <div class="quoteText">
        &ldquo;Be yourself; everyone else is already taken.&rdquo;
        <br />
        &#8213;
        <span class="authorOrTitle">Oscar Wilde</span>
      </div>
      <a title="View this quote" href="/quotes/19884-be-yourself-everyone-else-is-already-taken">likes</a>
    </div>
    <div class='quote'>
      <div class="quoteText">
        &ldquo;If you want to know what a man's like.&rdquo;
        <br />
        <span class="authorOrTitle">J.K. Rowling,</span>
        <a class="authorOrTitle" href="/work/quotes/1">Harry Potter and the Goblet of Fire</a>
      </div>
      <a href="/quotes/8630-if-you-want-to-know">likes</a>
    </div>`;
  const quotes = parseGoodreadsQuotes(html);
  assert.equal(quotes.length, 2);
  assert.deepEqual(quotes[0], {
    id: "19884",
    text: "Be yourself; everyone else is already taken.",
    author: "Oscar Wilde",
    book: "",
    url: "https://www.goodreads.com/quotes/19884-be-yourself-everyone-else-is-already-taken",
  });
  assert.equal(quotes[1].author, "J.K. Rowling");
  assert.equal(quotes[1].book, "Harry Potter and the Goblet of Fire");
});

test("keeps a Goodreads quote that breaks across lines", () => {
  const html = `
    <div class='quote'>
      <div class="quoteText">
        &ldquo;The story so far:<br />In the beginning the Universe was created.&rdquo;
        <br />
        &#8213;
        <span class="authorOrTitle">Douglas Adams</span>
      </div>
      <a href="/quotes/1-the-story-so-far">likes</a>
    </div>`;
  const quotes = parseGoodreadsQuotes(html);
  assert.equal(
    quotes[0].text,
    "The story so far: In the beginning the Universe was created.",
  );
  assert.equal(quotes[0].author, "Douglas Adams");
});
