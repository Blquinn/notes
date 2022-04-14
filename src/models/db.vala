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


namespace Notes.Models {
    
    public errordomain DbError {
        ERROR,
    }

    private void bind_nullable_int(Sqlite.Statement stmt, int column, int? value) {
        if (value == null) {
            stmt.bind_null(column);
        } else {
            stmt.bind_int(column, value);
        }
    }
    
    private void bind_nullable_int64(Sqlite.Statement stmt, int column, int64? value) {
        if (value == null) {
            stmt.bind_null(column);
        } else {
            stmt.bind_int64(column, value);
        }
    }

    public class Db {
        private string path;
        private Sqlite.Database db;
        
        public Db(string path = @"$(Environment.get_user_data_dir())/notes/notes.db") throws DbError {
            this.path = path;
            init();
        }
        
        private void must(int rc) throws DbError {
            if (rc != Sqlite.OK)
            throw new DbError.ERROR(db.errmsg());
        }
        
        private void init() throws DbError {
            debug("Creating sqlite database at %s", path);
            must(Sqlite.Database.open_v2(path, out db));

            try {
                execute("""
                create table notebooks (
                    id integer primary key autoincrement,
                    name text not null
                );
                """);
                debug("Created notebooks table.");

                execute("""
                create table notes (
                    id integer primary key autoincrement,
                    last_updated bigint not null,
                    notebook_id text references notebooks,
                    title text not null,
                    note_contents text not null,
                    note_preview text not null,
                    deleted_at bigint null,
                    is_pinned boolean not null default false
                );
                """);
                debug("Created notes table.");
            } catch (Error e) {}
        }

        public delegate void BindFunc(Sqlite.Statement stmt);
        
        public void execute(string query, BindFunc? bf = null)
        throws DbError
        requires (query != "")
        {
            debug("Executing query %s", query);

            Sqlite.Statement stmt;
            must(db.prepare_v2(query, query.length, out stmt));

            if (bf != null) bf(stmt);

            var rc = stmt.step();
            stmt.reset();
            if (rc != Sqlite.DONE)
                throw new DbError.ERROR("Execute expects no rows to be returned.");
        }

        public delegate R MapFunc<T, R>(T t);

        public GenericArray<T> select_rows<T>(string query, MapFunc<Sqlite.Statement, T> map_func, BindFunc? bf = null)
        throws DbError
        requires (query != "")
        {
            Sqlite.Statement stmt;
            must(db.prepare_v2(query, query.length, out stmt));
            
            if (bf != null) bf(stmt);
            
            var rows = new GenericArray<T>();
            while(stmt.step() == Sqlite.ROW) {
                rows.add(map_func(stmt));
            }
            stmt.reset();
            
            return rows;
        }

        public T? select_row<T>(string query, MapFunc<Sqlite.Statement, T> map_func, BindFunc? bf = null)
        throws DbError
        requires (query != "")
        {
            var rows = select_rows<T>(query, map_func, bf);
            if (rows.length == 0)
                return null;
            if (rows.length > 1)
                error("select_row returned more than 1 row.");
            return rows.get(0);
        }

        public int get_last_insert_rowid() throws DbError {
            return select_row<int>("SELECT last_insert_rowid();", (stmt) => stmt.column_int(0), null);
        }

        public int changes() {
            return this.db.changes();
        }
    }

    public class NoteDao {
        private unowned AppState state;
        private Db db;

        public NoteDao(AppState state, Db db) {
            this.state = state;
            this.db = db;
        }

        public GenericArray<Note> find_all(GenericArray<Notebook> notebooks) throws DbError {
            var nb_map = new HashTable<int, Notebook>(null, null);
            foreach (var nb in notebooks)
                nb_map[nb.id] = nb;

            return db.select_rows<Note>("""
            select n.id, n.title, n.note_contents, n.note_preview, n.deleted_at, n.is_pinned, nb.id, n.last_updated
            from notes n
            left outer join notebooks nb on n.notebook_id = nb.id
            order by n.is_pinned desc, n.last_updated desc
            """, (stmt) => {
                Notebook? nb = null;
                var nb_id = stmt.column_int(6);
                if (nb_id > 0) {
                    nb = nb_map.get(nb_id);
                }

                DateTime? deleted_at = null;
                var da_unix = stmt.column_int64(4);
                if (da_unix > 0) {
                    deleted_at = new DateTime.from_unix_local(da_unix);
                }

                return new Note(
                    state,
                    stmt.column_text(1), 
                    nb, 
                    deleted_at,
                    new DateTime.from_unix_local(stmt.column_int64(7)),
                    (bool) stmt.column_int(5),
                    stmt.column_text(2),
                    stmt.column_text(3)
                ) { id = stmt.column_int(0) };
            });
        }

        public void save(Note note) throws DbError {
            var notebook_id = note.notebook?.id;

            if (note.id > 0) {
                db.execute(""" 
                    update notes 
                    set notebook_id = ?, title = ?, note_contents = ?, note_preview = ?, deleted_at = ?, 
                        is_pinned = ?, last_updated = ?
                    where id = ? 
                """, (stmt) => {
                    bind_nullable_int(stmt, 1, notebook_id);
                    stmt.bind_text(2, note.title);
                    stmt.bind_text(3, note.editor_state);
                    stmt.bind_text(4, note.body_preview);
                    bind_nullable_int64(stmt, 5, note.deleted_at?.to_unix());
                    stmt.bind_int(6, (int)note.is_pinned);
                    stmt.bind_int64(7, note.updated_at.to_unix());
                    stmt.bind_int(8, note.id);
                });
                debug("Updated note %d, %d rows effected", note.id, db.changes());
                return;
            }

            db.execute("""
            insert into notes (notebook_id, title, note_contents, note_preview, deleted_at, is_pinned, last_updated)
            values (?, ?, ?, ?, ?, ?, ?)
            """, (stmt) => {
                bind_nullable_int(stmt, 1, notebook_id);
                stmt.bind_text(2, note.title);
                stmt.bind_text(3, note.editor_state);
                stmt.bind_text(4, note.body_preview);
                bind_nullable_int64(stmt, 5, note.deleted_at?.to_unix());
                stmt.bind_int(6, (int)note.is_pinned);
                stmt.bind_int64(7, note.updated_at.to_unix());
            });

            note.id = db.get_last_insert_rowid();
            debug("Inserted note %d", note.id);
        }
    }

    public class NotebookDao {
        private unowned AppState state;
        private Db db;

        public NotebookDao(AppState state, Db db) {
            this.state = state;
            this.db = db;
        }

        public void save(Notebook nb) throws DbError {
            if (nb.id > 0) {
                db.execute("update notebooks set name = ? where id = ?", (stmt) => {
                    stmt.bind_text(1, nb.name);
                    stmt.bind_int(2, nb.id);
                });
                return;
            }

            db.execute("insert into notebooks (name) values (?)", (stmt) => {
                stmt.bind_text(1, nb.name);
            });
            nb.id = db.get_last_insert_rowid();
        }

        public void delete(Notebook nb) throws DbError {
            // TODO: Delete all notes in notebook.
            db.execute("delete from notebooks where id = ?", (stmt) => {
                stmt.bind_int(1, nb.id);
            });
        }

        public GenericArray<Notebook> find_all() throws DbError {
            return db.select_rows<Notebook>("select id, \"name\" from notebooks", (stmt) => {
                return new Notebook(state, stmt.column_text(1)) {
                    id = stmt.column_int(0)
                };
            });
        }
    }
}
