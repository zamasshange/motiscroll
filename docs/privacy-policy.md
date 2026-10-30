# MotiScroll privacy policy

**Effective date:** 30 October 2026

This policy describes how the MotiScroll app handles information. On a phone's home screen the app is named Motis. In the app and on the store listing the name is MotiScroll.

MotiScroll is a reading app for public-domain lines and short speech excerpts. It does not show ads, it does not sell quote text or account information, and it does not include an advertising or tracking SDK.

## Account

The first time the app can reach Firebase, it signs in anonymously. That creates an account on the device with a Firebase user id and no name or email.

You can keep that account, or link Google, Apple, or email. Linking keeps the same account. If you create an email account, the app asks for a name. Google or Apple may also provide the name and email address their sign-in service shares. The app shows that name on your profile.

Signing out starts a new anonymous account on the device. It does not delete the previous account. Use **Delete account** for that.

## Information stored with your account

The account is stored in Google Firebase (Firebase Authentication, Cloud Firestore, and Cloud Functions) for the MotiScroll project.

With the account, the app can store:

- likes, saves, and followed subjects
- the lines you have opened, and the streak count and last active day kept for that account
- onboarding choices, including a usual mood and selected subjects
- time zone, notification times, and whether morning or evening reminders are on
- content language, app language, and an optional second language

That information is used to keep your library, your streak, and your notification settings when you open the app.

A copy of the same reading state also stays on the phone, in the app's private storage. That on-device copy includes theme, text size, notes you write on a line, visit days, and whether widgets are on. It is not a separate account.

## Reports and feedback

If you report a line, the app stores the line id, the reason, the note you write, your user id, and the time. Reports are used to check a wrong attribution, a wrong text, or a line that should not be up.

If you send feedback, the app stores the topic, the message, your user id, and the time.

Reports and feedback are kept so a person can review them. Deleting the account does not automatically erase a report or a feedback message already sent. Ask us if you want one removed.

## On this phone

**Widgets.** Home-screen and lock-screen widgets keep a copy of quote text, the author, the streak, and saved lines in an app group on the phone. That copy has no email address, user id, or sign-in token. Saved lines are not shown on a lock-screen widget unless you turn that setting on. It stays off until you do. The widget does not contact the network.

**Notifications.** Quote notifications are scheduled on this phone. They hold the quote text and the author. They do not hold your user id or email. A title can include your streak count. The upcoming list is stored only on the device. You can turn notifications off in MotiScroll or in the system settings. Permission is never required to use the app. Notification text can appear on the lock screen. Notifications are not ads or purchase prompts. The app may run after a restart so a reminder you already allowed can be scheduled again.

**Share cards.** A share picture is drawn on this phone. It stays on the device until you send it to an app you pick, or save it to Photos. Saving uses add-only access: MotiScroll can put a picture in Photos and does not read your photo library. Instagram and Facebook Story hand-off copies that picture to the system pasteboard, or to a one-time Android hand-off, so those apps can open it. No share event is counted. Temporary card files are deleted after use. WhatsApp, Instagram, Facebook, TikTok, X, and the system share sheet receive only what you choose to send them.

**Portraits.** When an author has a picture, the app downloads it from the address stored with that line, usually Wikimedia Commons. That download uses a MotiScroll user agent. The host of the picture can see the network address of the phone, the way any image load works. Authors with no picture use the MotiScroll mark, which is already in the app.

## Crash reports and app checks

Release builds can send a crash report through Firebase Crashlytics so a broken screen can be fixed. A crash report can include the app version, the device model, the operating system, and a crash trace. The app does not use an advertising id, and Firebase Analytics is not turned on.

Release builds also send an app-integrity check (Google Play Integrity on Android, Apple App Attest on iPhone) so account calls come from MotiScroll. The app fetches feature switches, such as whether the library is ready to read, from Firebase Remote Config. Those switches are not your profile.

## What we do not do

- We do not sell personal information or quote text.
- We do not show ads, and we do not use an advertising or tracking SDK.
- We do not require notification permission, photo access, or an email address to read the library.
- We do not put your email, user id, or sign-in token on a widget.

## How long it is kept

Account information stays until you delete the account. **Delete account** removes the Firebase user and the library stored under that user, including likes, saves, follows, progress, and the profile. It also clears the widget copy and the local notification plan on that phone.

The anonymous account created at first launch is an account. Delete it the same way if you want it removed.

Reports and feedback already submitted are described above.

## Children

MotiScroll is a general reading app. It does not ask for a date of birth, and it is not directed at children under 13. If you believe a child has sent us account information, contact us and we will delete that account.

## Changes

If this policy changes, the new text will replace this page and the effective date at the top will change. The copy in the app points here.

## Contact

Questions, deletion requests, and privacy requests: open an issue at [github.com/zamasshange/motiscroll/issues](https://github.com/zamasshange/motiscroll/issues). You can also use the developer email address shown on the MotiScroll store listing.
