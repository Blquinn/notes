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

        // Debouncer to eventually persist note to db.
        //  private Util.Debouncer? update_debouncer;
        private Util.Debouncer update_debouncer;
        //      get;
        //      default = new Util.Debouncer(300);
        //  }

        private Notebook? _notebook;
        public Notebook? notebook { 
            get { return _notebook; } 
            set {
                debug("setting nb %s", (update_debouncer == null).to_string());
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
                debug("setting deleted at");
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
                //  debug("setting deleted at");
                _is_pinned = value;
                if (state != null) state.note_moved();
                if (update_debouncer != null) update_debouncer.call();
            }
        }

        private string _title = "";
        public string title { 
            get { return _title; }
            set {
                debug("setting deleted at");
                _title = value;
                if (update_debouncer != null) update_debouncer.call();
            }
        }

        public Gtk.TextBuffer body_buffer { get; set; default = new Gtk.TextBuffer(null); }
        public string body_preview { 
            owned get {
                Gtk.TextIter start;
                Gtk.TextIter end;
                body_buffer.get_start_iter(out start);
                body_buffer.get_iter_at_offset(out end, 75);
                return body_buffer.get_text(start, end, false);
            } 
        }

        public Note(
            AppState state, 
            string title = "",
            Notebook? notebook = null, 
            DateTime? deleted_at = null,
            DateTime updated_at = new DateTime.now_local(),
            bool is_pinned = false,
            Gtk.TextBuffer body_buffer = new Gtk.TextBuffer(null)
        ) {
            Object(
                notebook: notebook,
                deleted_at: deleted_at,
                updated_at: updated_at,
                is_pinned: is_pinned,
                title: title,
                body_buffer: body_buffer
            );
            this.state = state;
            this.update_debouncer = new Util.Debouncer(300); 
            this.update_debouncer.callback.connect(on_debounced_update);
            this.body_buffer.changed.connect(update_debouncer.call);
        }

        private void on_debounced_update() {
            debug("Debounced note update triggered.");

            Idle.add(() => {
                updated_at = new DateTime.now_local();
                state.note_moved();
                // TODO: Update note preview.
                // TODO: Save note in db.
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
