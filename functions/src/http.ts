import { contactEmail } from "./secrets.js";

export async function fetchText(url: string, attempt = 0): Promise<string> {
  const email = contactEmail.value() || "editor@example.com";
  const response = await fetch(url, {
    headers: {
      "User-Agent": `MotiScroll/1.0 (public-domain quote catalog; ${email})`,
      Accept: "application/json, text/plain, */*",
    },
  });
  if ((response.status === 429 || response.status >= 500) && attempt < 4) {
    const wait = 500 * 2 ** attempt;
    await new Promise((resolve) => setTimeout(resolve, wait));
    return fetchText(url, attempt + 1);
  }
  if (!response.ok) {
    throw new Error(`${response.status} from ${url}`);
  }
  return response.text();
}

export function clip(value: unknown, max: number): string {
  return String(value ?? "").slice(0, max);
}
