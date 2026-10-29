import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { homedir, tmpdir } from "node:os";
import { join } from "node:path";

const clientId = "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com";
const clientSecret = "j9iVZfS8kkCEFUPaAeJV0sAi";

export function useFirebaseCliCredential() {
  if (process.env.GOOGLE_APPLICATION_CREDENTIALS || process.env.FIRESTORE_EMULATOR_HOST) return;
  const store = join(homedir(), ".config/configstore/firebase-tools.json");
  if (!existsSync(store)) return;
  const parsed = JSON.parse(readFileSync(store, "utf8")) as {
    tokens?: { refresh_token?: string };
  };
  const refresh = parsed.tokens?.refresh_token;
  if (!refresh) return;
  const file = join(tmpdir(), "moti-scroll-adc.json");
  writeFileSync(
    file,
    JSON.stringify({
      type: "authorized_user",
      client_id: clientId,
      client_secret: clientSecret,
      refresh_token: refresh,
    }),
  );
  process.env.GOOGLE_APPLICATION_CREDENTIALS = file;
}
