# Moti Scroll

Flutter app of public-domain quotes and short speech excerpts. Four tabs: Collections, Discover, Home, Feed. The visual design is fixed. Phase 2 adds Firebase behind that design.

The app reads `publishedItems` only. There is no local quote catalog. Feed and Discover stay on the preparing screen until Remote Config `contentReady` is true.

```bash
npm run bootstrap -- --env=prod
npm run content:report -- --env=prod
```

`bootstrap` resolves authors from Wikidata, fetches public-domain pages from Wikisource or Project Gutenberg, and approves only the excerpts that pass `approveItem`. Wikiquote and Wikipedia cannot be the approving source. Wikisource, Gutenberg, archive.org, and government archives can. Living people are not published from memory. Fill `content/manual_items.csv` from a real source. See `TODO_for_humans.md`.

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

A normal launch talks to the `motiscroll` project. First launch signs in anonymously. Linking Google, Apple, or an email link keeps the same uid. The Account screen shows a short reason when a provider is turned off or the iOS client is not registered.

```bash
flutter run
flutter run --dart-define=USE_EMULATOR=true
```

`USE_EMULATOR` defaults to false. Emulator ports are Auth 9099, Firestore 8080, Functions 5001, Storage 9199, and UI 4000.

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

Settings includes Account (link, sign out, delete), Rights and sources, Privacy, and Terms. Privacy and Terms are placeholders for a lawyer. Delete account removes the user subtree and the Auth user, and clears the widget copy on the phone. App Check is enforced on callable functions outside the emulator. Turn on enforcement for Firestore and Storage in the console after Play Integrity and App Attest are configured.

## Widgets

Home screen widgets (and iOS lock screen widgets) read a JSON payload the app writes. The extension does not use the network, Firebase, or any secret.

The App Group id is `group.com.example.motiScroll`. On Android the same JSON is in the `HomeWidgetPreferences` file under the key `widget_payload`. The payload holds quote text, author, source, field, a 14-day daily list, mood and field pools, up to 20 saved lines, the streak, and the widget’s own labels in the chosen language. It does not hold an email, a user id, or a token. A separate app preference, `widget_source_v1`, keeps a compact copy of lines that already fit a widget so a daily background refresh can rebuild the payload without opening Firebase.

There is no `publishedLocalized` collection. Widgets use the same published lines the feed already loaded. `isTranslated` stays false until a human-reviewed translation exists. A line that is too long for a size is not cut; that size gets another published line that fits. Placeholders say “Your daily quote appears here” and never use a real person’s name.

Saved quotes are a home screen widget only. Settings has “Show saved quotes on lock screen widgets”, off by default. Turning it on records the choice. The Saved widget is still not a lock screen family.

Sign-out and Delete account clear the payload. If it is missing or older than 14 days, the widget says “Open Moti Scroll to refresh”.

Remote Config `widgetsEnabled` defaults to true. When it is false, the sync writes a payload with no lines and the widgets show the neutral placeholder.

### Add the iOS widget extension in Xcode

`project.pbxproj` is not edited by hand. The Swift sources are in `ios/MotiWidgets/`.

1. Open `ios/Runner.xcworkspace` in Xcode.
2. File → New → Target → Widget Extension. Name it `MotiWidgets`. Uncheck “Include Live Activity”. Set the deployment target to iOS 17.0. If Xcode creates a sample Swift file, delete it from the target.
3. Add these files to the MotiWidgets target only, not Runner: `MotiWidgets.swift`, `PlayfairDisplay-SemiBold.ttf`, `DMSans-Medium.ttf`, and every `*.lproj` folder.
4. In the extension’s Info.plist, add the fonts:

```xml
<key>UIAppFonts</key>
<array>
  <string>PlayfairDisplay-SemiBold.ttf</string>
  <string>DMSans-Medium.ttf</string>
</array>
```

5. Signing & Capabilities on the Runner target and on MotiWidgets: add App Groups and enable `group.com.example.motiScroll` on both. The bundle id of the extension should be `com.example.motiScroll.MotiWidgets`.
6. Confirm the extension’s deployment target is iOS 17.0. App Intents configuration needs it. The Runner app can stay on iOS 15.

Editing `project.pbxproj` by script is possible and easy to get wrong (duplicate ids, a broken Runner target). Xcode is the safe way to add the target.

### Android

The providers are `QuoteWidgetProvider`, `StreakWidgetProvider`, `SavedWidgetProvider`, and `PoolWidgetProvider`, drawn with RemoteViews. Glance was not used: this project’s widget path is `HomeWidgetProvider`, and adding Compose for Glance would be a second UI toolkit in the Android app. The mood/field widget opens `PoolWidgetConfigureActivity`.

### Manual check

On a real iPhone and an Android phone:

- Add Quote of the Day at small, medium, and large, plus the iOS lock screen rectangular and inline forms.
- Add Streak, including the iOS circular lock screen form.
- Add Mood or field, pick a field, and confirm the line changes on the widget’s schedule.
- Add Saved. With nothing saved, it says “Save a quote to see it here”. Save a line, refresh from Settings, and confirm it appears. Confirm Saved is not offered on the lock screen.
- Tap a quote widget. The app opens that line in the feed. Tap Streak. The app opens Home. Tap a widget whose line was removed. The app opens Home.
- Change the app language to Arabic and to Russian. Arabic lays out from the right. Russian uses the bundled serif.
- Turn on airplane mode, leave the app, and confirm the widget still shows the last payload.
- Cross midnight, or set the phone’s date forward one day. Quote of the Day changes. It does not show yesterday’s line as if it were new after the payload is older than 14 days.
- Delete the app’s data, or sign out. The widget says to open Moti Scroll, not a leftover line.
- Settings → Widgets → Refresh widgets now updates the widgets.

`flutter analyze` should be clean. `flutter build ios` and `flutter build apk` build the app. The iOS widget extension is not part of that build until the Xcode target exists.

An iOS 17 “Next quote” button was not added. Save and Like on the widget were not added. Android has no lock screen widget. Live Activities, Dynamic Island, watchOS, and Wear OS are out of scope. Field art on the widget is a gradient from the same colors as the in-app covers, with a dark scrim in dark mode. Pre-rendered cover images were not added.

# motiscroll
