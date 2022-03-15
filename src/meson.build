notes_sources = [
  'main.vala',
  'application.vala',
  'models/note.vala',
  'widgets/window.vala',
  'widgets/side_bar.vala',
  'widgets/editor.vala',
]

notes_deps = [
  dependency('gtk4', required: true),
  dependency('libadwaita-1', required: true),
]

gnome = import('gnome')

notes_sources += gnome.compile_resources('notes-resources',
  'notes.gresource.xml',
  c_name: 'notes'
)

executable('notes', notes_sources,
  vala_args: '--target-glib=2.50',  dependencies: notes_deps,
  install: true,
)
