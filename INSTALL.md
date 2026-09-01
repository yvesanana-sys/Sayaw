# Installing Sayaw

Sayaw runs on Windows, macOS and Linux from one codebase. Windows is the only
platform with a packaged installer today; the others build from source in a
few minutes.

---

## Windows

### From the installer

1. Go to [Releases](https://github.com/yvesanana-sys/Sayaw/releases) and
   download `Sayaw-<version>-windows-x64-setup.exe` from the newest release.
2. Run it. **Windows will warn you** — see below.
3. Sayaw appears in the Start menu, and on the desktop if you asked for a
   shortcut.

Requires 64-bit Windows 10 or later. Nothing else needs installing: the audio
engine and the database library are inside the installer.

> **If there are no releases listed**, none has been cut yet. Anyone with push
> access can make one — see [Cutting a release](#cutting-a-release) — or build
> from source below.

### The SmartScreen warning

The installer is **not code-signed yet**, so on first run Windows shows
*"Windows protected your PC"*. To continue: click **More info**, then
**Run anyway**.

This is Windows saying it does not recognise the publisher, not that it found
anything wrong. It goes away once the project has a code-signing certificate,
which costs money and has not been bought.

### Uninstalling

Settings → Apps → Installed apps → Sayaw → Uninstall. Or use the Uninstall
shortcut in the Start menu folder.

Your library and playlists are **not** removed with the app. They live in:

```
%APPDATA%\Sayaw\Sayaw\
```

(Windows takes that name from the publisher and product recorded in the
executable, which is why it appears twice.)

Delete that folder to start completely fresh. Your music files are never
touched — Sayaw only ever reads them.

---

## Linux

There is no packaged build yet, so this is from source. It takes about five
minutes on a fresh machine.

### 1. Build dependencies

On Ubuntu or Debian:

```bash
sudo apt-get update
sudo apt-get install -y \
  clang cmake ninja-build pkg-config \
  libgtk-3-dev liblzma-dev libstdc++-12-dev \
  libmpv-dev mpv
```

`libmpv` is the audio engine and is a **runtime** dependency on Linux — unlike
Windows, where it ships inside the installer. It has to stay installed.

On Fedora the equivalent is `clang cmake ninja-build pkgconf-pkg-config
gtk3-devel xz-devel mpv-libs-devel`.

### 2. Flutter

Install the Flutter SDK if you do not have it —
[flutter.dev/docs/get-started/install/linux](https://docs.flutter.dev/get-started/install/linux)
— then enable the desktop target:

```bash
flutter config --enable-linux-desktop
flutter doctor
```

`flutter doctor` should report no issues for "Linux toolchain".

### 3. Build and run

```bash
git clone https://github.com/yvesanana-sys/Sayaw.git
cd Sayaw
flutter pub get
flutter run -d linux
```

For a build you can keep and run without Flutter:

```bash
flutter build linux --release
./build/linux/x64/release/bundle/sayaw
```

The `bundle` directory is self-contained apart from `libmpv` and GTK. Copy it
wherever you like.

Your library and playlists live in:

```
~/.local/share/io.github.yvesanana.sayaw/
```

---

## macOS

No packaged build yet. From source:

```bash
git clone https://github.com/yvesanana-sys/Sayaw.git
cd Sayaw
flutter pub get
flutter run -d macos
```

Data lives in `~/Library/Application Support/io.github.yvesanana.sayaw/`.

---

## First run

Sayaw starts empty. To get playing:

1. **Library** pane → **Add music folder**, and pick a folder of music.
   Sayaw reads the tags and imports what it finds; it never moves, renames or
   writes to your files.
2. Press **+** beside a track to add it to the set.
3. Press **play** in the transport bar.

Supported formats are whatever `libmpv` handles, which is essentially
everything: mp3, m4a, flac, wav, aiff, ogg, opus.

---

## Troubleshooting

**No sound, but the position counter is moving.** The audio is being decoded
and sent to the OS, so the problem is the output device. Check the system
volume and that the right output is selected. On Linux, confirm `mpv` itself
can play the same file: `mpv --no-video yourfile.mp3`.

**No sound, and the position stays at 0:00.** The file could not be opened.
Check the track is not greyed out in the queue — an unplayable row is labelled
with the reason.

**Linux: "error while loading shared libraries: libmpv.so".** `libmpv` is
missing. Install it — see step 1.

**Windows: the installer will not run.** See
[the SmartScreen warning](#the-smartscreen-warning).

**A track is greyed out.** The queue says why on the row: the file has moved,
a folder permission expired, or the source needs a connection that is not
there.

**Everything is wrong and you want to start over.** Delete the data folder
listed for your platform above. Your music is not in it.

---

## Cutting a release

Releases are built by CI when a tag is pushed:

```bash
git tag v0.1.0
git push origin v0.1.0
```

That runs the tests, builds, and attaches the Windows installer to a **draft**
release for you to check before publishing.

To exercise the build without creating a release, run the *Windows release*
workflow manually from the Actions tab, or:

```bash
gh workflow run release-windows.yml --ref main
gh run watch
```
