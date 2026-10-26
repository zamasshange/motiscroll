# Moti Scroll

Flutter app of public-domain quotes and short speech excerpts. Four tabs: Collections, Discover, Home, Feed. The visual design is fixed. Phase 2 adds Firebase behind that design.

The app reads the local catalog unless you pass `--dart-define=USE_FIREBASE=true`. With that flag it reads only `publishedItems` (one document per card). Drafts, candidates, and author records stay in the editor workflow.

Cloud Functions that call Wikiquote, Wikimedia, YouTube, or an LLM need the Firebase **Blaze** (pay-as-you-go) plan, because those calls leave Google's network. Set a budget alert on the `motiscroll` project before the first deploy.

There is no ad SDK and no Firebase Analytics. Crashlytics is the only crash reporter, and it starts only when Firebase is on and a native app config exists.

The `app/`, `data/items.ts`, and `store/useStore.ts` tree is an unused Expo draft. Do not run it. The product is `lib/`.

## Local setup

```bash
flutter pub get
cd functions && npm install && cd ..
```

Copy `.env.example` to `functions/.env.local` when you want the emulator to see `CONTACT_EMAIL`, `LLM_API_KEY`, and `YOUTUBE_API_KEY`. Leave the LLM and YouTube keys empty until you have them. Do not commit that file.

```bash
flutter run
flutter test
flutter analyze
```

`flutter analyze` should be clean. Widget tests use the local catalog and do not start Firebase.

## FlutterFire

`lib/firebase_options.dart` holds the public web config for project `motiscroll`. Android and iOS still use that web app id. Before a store build, register both apps and replace the file:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=motiscroll
```

Do not add `google-services.json` until the Android app id is real. Analytics is not initialized.

Run against the emulators (Auth 9099, Firestore 8080, Functions 5001, Storage 9199, UI 4000):

```bash
flutter run --dart-define=USE_FIREBASE=true
```

`USE_EMULATOR` defaults to true. A device build that should hit production passes `--dart-define=USE_EMULATOR=false`. First launch signs in anonymously. Linking Google, Apple, or an email link keeps the same uid.

## Secrets

`CONTACT_EMAIL`, `LLM_API_KEY`, and `YOUTUBE_API_KEY` are Cloud Functions secrets (`defineSecret`). They are not in the app.

```bash
firebase functions:secrets:set CONTACT_EMAIL
firebase functions:secrets:set LLM_API_KEY
firebase functions:secrets:set YOUTUBE_API_KEY
```

For the emulator, put the same names in `functions/.env.local`.

## Emulators, rules, functions

Install the [Firebase CLI](https://firebase.google.com/docs/cli). From the repo root:

```bash
npm run emulators
```

Deploy rules, indexes, and functions (Blaze required for the outbound jobs):

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage,functions
```

Editor admin (Flutter web, separate entry point):

```bash
flutter build web -t lib/admin/main_admin.dart --dart-define=USE_FIREBASE=true --dart-define=USE_EMULATOR=false
firebase deploy --only hosting
```

## Editor role and content

```bash
npm run grant-editor -- editor@example.com
npm run seed:drafts
```

The editor must sign out and back in before the `editor` claim is visible. `grant-editor` needs Application Default Credentials for project `motiscroll`.

`seed:drafts` writes the 15 local lines into `items` as `draft`, with `verified: false`. It does not publish them. Most of those sources are wiki URLs, and `approveItem` rejects wiki hosts. They stay a human-sourcing TODO. The seed also writes the misattribution watchlist and `config/flags` (`charactersEnabled: false`, `livingFiguresEnabled: true`).

Workflow:

1. Discovery jobs (`discoverWikiquote`, `importPublicDomain`, `discoverFeeds`) or `importItems` create candidates. Wikiquote text is a hint only. Feeds store metadata, not transcripts or media.
2. A trigger flags duplicates, length, the blocklist, and the watchlist, and moves a passing candidate to `needs_review`.
3. `draftDeeper` may draft Go deeper text with `generatedBy: ai` and `humanReviewed: false`. That text cannot go live until an editor marks it reviewed.
4. The admin queue calls `approveItem`. That function is the only publisher. It refuses a missing source, any wiki URL, unknown speech rights, a living author without a primary source and page or timestamp, a watchlist author without a confirmed primary source, unreviewed AI deeper text, a quote over 40 words without an override reason, and characters while the flag is false.
5. `retireItem`, an edit to an approved line, or two open reports remove the line from `publishedItems`.

## Tests

```bash
cd functions && npm test
cd functions && npm run test:rules
```

`npm test` runs the approval-gate cases. `test:rules` needs the Firestore emulator and proves a signed-in user cannot read drafts, write `publishedItems`, read another user, or write streak fields, and can create only their own report.

## Cost

Each card is one `publishedItems` read. Discover and Feed page 20 documents and prefetch near the end. Followed fields add a second query. The daily document is one read. Scheduled reminder and daily jobs run on a clock (every 15 minutes, and once a day). Set a budget alert before deploy. Empty LLM or YouTube secrets skip those calls.

## Privacy

Settings includes Account (link, sign out, delete), Rights and sources, Privacy, and Terms. Privacy and Terms are placeholders for a lawyer. Delete account removes the user subtree and the Auth user. App Check is enforced on callable functions outside the emulator. Turn on enforcement for Firestore and Storage in the console after Play Integrity and App Attest are configured.
