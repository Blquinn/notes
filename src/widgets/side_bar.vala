/* side_bar.vala
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


// TODO: Fix issue where context menu selects next row for some reason.

namespace Notes.Widgets {
    public class NoteListItem : Gtk.Box {
        const string default_title = _("New Note");

        private Models.WindowState win_state;
        public Models.Note note { get; private set; }
        private Gtk.Label title_lbl;
        private Gtk.Label update_time_lbl;
        private Gtk.Label note_preview_lbl;
        private Gtk.PopoverMenu context_menu;

        public NoteListItem(Models.WindowState win_state, Models.Note note) {
            Object(orientation: Gtk.Orientation.VERTICAL, spacing: 8);
            this.win_state = win_state;
            this.note = note;
            build_ui();
        }

        private void build_ui() {
            margin_top = 8;
            margin_end = 8;
            margin_bottom = 8;
            margin_start = 8;

            var title_row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            title_lbl = new Gtk.Label(null);
            note.bind_property("title", title_lbl, "label", GLib.BindingFlags.SYNC_CREATE, (_, f, ref t) => {
                var title = f.get_string();
                if (title == "")
                    title = default_title;
                t.set_string(title);
                return true;
            }, null);
            title_lbl.add_css_class("caption-heading");
            title_lbl.hexpand = true;
            title_lbl.halign = Gtk.Align.START;
            title_lbl.max_width_chars = 18;
            title_lbl.ellipsize = Pango.EllipsizeMode.END;
            title_row.append(title_lbl);

            // TODO: Use /org/gnome/desktop/interface/clock-format to set 24/12 hr time.
            update_time_lbl = new Gtk.Label(null);
            note.bind_property("updated-at", update_time_lbl, "label", BindingFlags.SYNC_CREATE, (_, f, ref t) => {
                t.set_string(note.updated_at_formatted());
                return true;
            }, null);

            update_time_lbl.add_css_class("dim-label");
            title_row.append(update_time_lbl);

            append(title_row);

            note_preview_lbl = new Gtk.Label(note.body_preview);
            note.bind_property("body-preview", note_preview_lbl, "label", BindingFlags.SYNC_CREATE);
            note_preview_lbl.add_css_class("caption");
            note_preview_lbl.max_width_chars = 25;
            note_preview_lbl.halign = Gtk.Align.START;
            note_preview_lbl.ellipsize = Pango.EllipsizeMode.END;
            note_preview_lbl.lines = 2;
            note_preview_lbl.wrap = true;
            note_preview_lbl.wrap_mode = Pango.WrapMode.WORD_CHAR;
            append(note_preview_lbl);

            // Context Menu
            context_menu = new Gtk.PopoverMenu.from_model(Widgets.create_note_actions_menu());
            context_menu.set_parent(this);

            var click_gesture = new Gtk.GestureClick();
            click_gesture.button = Gdk.BUTTON_SECONDARY;
            click_gesture.pressed.connect((n_press, x, y) => {
                debug("Popping up note context menu.");
                Gtk.Allocation alloc;
                this.get_allocation(out alloc);
                context_menu.pointing_to = alloc;
                win_state.update_active_note(note);
                context_menu.popup();
            });
            add_controller(click_gesture);
        }
    }

    public class NoteListHeader : Gtk.Box {
        public NoteListHeader(string text) {
            Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);
            margin_top = 10;
            var lbl = new Gtk.Label(text) {
                css_classes = {"heading"},
                halign = Gtk.Align.START,
                margin_start = 10,
                margin_bottom = 4,
            };
            append(lbl);
            append(new Gtk.Separator(Gtk.Orientation.HORIZONTAL));
        }
    }

	public class SideBar : Gtk.Box {
        private Models.AppState app_state;
        private Models.WindowState win_state;
        private Gtk.SearchEntry filter_entry;
        private Gtk.ListBox notes_list;

        public SideBar(Models.AppState app_state, Models.WindowState win_state) {
            Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);
            this.app_state = app_state;
            this.win_state = win_state;
            win_state.notify["active-note"].connect(on_active_note_changed);
            build_ui();
        }

        private Gtk.Widget create_note_widget(Object note) {
            return new NoteListItem(win_state, (Models.Note) note);
        }

        // Sorts the current view of the notes. Sorts on pinned, then last_updated.
        private int notes_sort_func(Gtk.ListBoxRow a_row, Gtk.ListBoxRow b_row) {
            var a_note = ((NoteListItem) a_row.child).note;
            var b_note = ((NoteListItem) b_row.child).note;
            return Models.AppState.notes_sort(a_note, b_note);
        }

        private bool notes_filter_func(Gtk.ListBoxRow row) {
            var note = ((NoteListItem) row.child).note;

            var filter = filter_entry.text;
            if (filter.length > 0 && !note.title.down().contains(filter.down()))
                return false;

            var anb = win_state.active_notebook;
            if (anb.is_trash())
                return note.deleted_at != null;

            if (note.deleted_at != null)
                return false;            
            
            if (anb.is_all_notes())
                return true;

            // TODO: Switch to using notebooks primary keys.
            string? notebook_name = note.notebook != null ? note.notebook.name : null;
            var anb_obj = (Models.ActiveNotebookVariant) anb;
            return notebook_name == anb_obj.to_string();
        }

        private void note_header_func(Gtk.ListBoxRow row, Gtk.ListBoxRow? before) {
            var note = ((NoteListItem) row.child).note;

            // No headers for trash.
            if (note.deleted_at != null)
                return;

            if (before == null) {
                if (note.is_pinned)
                    row.set_header(new NoteListHeader(_("Pinned")));
                else
                    row.set_header(new NoteListHeader(_("Other Notes")));
                return;
            }

            var before_note = ((NoteListItem) before.child).note;
            if (before_note.is_pinned && !note.is_pinned) {
                row.set_header(new NoteListHeader(_("Other Notes")));
                return;
            }

            row.set_header(null);
        }

        private void on_active_note_changed() {
            var an = win_state.active_note;
            if (an == null)
                return;

            int i = 0;
            while (true) {
                var row = notes_list.get_row_at_index(i);
                if (row == null)
                    break;
                var note = ((NoteListItem) row.child).note;
                if (an == note) {
                    notes_list.select_row(row);
                    break;
                }
                i++;
            }
        }

        private void build_ui() {
            const int search_entry_margin = 8;
            filter_entry = new Gtk.SearchEntry() {
                margin_top = search_entry_margin,
                margin_end = search_entry_margin,
                margin_bottom = search_entry_margin,
                margin_start = search_entry_margin,
            };
            append(filter_entry);

            notes_list = new Gtk.ListBox() {
                css_classes = {"notes-list"},
            };

            notes_list.bind_model(app_state.notes, create_note_widget);
            notes_list.set_sort_func(notes_sort_func);
            notes_list.set_filter_func(notes_filter_func);
            notes_list.set_header_func(note_header_func);

            filter_entry.notify["text"].connect(notes_list.invalidate_filter);
            win_state.notify["active-notebook"].connect(notes_list.invalidate_filter);
            app_state.note_moved.connect(() => {
                notes_list.invalidate_filter();
                notes_list.invalidate_sort();
                notes_list.invalidate_headers();
            });

            notes_list.selected_rows_changed.connect(() => {
                var row = notes_list.get_selected_row();
                var note_item = (NoteListItem) row.child;
                var note = note_item.note;
                win_state.update_active_note(note);
            });
            append(notes_list);
        }
    }
}
