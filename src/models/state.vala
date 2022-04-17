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

        public ActiveNotebookVariant active_notebook { get; set; }
        public Note? active_note { get; private set; }

        public WindowState(AppState app_state, Gtk.Window window) {
            Object(window: window, app_state: app_state, active_notebook: Models.ActiveNotebookVariant.all_notes());
        }

        public signal void active_note_change_request(SourceFunc callback);

        // The editor will connect to this signal and call the callback when the contents
        // of the editor are retrieved from the webview.
        public void update_active_note(Note note) {
            active_note = note;
        }
    }

    public enum ColorScheme {
        LIGHT,
        DARK
    }

    public class AppState : Object {
        private unowned Application application;
        public NoteDao note_dao { get; set; }
        public NotebookDao notebook_dao { get; set; }

        // Signal is called when a note moves between notebooks, or changes
        // trash, or pinned states.
        public signal void note_moved();
        public signal void notebook_changed();
        
        public ListStore notes { get; default = new ListStore(typeof(Note)); }
        public ListStore notebooks { get; default = new ListStore(typeof(Notebook)); }

        public ColorScheme color_scheme { get; set; default = ColorScheme.LIGHT; }

        public AppState(Application app) {
            this.application = app;
            this.notebooks.items_changed.connect(() => notebook_changed());

            bind_color_scheme();

			try {
				var db = new Db();
				notebook_dao = new NotebookDao(this, db);
                var notebooks = notebook_dao.find_all();
                foreach (var nb in notebooks)
                    this.notebooks.append(nb);

				note_dao = new NoteDao(this, db);
				var notes = note_dao.find_all(notebooks);

                foreach (var n in notes)
                    this.notes.append(n);

				debug("Got notes of len %d and notebooks of len %d", notes.length, notebooks.length);
			} catch (Error e) {
				error("Failed to initialize database: %s", e.message);
			}
        }

        private Widgets.Window? get_active_window() {
            var win = this.application.get_active_window();
            return win == null ? null : (Widgets.Window) win;
        }

        private WindowState? get_active_window_state() {
            return get_active_window()?.state;
        }

        public void add_notebook(Notebook notebook) {
            try {
                notebook_dao.save(notebook);
            } catch (Error e) {
                error(e.message);
            }
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
            try {
                note_dao.save(note);
            } catch (Error e) {
                error("Failed to insert note: %s", e.message);
            }

            notes.insert_sorted(note, notes_sort);

            var win_state = get_active_window_state();
            if (win_state != null)
                win_state.update_active_note(note);
        }

        public static int notes_sort(Object a, Object b) {
            var a_note = (Note) a;
            var b_note = (Note) b;
            var comp = (int) b_note.is_pinned - (int) a_note.is_pinned;
            if (comp == 0)
                comp = b_note.updated_at.compare(a_note.updated_at);
            return comp;
        }

		private void bind_color_scheme() {
			var gnome_settings = new Settings("org.gnome.desktop.interface");
			var gtk_theme = gnome_settings.get_string("gtk-theme");
			color_scheme = map_color_scheme(gtk_theme);
			gnome_settings.bind_with_mapping("gtk-theme", this, "color-scheme", SettingsBindFlags.DEFAULT, 
				(value, variant, _) => {
					var scheme = map_color_scheme(variant.get_string());
					value.set_enum(scheme);
					return true;
				}, 
				(a, b, c) => { return true; }, 
				null, null);
		}

		private static ColorScheme map_color_scheme(string theme_name) {
			var gtk_settings = Gtk.Settings.get_default();
			var is_dark = (gtk_settings != null && gtk_settings.gtk_application_prefer_dark_theme == true)
				? true
				: theme_name.down().contains("dark");
			return is_dark ? ColorScheme.DARK : ColorScheme.LIGHT;
		}
    }
}
