# Ibong Adarna Dictionary

An offline-first Flutter dictionary. The bundled `assets/dictionary.db` is copied
into the app documents directory on first launch; all subsequent reads and
changes use the writable local SQLite copy. When a newer bundled dictionary is
installed, newly added terms are merged into that copy without overwriting
existing word saves or activity history.

## Data and database

`DatabaseHelper.instance` is the single database access point. It opens the
copied database once, creates missing tables, and applies additive upgrades to
the bundled `activities` table without replacing existing user data.

| Table | Purpose |
| --- | --- |
| `words` | Dictionary terms, definitions, image asset paths, and saved state. |
| `activities` | Activity name/type, score, maximum score, date, and notes. |
| `reward_definitions` | Reward criteria for streaks, activity count, and points. |
| `user_rewards` | Persistent unlock records. |
| `app_settings` | Local settings, including automatic word-of-day speech. |
| `quiz_drafts` | Saved quiz questions and setup metadata for resuming later. |

`DatabaseHelper` provides dictionary search, word-of-day selection, save
updates, activity insert/update/delete, reward evaluation, and growth
aggregates. The Growth screen uses `fl_chart` and asynchronously combines
completed quiz activities with persisted Pilak transaction, login, and reading
histories. It shows quiz performance, chapter mastery, accuracy, quiz Pilak
decay, vocabulary searches, streak comparisons, and a 30-day balance timeline.
Quiz and marketplace history is recorded from the new tracking rollout onward.
Dictionary searches are stored as unique terms per local day. Active reading
minutes are shown only when `rewardActiveReading` is called; the app does not
currently have a reading timer. The time-distribution chart is explicitly an
event-based estimate because elapsed time is not measured for all app areas.

To update the bundled dictionary, replace `assets/dictionary.db` with a
compatible SQLite database containing the `words` table. Keep image paths
relative to the project root and include the corresponding files under
`assets/images/`. The bundled database is a first-install template; replacing
it does not overwrite an already-installed app's local database.

## App flows

- Home shows a deterministic daily word and can speak its pronunciation on
  Android through the native Android text-to-speech engine. Speech controls are
  no-ops on desktop platforms, so Windows builds do not require NuGet for TTS.
- Search starts with all dictionary entries, filters terms and definitions, and
  updates results while typing. In Adarna Mode, searches are submitted
  explicitly and cost one heart; search is disabled when no hearts remain.
  Search results and detail pages can toggle saved state; the Saves tab reads
  that same state from SQLite.
- Activities supports create, edit, delete, filtering, and sorting. Activity
  dates and scores feed rewards and the Growth screen.
- New quizzes support Freestyle term/definition pairs, a searchable
  dictionary-word picker with an exact word count, or a requested number of
  random unique dictionary words. Multiple Choice uses dictionary terms as
  answer options, Identification checks typed answers, and Flashcards reveal
  definitions. Each completed quiz is saved as a scored activity. Quiz setup
  can start immediately or save a persistent quiz draft in Activities; drafts
  can be resumed later and are removed after the quiz is completed.
- Rewards unlock once a streak, activity-count, or total-score threshold is
  reached. The Rewards screen also contains the Pilak marketplace.
- Pilak balance, purchased product IDs, active theme, login streak, streak-freeze
  expiry, and quiz-reset credits are serialized as one JSON value in
  `SharedPreferences`. Quiz and daily-login rewards are credited through
  `PilakService`; reading reward calculation is exposed by
  `rewardActiveReading(minutes)`. Quiz attempts are counted by activity type in
  the preceding rolling 24-hour window, including the attempt being completed.
  Purchases are serialized and checked against the current balance before they
  are persisted.
- Tapping the center bird in the app bar opens Adarna Mode. Its enabled state
  and up-to-three hearts persist with the Pilak account. Submitting a non-empty
  dictionary or chapter word search, or opening a word from either result list,
  spends one heart; quiz Pilak is doubled while the mode is enabled. A quiz’s
  first recorded attempt scoring at least 75% restores one heart, up to the
  three-heart limit. Spent hearts remain visible as filled gray icons.
- The marketplace lists 30 products in theme, feature, and material categories.
  Purchased themes rebuild the app's `ThemeData`; Advanced SQL Filters and
  Custom Quiz Architect are gated by their purchased IDs. Marketplace material
  export copies a bundled asset into the app documents directory. The PDF/ZIP
  files listed in the catalog are not currently present under
  `assets/marketplace/`, so those export buttons report that the files need to
  be added rather than creating placeholder downloads. Native Android widgets,
  scheduled themes, and other platform-heavy unlocks still require their
  platform implementations.
- Settings stores the automatic word-of-day speech preference locally.
  The toolbar share action opens the platform share sheet.
- Successful actions show snackbars for Adarna Mode and heart changes, quiz
  results and setup, saved-word changes, Pilak rewards and purchases, badge
  unlocks, settings changes, and successful word sharing. Search and Kabanata
  show an Adarna heart-cost warning when the mode is active. Rewards tab labels
  use high-contrast white text against the dark app bar.

On Windows, macOS, and Linux, the app initializes `sqflite_common_ffi` before
opening SQLite. Android and iOS use `sqflite`.

## Android app icon and APK

The Android launcher icon is generated from `assets/images/logo1_icon.png`,
which is rendered from `assets/images/logo1.svg` and placed on the Parchment
White adaptive-icon background. If the SVG changes, update the raster icon and
run `dart run flutter_launcher_icons` to regenerate the Android resources.

Build an installable debug APK with:

```shell
flutter build apk --debug
```

The APK is written to `build/app/outputs/flutter-apk/app-debug.apk`. Copy it to
an Android phone and open the file to install it; you may need to allow installs
from that file manager. This debug APK is for testing, not Play Store release.
For a smaller download, build per architecture with
`flutter build apk --debug --split-per-abi`; most modern phones use
`build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk`.

## Validation

Run `flutter pub get`, `flutter analyze`, and `flutter test` from the project
root.
