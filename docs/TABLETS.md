# Playing on a tablet

Three ways to get The Good Garden onto a tablet for playtesting. All of them
play the same game as the desktop builds; touch works everywhere (tap to walk
and use, drag pieces, hold a button to hear it).

## Android tablet (or Amazon Fire)

`GoodGarden.apk` installs directly. It needs Android 5.0 or newer and asks
for no permissions.

1. Copy `GoodGarden.apk` to the tablet (email it to yourself, or use a USB
   cable or cloud drive) and tap it.
2. Android asks whether to allow installing apps from that source (Files,
   Chrome, Gmail…). Allow it for this one install. On a Fire tablet:
   **Settings → Security & Privacy → Apps from Unknown Sources**.
3. Tap **Install**, then **Open**. The Good Garden appears on the home
   screen with its sprout icon.

Playtest builds are signed with a playtest key. A newer build signed with the
same key installs over the old one and keeps the child's garden; if Android
refuses to update, uninstall the old one first (this clears the save).

## iPad, in Safari (no Mac needed)

`GoodGarden-Web.zip` is the web version. It needs to be put on a website once;
then the iPad opens a link.

The easiest free host is **itch.io**:

1. Make a free account at itch.io, then **Upload new project**.
2. Kind of project: **HTML**. Upload `GoodGarden-Web.zip` and tick **This file
   will be played in the browser**.
3. Under *Embed options* choose **Click to launch in fullscreen**, and under
   *Visibility* choose **Restricted** with a password, so only your
   playtesters can open it.
4. Save, then open the page's link in Safari on the iPad. Tap **Share → Add to
   Home Screen** for an app-like icon.

The first load downloads about 20 MB. The game saves in Safari's storage for
that site; clearing Safari's website data clears the garden.

## iPad, as a real app (needs a Mac)

`GoodGarden-iPad-Xcode.zip` is a ready Xcode project. Apple only allows
iPad apps to be built on a Mac with Xcode.

1. On a Mac, install **Xcode** from the App Store, and unzip the project.
2. Open `GoodGarden.xcodeproj`. Select the **GoodGarden** target, then
   **Signing & Capabilities**: tick *Automatically manage signing* and choose
   your **Team** (sign in with your Apple ID; the project's placeholder team
   is replaced).
3. Connect the iPad with a cable, choose it as the run destination at the
   top, and press **Run** (▶). The first time, the iPad asks you to trust the
   developer: **Settings → General → VPN & Device Management**.

With a free Apple ID the app runs for 7 days before it must be installed
again from Xcode. A paid Apple Developer account ($99 a year) removes that
limit and allows TestFlight, which sends the app to other families' iPads
without a cable.

## Rebuilding

Presets for all of these live in `export_presets.cfg` (see the README). The
Android release build reads its signing key from the
`GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `_USER` and `_PASSWORD` environment
variables; the key itself is never committed.

The web build turns off Godot's threaded culling
(`threaded_cull_minimum_instances.web` in `project.godot`): the web build has
no worker threads, and in Godot 4.3 a scene with more than 1,000 objects
otherwise draws nothing but the sky.
