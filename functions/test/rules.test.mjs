import { readFileSync } from "node:fs";
import assert from "node:assert/strict";
import test from "node:test";
import { assertFails, assertSucceeds, initializeTestEnvironment } from "@firebase/rules-unit-testing";
import { doc, getDoc, setDoc } from "firebase/firestore";

const testEnv = await initializeTestEnvironment({
  projectId: "motiscroll",
  firestore: {
    rules: readFileSync(new URL("../../firestore.rules", import.meta.url), "utf8"),
    host: "127.0.0.1",
    port: 8080,
  },
});

test.after(async () => {
  await testEnv.cleanup();
});

test("anonymous users cannot read draft items", async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "items/draft-1"), { status: "draft", text: "hidden" });
  });
  const anon = testEnv.authenticatedContext("anon-user").firestore();
  await assertFails(getDoc(doc(anon, "items/draft-1")));
});

test("a signed-in user can read published items and cannot write them", async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "publishedItems/line-1"), { text: "visible" });
  });
  const user = testEnv.authenticatedContext("reader").firestore();
  await assertSucceeds(getDoc(doc(user, "publishedItems/line-1")));
  await assertFails(setDoc(doc(user, "publishedItems/line-1"), { text: "changed" }));
});

test("a user cannot read another user's document", async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "users/owner"), { displayName: "Ada" });
  });
  const other = testEnv.authenticatedContext("someone-else").firestore();
  await assertFails(getDoc(doc(other, "users/owner")));
});

test("a user cannot write their own streak fields", async () => {
  const user = testEnv.authenticatedContext("streak-user").firestore();
  await assertSucceeds(setDoc(doc(user, "users/streak-user"), { displayName: "Ada", timezone: "UTC" }));
  await assertFails(
    setDoc(doc(user, "users/streak-user"), { streakCount: 99, lastActiveDate: "2099-01-01" }, { merge: true }),
  );
});

test("reports can be created only as yourself", async () => {
  const user = testEnv.authenticatedContext("reporter").firestore();
  await assertSucceeds(
    setDoc(doc(user, "reports/r1"), {
      itemId: "line-1",
      userId: "reporter",
      reason: "wrong attribution",
      note: "Check the letter.",
      status: "open",
      createdAt: new Date(),
    }),
  );
  await assertFails(getDoc(doc(user, "reports/r1")));
  assert.ok(true);
});
