/* editor.vala
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
    public class Editor : Gtk.Box {

        private Models.WindowState win_state;
        private Models.AppState app_state;
        private Gtk.Stack stack;

        private Gtk.Box editor_box;
        private Gtk.Label placeholder;
        private Gtk.Entry title_entry;
        private Gtk.Label notebook_name_lbl;
        private Gtk.Label last_updated_lbl;
        private Gtk.TextView note_text;

        private Binding? title_binding;
        private Binding? last_updated_binding;
        private Binding? notebook_name_binding;

        const string last_updated_prefix = _("Last updated");

        public Editor(Models.AppState state, Models.WindowState win_state) {
            Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);
            this.app_state = state;
            this.win_state = win_state;
            build_ui();
        }

        private void on_move_notebook_btn_clicked() {
            debug("Move notebook button clicked.");

            if (win_state.active_note == null) {
                debug("Active note is null, not opening move diag.");
                return;
            }

            new MoveNoteDialog(app_state, win_state.active_note) {
                transient_for = (Gtk.Window) this.root,
            }.present();
        }

        private void on_active_note_changed() {
            // Unbind existing bindings.

            if (title_binding != null)
                title_binding.unbind();

            if (last_updated_binding != null)
                last_updated_binding.unbind();

            if (notebook_name_binding != null)
                notebook_name_binding.unbind();

            var note = win_state.active_note;
            if (note == null) {
                stack.set_visible_child(placeholder);
                return;
            }

            stack.set_visible_child(editor_box);

            // Set the rest of the properties.

            title_binding = note.bind_property("title", title_entry, "text", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL, null, null);

            // Hack to reset undo/redo stacks. Otherwise pressing undo after changing notes
            // would undo changes from the last note :/
            // Undo/Redo stacks should be stored on the buffer like they are for TextView...
            title_entry.enable_undo = false;
            title_entry.enable_undo = true;

            notebook_name_binding = note.bind_property("notebook", notebook_name_lbl, "label", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE, 
                (_, f, ref t) => { 
                    var notebook = (Models.Notebook?) f;
                    var name = notebook == null ? Models.NOTEBOOK_ALL_NOTES : notebook.name;
                    t.set_string(name);
                    return true; 
                }, null);
                
            last_updated_binding = note.bind_property("updated-at", last_updated_lbl, "label", GLib.BindingFlags.SYNC_CREATE, 
                (_, f, ref t) => { 
                    var update_time = note.updated_at_formatted();
                    t.set_string(@"$last_updated_prefix $update_time");
                    return true; 
                }, null);

            note_text.buffer = note.body_buffer;
        }
        
        private void build_ui() {
            add_css_class("view");

            // Empty page.
            stack = new Gtk.Stack();
            append(stack);

            editor_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            stack.add_child(editor_box);

            placeholder = new Gtk.Label(null);
            stack.add_child(placeholder);

            stack.set_visible_child(placeholder);

            win_state.notify["active-note"].connect(on_active_note_changed);
            
            title_entry = new Gtk.Entry() {
                css_classes = {"flat", "title-1"},
                halign = Gtk.Align.FILL,
                placeholder_text = _("Note Title..."),
            };
            
            var contents_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 8);
            editor_box.append(new Adw.Clamp() {
                margin_top = 8,
                margin_end = 8,
                margin_bottom = 8,
                margin_start = 8,
                maximum_size = 800,
                child = contents_box,
            });
            contents_box.append(title_entry);
            contents_box.append(new Gtk.Separator(Gtk.Orientation.HORIZONTAL));
            
            var note_details_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 8);
            // TODO: Source this from somewhere.
            last_updated_lbl = new Gtk.Label(null);
            note_details_box.append(last_updated_lbl);
            
            var change_nb_btn = new Gtk.Button();
            change_nb_btn.add_css_class("flat");
            change_nb_btn.clicked.connect(on_move_notebook_btn_clicked);
            
            var change_nb_btn_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 8);
            var nb_icon = new Gtk.Image() {
                icon_name = "accessories-text-editor-symbolic",
            };
            change_nb_btn_box.append(nb_icon);
            notebook_name_lbl = new Gtk.Label(null);
            change_nb_btn_box.append(notebook_name_lbl);
            change_nb_btn.child = change_nb_btn_box;
            note_details_box.append(change_nb_btn);
            
            contents_box.append(note_details_box);
            
            note_text = new Gtk.TextView() {
                wrap_mode = Gtk.WrapMode.WORD_CHAR,
                vexpand = true,
            };
            //  var buf = edit.buffer;
            //  buf.create_tag("b", 
            //      "weight", Pango.Weight.BOLD);
            //  buf.create_tag("i", 
            //      "style", Pango.Style.ITALIC);
            //  buf.create_tag("ul", 
            //      "left-margin", 8);
            //  buf.create_tag("li", 
            //      "left-margin", 8);
            
            //  edit.buffer.text = "Some text ";
            
            //  Gtk.TextIter iter;
            //  edit.buffer.get_end_iter(out iter);
            //  edit.buffer.insert_markup(ref iter, "<i>Italic text. </i>", -1);
            //  edit.buffer.insert_markup(ref iter, "<b>Bold text. </b>\n", -1);
            //  edit.buffer.insert_with_tags_by_name(ref iter, "1. Unordered list.", -1, "ul", "li"); 
            
            contents_box.append(new Gtk.ScrolledWindow() {
                child = note_text,
            });
        }
    }
}