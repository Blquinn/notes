notes_sources = [
  'main.vala',
  'application.vala',

  'models/db.vala',
  'models/notebook.vala',
  'models/note.vala',
  'models/state.vala',

  'util/debounce.vala',

  'widgets/window.vala',
  'widgets/side_bar.vala',
  'widgets/editor.vala',
  'widgets/edit_notebooks_dialog.vala',
  'widgets/move_note_dialog.vala',
  'widgets/note_menu.vala',
]

notes_deps = [
  dependency('gtk4', required: true),
  dependency('sqlite3', required: true),
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
