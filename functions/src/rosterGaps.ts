import { readFileSync, writeFileSync } from "node:fs";

import { firstAllowedPortrait } from "./images.js";
import { lookupExactHuman, lookupWikipediaPrimary } from "./resolveAuthors.js";

function p18Files(entity: { claims?: Record<string, { mainsnak?: { datavalue?: { value?: unknown } } }[]> }): string[] {
  return (entity.claims?.P18 ?? [])
    .map((claim) => claim.mainsnak?.datavalue?.value)
    .filter((value): value is string => typeof value === "string" && value.length > 0);
}

async function main() {
  const names = JSON.parse(readFileSync("/tmp/missing-authors.json", "utf8")) as string[];
  const out: Record<string, { downloadUrl: string; artist: string; license: string; sourceUrl: string } | { reason: string }> = {};
  let cursor = 0;
  let pictured = 0;
  async function worker() {
    while (cursor < names.length) {
      const name = names[cursor];
      cursor += 1;
      try {
        const exact = await lookupExactHuman(name);
        const found = exact.ok ? exact : await lookupWikipediaPrimary(name);
        if (!found.ok) {
          out[name] = { reason: found.reason };
          continue;
        }
        const portrait = await firstAllowedPortrait(p18Files(found.entity));
        out[name] = portrait ?? { reason: "no-usable-portrait" };
        if (portrait) pictured += 1;
      } catch (error) {
        out[name] = { reason: error instanceof Error ? error.message : "lookup failed" };
      }
      if (Object.keys(out).length % 20 === 0) {
        writeFileSync("/tmp/roster-portraits.json", JSON.stringify(out));
        console.log(`checked ${Object.keys(out).length} of ${names.length}, photos ${pictured}`);
      }
    }
  }
  await Promise.all(Array.from({ length: 4 }, () => worker()));
  writeFileSync("/tmp/roster-portraits.json", JSON.stringify(out));
  console.log(`checked ${names.length}, photos ${pictured}`);
}

main().catch((error: unknown) => {
  console.error(error);
  process.exit(1);
});
