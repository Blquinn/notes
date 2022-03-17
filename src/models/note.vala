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
    public class Notebook : Object {
        public string name { get; set; }
    }

    public class Note : Object {
        public string title { get; set; }
        public Gtk.TextBuffer body_buffer { get; set; }
        public string body_preview { 
            owned get {
                Gtk.TextIter start;
                Gtk.TextIter end;
                body_buffer.get_start_iter(out start);
                body_buffer.get_iter_at_offset(out end, 75);
                return body_buffer.get_text(start, end, false);
            } 
        }
    }
}
