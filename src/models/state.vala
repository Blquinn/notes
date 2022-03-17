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
    public class AppState : Object {
        public Note? active_note { get; set; }
        public ListStore notes { get; default = new ListStore(typeof(Note)); }

        construct {
            var n1 = new Models.Note();
            n1.title = "Hello lk2lkj3kjl 32kjl32rjkl 32rjk l23jrlj kl kjjkl";
            n1.body_buffer = new Gtk.TextBuffer(null);
            n1.body_buffer.text = "ljkaklk3 jlkk3lj2kjl 23jk aslkkl k1";
            notes.append(n1);

            var n2 = new Models.Note();
            n2.title = "World";
            n2.body_buffer = new Gtk.TextBuffer(null);
            n2.body_buffer.text = "lkj23kjl23 lkkj l234jkl2jkl3 kjl jkl12klj21kljlkj213lkj23kjl 23kl j123lkjljk12ljk ";
            notes.append(n2);

            var n3 = new Models.Note();
            n3.title = "Blah";
            n3.body_buffer = new Gtk.TextBuffer(null);
            n3.body_buffer.text = "Blee bloop.";
            notes.append(n3);
        }
    }
}
