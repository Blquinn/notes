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

namespace Notes.Widgets {
    public class NoteListItem : Gtk.Box {
        private Models.AppState state;

        private Models.Note _note;
        public Models.Note note { 
            get { return _note; }
            set {
                _note = value;
                title_lbl.label = _note.title;
                note_preview_lbl.label = _note.body_preview;
            } 
        }

        private Gtk.Label title_lbl;
        private Gtk.Label update_time_lbl;
        private Gtk.Label note_preview_lbl;
        private Gtk.PopoverMenu context_menu;

        public NoteListItem(Models.AppState state) {
            Object(orientation: Gtk.Orientation.VERTICAL, spacing: 8);
            this.state = state;
            build_ui();
        }

        private void build_ui() {
            margin_top = 8;
            margin_end = 8;
            margin_bottom = 8;
            margin_start = 8;

            var title_row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            title_lbl = new Gtk.Label(null);
            title_lbl.add_css_class("caption-heading");
            title_lbl.hexpand = true;
            title_lbl.halign = Gtk.Align.START;
            title_lbl.max_width_chars = 18;
            title_lbl.ellipsize = Pango.EllipsizeMode.END;
            title_row.append(title_lbl);

            update_time_lbl = new Gtk.Label("12:22");
            update_time_lbl.add_css_class("dim-label");
            title_row.append(update_time_lbl);

            append(title_row);

            note_preview_lbl = new Gtk.Label("Some preview text of the note. lkadlkjalks ldfkjl asdjklasdklj faklj sdflkjla..a.lkla lksljkdf.");
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
                state.active_note = note;
                context_menu.popup();
            });
            add_controller(click_gesture);
        }
    }

	public class SideBar : Gtk.Box {
        private Models.AppState state;

        public SideBar(Models.AppState state) {
            Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);
            this.state = state;
            build_ui();
        }

        private Gtk.Widget create_note_widget(Object note) {
            var item = new NoteListItem(state);
            item.note = (Models.Note) note;
            return item;
        }

        private void build_ui() {
            const int search_entry_margin = 8;
            append(new Gtk.SearchEntry() {
                margin_top = search_entry_margin,
                margin_end = search_entry_margin,
                margin_bottom = search_entry_margin,
                margin_start = search_entry_margin,
            });

            var notes_list = new Gtk.ListBox();
            notes_list.bind_model(state.notes, create_note_widget);
            notes_list.selected_rows_changed.connect(() => {
                var row = notes_list.get_selected_row();
                var note_item = (NoteListItem) row.child;
                var note = note_item.note;
                state.active_note = note;
            });
            append(notes_list);
        }
    }
}
