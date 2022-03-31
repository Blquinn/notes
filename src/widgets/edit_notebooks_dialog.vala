/* edit_notebooks_dialog.vala
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
    public class NotebookEditRow : Gtk.Box {
        private Models.AppState state;
        private Models.Notebook notebook;

        public NotebookEditRow(Models.AppState state, Models.Notebook notebook) {
            Object(
                orientation: Gtk.Orientation.HORIZONTAL, 
                spacing: 8, 
                hexpand: true,
                margin_top: 8,
                margin_end: 8,
                margin_bottom: 8,
                margin_start: 8
            );
            this.state = state;
            this.notebook = notebook;
            build_ui();
        }

        private void build_ui() {
            var edit_name_entry = new Gtk.Entry() {
                hexpand = true,
            };
            edit_name_entry.buffer.set_text((uint8[]) notebook.name);
            edit_name_entry.activate.connect(() => {
                debug("Notebook name entry editing done.");
                if (edit_name_entry.text == "")
                    return;
                
                notebook.name = edit_name_entry.text;
            });
            append(edit_name_entry);

            var delete_notebook_btn = new Gtk.Button() {
                css_classes = {"flat"},
                icon_name = "edit-delete-symbolic",
                //  margin_start = 8,
            };
            delete_notebook_btn.clicked.connect(() => {
                debug("Deleting notebook %s", notebook.name);
                state.remove_notebook(notebook);
            });
            append(delete_notebook_btn);
        }
    }

    public class EditNotebooksDialog : Adw.Window {
        private Models.AppState state;

        public EditNotebooksDialog(Models.AppState state) {
            Object(modal: true, height_request: 300, width_request: 300);
            this.state = state;
            build_ui();
        }

        private void build_ui() {
            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            this.content = box;

            var header = new Adw.HeaderBar();
            box.append(header);
            header.title_widget = new Gtk.Label(_("Edit Notebooks"));

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
            new_notebook_entry.bind_property("text", new_notebook_btn, "sensitive", GLib.BindingFlags.DEFAULT, (_, f, ref t) => {
                t.set_boolean(f.get_string() != "");
                return true;
            }, null);
            new_notebook_btn.clicked.connect(() => {
                if (new_notebook_entry.text == "")
                    return;

                state.add_notebook(new Models.Notebook(state, new_notebook_entry.text));
                new_notebook_entry.text = "";
            });
            new_notebook_box.append(new_notebook_btn);

            var notebooks_list = new Gtk.ListBox() {
                hexpand = true,
                selection_mode = Gtk.SelectionMode.NONE,
            };
            var notebooks_scroll = new Gtk.ScrolledWindow() {
                child = notebooks_list,
                vexpand = true,
            };
            box.append(notebooks_scroll);
            notebooks_list.bind_model(state.notebooks, (nb) => new NotebookEditRow(state, (Models.Notebook) nb));
        }
    }
}
