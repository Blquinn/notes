/* db.vala
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

using Sqlite;

namespace Notes.Models {

    public errordomain DbError {
        ERROR
    }

    public class Db {
        private Sqlite.Database db;

        public Db() throws DbError {
            init();
        }

        private void must(int rc) throws DbError {
            if (rc != Sqlite.OK)
                throw new DbError.ERROR(db.errmsg());
        }

        private void init() throws DbError {
            must(Sqlite.Database.open_v2("notes.db", out db));
        }
    }
}
