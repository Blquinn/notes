/* debounce.vala
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


namespace Notes.Util {
    public class Debouncer {
        public signal void callback();

        private uint timeout;
        private uint? timeout_source = null;

        public Debouncer(uint timeout) {
            this.timeout = timeout;
        }

        ~Debouncer() {
            remove_timeout();
        }

        private void invoke_callback() {
            timeout_source = null;
            callback();
        }

        private void remove_timeout() {
            if (timeout_source != null)
                Source.remove(timeout_source);
        }

        public void call() {
            remove_timeout();

            timeout_source = Timeout.add_full(Priority.DEFAULT, timeout, () => {
                invoke_callback();
                return false;
            });
        }
    }
}