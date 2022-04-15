/* note.vala
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
    public class Note : Object {
        private unowned AppState state;

        public int id { get; set; default = -1; }

        // Debouncer to eventually persist note to db.
        private Util.Debouncer update_debouncer;

        private Notebook? _notebook;
        public Notebook? notebook { 
            get { return _notebook; } 
            set {
                debug("Updating notebook.");
                _notebook = value;
                if (state != null) state.note_moved();
                if (update_debouncer != null) update_debouncer.call();
            }
        }

        // Deleted at determines if a note should be in the trash.
        private DateTime? _deleted_at;
        public DateTime? deleted_at { 
            get { return _deleted_at; }
            set {
                debug("Updating deleted_at.");
                _deleted_at = value;
                if (state != null) state.note_moved();
                if (update_debouncer != null) update_debouncer.call();
            }
        }

        public DateTime updated_at { get; set; default = new DateTime.now_local(); }

        private bool _is_pinned = false;
        public bool is_pinned { 
            get { return _is_pinned; }
            set {
                debug("Updating is_pinned.");
                _is_pinned = value;
                if (state != null) state.note_moved();
                if (update_debouncer != null) update_debouncer.call();
            }
        }

        private string _title = "";
        public string title { 
            get { return _title; }
            set {
                debug("Updating title.");
                _title = value;
                if (update_debouncer != null) update_debouncer.call();
            }
        }

        private string _editor_state = "";
        public string editor_state { 
            get { return _editor_state; }
            set {
                debug("Updating editor_state.");
                if (_editor_state == value)
                    return;
                _editor_state = value;
                if (update_debouncer != null) update_debouncer.call();
            }
        }
        public string body_preview { get; set; }

        public Note(
            AppState? state, 
            string title = "",
            Notebook? notebook = null, 
            DateTime? deleted_at = null,
            DateTime updated_at = new DateTime.now_local(),
            bool is_pinned = false,
            string editor_state = """{"document":[{"text":[{"type":"string","attributes":{"blockBreak":true},"string":"\n"}],"attributes":[]}],"selectedRange":[0,0]}""",
            string body_preview = ""
        ) {
            Object(
                notebook: notebook,
                deleted_at: deleted_at,
                updated_at: updated_at,
                is_pinned: is_pinned,
                title: title,
                editor_state: editor_state,
                body_preview: body_preview
            );
            this.state = state;
            this.update_debouncer = new Util.Debouncer(300); 
            this.update_debouncer.callback.connect(on_debounced_update);
        }

        private void on_debounced_update() {
            debug("Debounced note update triggered.");

            Idle.add(() => {
                updated_at = new DateTime.now_local();
                // TODO: Update note preview.
                try {
                    state.note_dao.save(this);
                } catch (Error e) {
                    warning("Failed to save note in db: %s", e.message);
                }

                state.note_moved();
                return Source.REMOVE;
            }, Priority.DEFAULT);
        }

        public string updated_at_formatted() {
            var now = new DateTime.now_local();
            var midnight = new DateTime(now.get_timezone(), now.get_year(), now.get_month(), now.get_day_of_month(), 0, 0, 0);

            if (updated_at.compare(midnight) > 0)
                return updated_at.format("%R");
            
            if (updated_at.get_year() < now.get_year())
                return updated_at.format("%b %Y");

            return updated_at.format("%b %e");
        }
    }
}
