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

    public class AppState : Object {
        // Signal is called when a note moves between notebooks, or changes
        // trash, or pinned states.
        public signal void note_moved();
        
        public Note? active_note { get; set; }
        public ListStore notes { get; default = new ListStore(typeof(Note)); }
        public ListStore notebooks { get; default = new ListStore(typeof(Notebook)); }

        public string active_notebook { get; set; default = NOTEBOOK_ALL_NOTES; }

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
            active_note = note;
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
            var nb = new Notebook() { name = "Astronomy" };
            add_notebook(nb);
            add_notebook(new Notebook() { name = "Personal" });
            add_notebook(new Notebook() { name = "Work" });

            notes.append(new Models.Note(this) {
                title = "Hello lk2lkj3kjl 32kjl32rjkl 32rjk l23jrlj kl kjjkl",
                body_buffer = new Gtk.TextBuffer(null) {
                    text = "ljkaklk3 jlkk3lj2kjl 23jk aslkkl k1",
                },
                notebook = nb,
            });
            notes.append(new Models.Note(this) {
                title = "World",
                body_buffer = new Gtk.TextBuffer(null) {
                    text = "lkj23kjl23 lkkj l234jkl2jkl3 kjl jkl12klj21kljlkj213lkj23kjl 23kl j123lkjljk12ljk ",
                },
            });
            notes.append(new Models.Note(this) {
                title = "Blah",
                body_buffer = new Gtk.TextBuffer(null) {
                    text = "Blee Bloop.",
                },
            });
        }
    }
}
