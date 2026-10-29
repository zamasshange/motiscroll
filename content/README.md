# Manual curation

`manual_items.csv` is the path for living people and anyone whose words are still in copyright. Kanye West, Lionel Messi, LeBron James, Steven Bartlett, Nelson Mandela, Oprah Winfrey, Steve Harvey, Maya Angelou, Muhammad Ali, and Michael Jordan belong here. Do not type a quotation from memory.

Fill one row per line:

- `text` — the exact words, copied from the source you have open.
- `authorId` — the author slug (`kanye-west`, `lionel-messi`, `lebron-james`, `steven-bartlett`, `nelson-mandela`).
- `sourceTitle` — the book, interview, or speech the words come from.
- `publisher` — who published that source.
- `year` — the year printed on that source.
- `sourceUrl` — a link to the original work. Wikiquote and Wikipedia addresses are rejected.
- `pageOrTimestamp` — page number or the timestamp you listened to.
- `field` — `sports`, `business`, `science`, `arts`, `leadership`, `resilience`, or `other`.
- `type` — `quote` or `speech`.
- `status` — leave `draft` until an editor is ready. The five rows already in the file start with `EXAMPLE ONLY` and are rejected by `importItems`.

An editor imports rows with the `importItems` callable, then approves them in the review queue. Living authors need a primary source and a page or timestamp. Watchlist authors need that source marked confirmed.
