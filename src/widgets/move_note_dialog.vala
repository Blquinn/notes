/* move_note_dialog.vala
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

namespace Notes.Widgets {
    public class MoveNoteDialog : Adw.Window {
        private Models.AppState state;
        private Models.Note note;
        
        public MoveNoteDialog(Models.AppState state, Models.Note note) {
            Object(
                modal: true,
                height_request: 300,
                width_request: 300
            );

            this.state = state;
            this.note = note;
            this.build_ui();
        }

        private void build_ui() {
            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            this.content = box;

            // TODO: Have esc key close modal?

            var headerbar = new Adw.HeaderBar() {
                show_end_title_buttons = false,
            };
            box.append(headerbar);

            headerbar.title_widget = new Gtk.Label(_("Move To"));

            var cancel_btn = new Gtk.Button() {
                label = _("Cancel"),
            };
            cancel_btn.clicked.connect(this.close);
            headerbar.pack_start(cancel_btn);

            var move_btn = new Gtk.Button() {
                label = _("Move"),
                sensitive = false,
            };
            headerbar.pack_end(move_btn);
            // TODO: This is shared with the edit_notebooks_dialog. Extract component?
            var new_notebook_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0) {
                margin_top = 8,
                margin_end = 8,
                margin_bottom = 8,
                margin_start = 8,
                css_classes = {"linked"},
                hexpand = true,
            };
            box.append(new_notebook_box);

            var new_notebook_entry = new Gtk.Entry() {
                placeholder_text = _("New Notebook..."),
                hexpand = true,
            };
            new_notebook_box.append(new_notebook_entry);
            var new_notebook_btn = new Gtk.Button() {
                label = _("Add"),
                sensitive = false,
            };
            new_notebook_btn.clicked.connect(() => {
                if (new_notebook_entry.text == "")
                    return;
                state.add_notebook(new Models.Notebook(state) { name = new_notebook_entry.text });
                new_notebook_entry.text = "";
            });
            new_notebook_entry.bind_property("text", new_notebook_btn, "sensitive", GLib.BindingFlags.DEFAULT, (_, f, ref t) => {
                t.set_boolean(f.get_string() != "");
                return true;
            }, null);
            new_notebook_box.append(new_notebook_btn);

            var notebooks_list = new Gtk.ListBox() {
                hexpand = true,
                selection_mode = Gtk.SelectionMode.SINGLE,
            };
            notebooks_list.selected_rows_changed.connect(() => {
                move_btn.sensitive = true;
            });
            var notebooks_scroll = new Gtk.ScrolledWindow() {
                child = notebooks_list,
                vexpand = true,
            };
            box.append(notebooks_scroll);
            notebooks_list.bind_model(state.notebooks, (nb) => {
                var notebook = (Models.Notebook) nb;
                return new Gtk.Label(notebook.name) {
                    halign = Gtk.Align.START,
                    margin_top = 16,
                    margin_end = 16,
                    margin_bottom = 16,
                    margin_start = 16,
                    ellipsize = Pango.EllipsizeMode.END,
                };
            });

            move_btn.clicked.connect(() => {
                debug("Move notebook button clicked.");
                //  note.notebook
                var row = notebooks_list.get_selected_row();
                var nb = (Models.Notebook) state.notebooks.get_item(row.get_index());
                note.notebook = nb;
                close();
            });
        }
    }
}
