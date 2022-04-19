# Notes

Notes is a note taking application for the GNOME desktop environment.

It is built with gtk-4 and libadwaita.

![Notes application.](screenshots/notes-screenshot.png?raw=true "Notes application.")

## Status

This software is pre-alpha. It is not feature complete, nor stable in any sense.

Please only use it if you're curious to play around with it.

Please do play around with it and file issues for any bugs found,
any help is appreciated :)

## Features

*Application*

- [x] Notebook based categorization
- [x] Trash can
- [x] Local persistence
- [x] Auto-save
- [x] Dark theme support
- [ ] Cloud sync
- [ ] Sync with 3rd party applications
- [ ] Full text search (serching note contents)

*Editor*

- [x] Bold, Italics, Strikethrough, Underline text
- [x] Ordered Lists & Bulleted Lists
- [x] Code Blocks
- [x] Block Quotes
- [x] Arbitrary nesting of block formatting
- [x] Pasting images support
- [ ] Drawing support
- [ ] Hyperlinks (They should be editable and open in the browser)

## Issues

The webview used for the editor is pre-release and it seems to freeze up
with some regularity.

You can see the progress of this package [here](https://bugs.webkit.org/show_bug.cgi?id=210100).

# Building

## GNOME Builder

Simply opening the project in gnome builder should automatically
handle building and running the project.

## Flatpak

1. Add flatpak repo: 
`flatpak remote-add --if-not-exists gnome-nightly https://nightly.gnome.org/gnome-nightly.flatpakrepo`
2. Build gnome nightly sdk:
`flatpak install org.gnome.Sdk//master`
3. Build flatpak: 
`flatpak-builder build-flatpak me.blq.notes.json`
4. Install built flatpak: 
`flatpak-builder --user --install --force-clean build-flatpak me.blq.notes.json`
5. Run the flatpak: 
`flatpak run me.blq.notes`

## Meson

You can do a non-flatpak build of this project, however you need
to have 'webkit2gtk-5.0' installed, which is prerelease and
isn't available on any platforms (other than arch) at the moment.

### Dependencies

1. gtk4
1. libadwaita-1
1. sqlite3
1. webkit2gtk-5.0

#### Webkit2gtk-5.0

The trick I used to figure out how to build this version of webkit was to
follow the [build file for arch](https://github.com/archlinux/svntogit-packages/blob/packages/webkit2gtk-5.0/trunk/PKGBUILD).

Note that this is a painful process if your distro doesn't have this package available.

