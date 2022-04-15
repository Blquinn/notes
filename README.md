# Notes

Notes is a note taking application for the GNOME desktop environment.

It is built with gtk-4 and libadwaita.

# Building

## Flatpak

1. Build gnome nightly sdk `flatpak install org.gnome.Sdk//master`
1. Build flatpak `flatpak-builder build-flatpak me.blq.notes.json`
1. Install built flatpak `flatpak-builder --user --install --force-clean build-flatpak me.blq.notes.json`
1. Run the flatpak `flatpak run me.blq.notes`
