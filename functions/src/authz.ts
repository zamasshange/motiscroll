import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";

const recent = new Map<string, number[]>();

export function assertEditor(request: CallableRequest<unknown>): string {
  const uid = request.auth?.uid;
  const editor = request.auth?.token?.editor === true;
  if (!uid || !editor) {
    throw new HttpsError("permission-denied", "This action is limited to editors.");
  }
  rateLimit(uid);
  const size = JSON.stringify(request.data ?? {}).length;
  if (size > 48_000) {
    throw new HttpsError("invalid-argument", "That payload is too large.");
  }
  return uid;
}

export function assertSignedIn(request: CallableRequest<unknown>): string {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in first.");
  rateLimit(uid);
  const size = JSON.stringify(request.data ?? {}).length;
  if (size > 8_000) {
    throw new HttpsError("invalid-argument", "That payload is too large.");
  }
  return uid;
}

function rateLimit(uid: string) {
  const now = Date.now();
  const windowed = (recent.get(uid) ?? []).filter((stamp) => now - stamp < 60_000);
  if (windowed.length >= 40) {
    throw new HttpsError("resource-exhausted", "Too many requests. Wait a minute and try again.");
  }
  windowed.push(now);
  recent.set(uid, windowed);
}
