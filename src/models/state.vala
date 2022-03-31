/* state.vala
 *
 * Copyright 2022 Benjamin Quinn
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace Notes.Models {
    public const string NOTEBOOK_ALL_NOTES = _("All Notes");
    public const string NOTEBOOK_TRASH = _("Trash");

    public class ActiveNotebookVariant {
        Notebook? notebook;
        string? other; // TODO: Rename this

        private ActiveNotebookVariant(Notebook? notebook, string? other) {
            this.notebook = notebook;
            this.other = other;
        }

        public static ActiveNotebookVariant from_notebook(Notebook nb) {
            return new ActiveNotebookVariant(nb, null);
        }

        public static ActiveNotebookVariant trash() {
            return new ActiveNotebookVariant(null, NOTEBOOK_TRASH);
        }

        public static ActiveNotebookVariant all_notes() {
            return new ActiveNotebookVariant(null, NOTEBOOK_ALL_NOTES);
        }

        public string to_string() {
            return notebook != null ? notebook.name : other;
        }

        public bool is_trash() {
            return other != null && other == NOTEBOOK_TRASH;
        }

        public bool is_all_notes() {
            return other != null && other == NOTEBOOK_ALL_NOTES;
        }
        
        public bool is_notebook() {
            return notebook != null;
        }
    }

    public class WindowState : Object {
        public unowned AppState app_state { get; construct; }
        public unowned Gtk.Window window { get; construct; }

        //  public string active_notebook { get; set; default = NOTEBOOK_ALL_NOTES; }
        // Notebook | string
        public ActiveNotebookVariant active_notebook { get; set; }
        public Note? active_note { get; set; }

        public WindowState(AppState app_state, Gtk.Window window) {
            Object(window: window, app_state: app_state, active_notebook: Models.ActiveNotebookVariant.all_notes());
        }
    }

    public class AppState : Object {
        private unowned Application application;

        // Signal is called when a note moves between notebooks, or changes
        // trash, or pinned states.
        public signal void note_moved();
        public signal void notebook_changed();
        
        public ListStore notes { get; default = new ListStore(typeof(Note)); }
        public ListStore notebooks { get; default = new ListStore(typeof(Notebook)); }

        public AppState(Application app) {
            this.application = app;
            this.notebooks.items_changed.connect(() => notebook_changed());
        }

        private Widgets.Window? get_active_window() {
            var win = this.application.get_active_window();
            return win == null ? null : (Widgets.Window) win;
        }

        private WindowState? get_active_window_state() {
            return get_active_window()?.state;
        }

        public void add_notebook(Notebook notebook) {
            notebooks.insert_sorted(notebook, (a, b) => {
                return ((Notebook) a).name.collate(((Notebook)b).name);
            });
        }

        public void remove_notebook(Notebook notebook) {
            for (int i = 0; i < notes.get_n_items(); i++) {
                var note = (Note) notes.get_item(i);
                var now = new DateTime.now_local();
                if (note.notebook == notebook)
                    note.deleted_at = now;
            }

            uint idx;
            notebooks.find(notebook, out idx);
            if (idx >= 0)
                notebooks.remove(idx);
        }

        public void add_note(Note note) {
            notes.insert_sorted(note, notes_sort);

            var win_state = get_active_window_state();
            if (win_state != null)
                win_state.active_note = note;
        }

        public static int notes_sort(Object a, Object b) {
            var a_note = (Note) a;
            var b_note = (Note) b;
            var comp = (int) b_note.is_pinned - (int) a_note.is_pinned;
            if (comp == 0)
                comp = b_note.updated_at.compare(a_note.updated_at);
            return comp;
        }

        construct {
            var nb = new Notebook(this, "Astronomy");
            add_notebook(nb);
            add_notebook(new Notebook(this, "Personal"));
            add_notebook(new Notebook(this, "Work"));

            notes.append(new Models.Note(this,
                "Hello lk2lkj3kjl 32kjl32rjkl 32rjk l23jrlj kl kjjkl",
                nb,
                null,
                new DateTime.now_local(),
                false,
                new Gtk.TextBuffer(null) {
                    text = "ljkaklk3 jlkk3lj2kjl 23jk aslkkl k1",
                }
            ));
            notes.append(new Models.Note(this,
                "World",
                null,
                null,
                new DateTime(new TimeZone.local(), 2017, 3, 10, 13, 45, 0),
                false,
                new Gtk.TextBuffer(null) {
                    text = "lkj23kjl23 lkkj l234jkl2jkl3 kjl jkl12klj21kljlkj213lkj23kjl 23kl j123lkjljk12ljk ",
                }
            ));
            notes.append(new Models.Note(this,
                "Blah",
                null,
                null,
                new DateTime(new TimeZone.local(), 2022, 3, 10, 13, 45, 0),
                false,
                new Gtk.TextBuffer(null) {
                    text = "Blee bloop",
                }
            ));
            //  notes.append(new Models.Note(this) {
            //      title = "World",
            //      body_buffer = new Gtk.TextBuffer(null) {
            //          text = "lkj23kjl23 lkkj l234jkl2jkl3 kjl jkl12klj21kljlkj213lkj23kjl 23kl j123lkjljk12ljk ",
            //      },
            //      updated_at = new DateTime(new TimeZone.local(), 2017, 5, 20, 13, 45, 0),
            //  });
            //  notes.append(new Models.Note(this) {
            //      title = "Blah",
            //      body_buffer = new Gtk.TextBuffer(null) {
            //          text = "Blee Bloop.",
            //      },
            //      updated_at = new DateTime(new TimeZone.local(), 2022, 3, 10, 13, 45, 0),
            //  });
        }
    }
}
