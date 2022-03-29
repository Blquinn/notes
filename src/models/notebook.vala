/* notebook.vala
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
        private unowned AppState state;
        private Util.Debouncer update_debouncer;

        private string _name;
        public string name { 
            get { return _name; }
            set {
                _name = value;
                update_debouncer.call();
                state.notebook_changed();
            } 
        }

        public Notebook(AppState state) {
            this.update_debouncer = new Util.Debouncer(300);
            this.update_debouncer.callback.connect(on_debounced_update);
            this.state = state;
        }

        private void on_debounced_update() {
            debug("Updating notebook.");
            // TODO: Save changes to notebook.
        }
    }
}
