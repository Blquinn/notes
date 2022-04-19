/* editor.vala
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
    public class Editor : Gtk.Box {

        private Models.WindowState win_state;
        private Models.AppState app_state;
        private Gtk.Stack stack;

        private Gtk.Box editor_box;
        private Gtk.Label placeholder;
        private Gtk.Entry title_entry;
        private Gtk.Label notebook_name_lbl;
        private Gtk.Label last_updated_lbl;
        // private Gtk.TextView note_text;
        private WebKit.WebView webview;
        private WebKit.UserContentManager webview_ucm;
        private Adw.StyleManager style_manager;

        private Binding? title_binding;
        private Binding? last_updated_binding;
        private Binding? notebook_name_binding;

        const string last_updated_prefix = _("Last updated");

        public Editor(Models.AppState state, Models.WindowState win_state) {
            Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);
            this.app_state = state;
            this.win_state = win_state;
            this.style_manager = Adw.StyleManager.get_for_display(get_display());
            build_ui();
        }

        private void on_move_notebook_btn_clicked() {
            debug("Move notebook button clicked.");

            if (win_state.active_note == null) {
                debug("Active note is null, not opening move diag.");
                return;
            }

            new MoveNoteDialog(app_state, win_state.active_note) {
                transient_for = (Gtk.Window) this.root,
            }.present();
        }

        private void on_active_note_changed() {
            // Unbind existing bindings.

            if (title_binding != null)
                title_binding.unbind();

            if (last_updated_binding != null)
                last_updated_binding.unbind();

            if (notebook_name_binding != null)
                notebook_name_binding.unbind();

            var note = win_state.active_note;
            if (note == null) {
                stack.set_visible_child(placeholder);
                return;
            }

            stack.set_visible_child(editor_box);

            // Set the rest of the properties.

            title_binding = note.bind_property("title", title_entry, "text", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL, null, null);

            // Hack to reset undo/redo stacks. Otherwise pressing undo after changing notes
            // would undo changes from the last note :/
            // Undo/Redo stacks should be stored on the buffer like they are for TextView...
            title_entry.enable_undo = false;
            title_entry.enable_undo = true;

            // TODO: When the notebook changes it's name, this label has to update.
            notebook_name_binding = note.bind_property("notebook", notebook_name_lbl, "label", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE, 
                (_, f, ref t) => { 
                    var notebook = (Models.Notebook?) f;
                    var name = notebook == null ? Models.NOTEBOOK_ALL_NOTES : notebook.name;
                    t.set_string(name);
                    return true; 
                }, null);
                
            last_updated_binding = note.bind_property("updated-at", last_updated_lbl, "label", GLib.BindingFlags.SYNC_CREATE, 
                (_, f, ref t) => { 
                    var update_time = note.updated_at_formatted();
                    t.set_string(@"$last_updated_prefix $update_time");
                    return true; 
                }, null);

            // Set editor state
            // TODO: Bind the editor contents.
            webview.run_javascript.begin(@"loadEditor($(note.id), $(note.editor_state));");
        }

        private void on_editor_changed(WebKit.JavascriptResult payload) {
            var val = payload.get_js_value();
            var note_id = (int) val.object_get_property("noteId").to_int32();
            var editor_json = val.object_get_property("state").to_string();
            var editor_text = val.object_get_property("text").to_string();

            var note = win_state.active_note;
            if (note.id == note_id) {
                note.editor_state = editor_json;
                note.body_preview = editor_text;
            } else {
                for (int i = 0; i < app_state.notes.get_n_items(); i++) {
                    var n = (Models.Note) app_state.notes.get_item(i);
                    if (n.id == note_id) {
                        note.editor_state = editor_json;
                        note.body_preview = editor_text;
                        return;
                    }
                }

                warning("Note with note_id %d not found.", note_id);
            }
        }

        private void recolor_webview() {
            string js;

            if (style_manager.dark) {
                js = """
                document.documentElement.style.setProperty('--text-color', '#ffffff');
                document.documentElement.style.setProperty('--background-color', '#1e1e1e');
                document.documentElement.style.setProperty('--code-block-background-color', '#393939');
                document.documentElement.style.setProperty('--code-block-text-color', '#ffffff');
                """;
            } else {
                js = """
                document.documentElement.style.setProperty('--text-color', 'inherit');
                document.documentElement.style.setProperty('--background-color', 'inherit');
                document.documentElement.style.setProperty('--code-block-background-color', '#eee');
                document.documentElement.style.setProperty('--code-block-text-color', 'inherit');
                """;
            }

            webview.run_javascript.begin(js, null);
        }
        
        private void build_ui() {
            add_css_class("view");

            // Empty page.
            stack = new Gtk.Stack();
            append(stack);

            editor_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            stack.add_child(editor_box);

            placeholder = new Gtk.Label(null);
            stack.add_child(placeholder);

            stack.set_visible_child(placeholder);
            
            title_entry = new Gtk.Entry() {
                css_classes = {"flat", "title-1"},
                halign = Gtk.Align.FILL,
                placeholder_text = _("Note Title..."),
            };
            
            var contents_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 8);
            editor_box.append(new Adw.Clamp() {
                margin_top = 8,
                margin_end = 8,
                margin_bottom = 8,
                margin_start = 8,
                maximum_size = 800,
                child = contents_box,
            });
            contents_box.append(title_entry);
            contents_box.append(new Gtk.Separator(Gtk.Orientation.HORIZONTAL));
            
            var note_details_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 8);
            // TODO: Source this from somewhere.
            last_updated_lbl = new Gtk.Label(null) {
                css_classes = {"dim-label"},
            };
            note_details_box.append(last_updated_lbl);
            
            var change_nb_btn = new Gtk.Button();
            change_nb_btn.add_css_class("flat");
            change_nb_btn.clicked.connect(on_move_notebook_btn_clicked);
            
            var change_nb_btn_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 8);
            var nb_icon = new Gtk.Image() {
                icon_name = "accessories-text-editor-symbolic",
                css_classes = {"dim-label"},
            };
            change_nb_btn_box.append(nb_icon);
            notebook_name_lbl = new Gtk.Label(null) {
                css_classes = {"dim-label"},
            };
            change_nb_btn_box.append(notebook_name_lbl);
            change_nb_btn.child = change_nb_btn_box;
            note_details_box.append(change_nb_btn);
            
            contents_box.append(note_details_box);
            
            webview_ucm = new WebKit.UserContentManager();
            var webview_settings = new WebKit.Settings() {
                enable_write_console_messages_to_stdout = true,
                allow_top_navigation_to_data_urls = false,
                allow_universal_access_from_file_urls = false,
                enable_back_forward_navigation_gestures = false,
                // TODO: Disable this in production builds.
                enable_developer_extras = true,
            };
            webview = new WebKit.WebView.with_user_content_manager(webview_ucm) {
                vexpand = true,
                settings = webview_settings,
            };

            load_script_from_resource("/me/blq/notes/js/trix.js");
            load_stylesheet_from_resource("/me/blq/notes/js/trix.css");

            // Register script messages.
            webview_ucm.script_message_received["editorChanged"].connect(on_editor_changed);
            webview_ucm.register_script_message_handler("editorChanged");

            webview.decide_policy.connect((decision, type) => {
                if (type == WebKit.PolicyDecisionType.NAVIGATION_ACTION) {
                    var nav_decision = (WebKit.NavigationPolicyDecision) decision;
                    // Prevent user from navigating to links on page inside webview.
                    if (nav_decision.navigation_action.get_request().uri == "about:blank")
                        decision.use();
                    else
                        decision.ignore();
                }

                return false;
            });

            try {
                var html_stream = GLib.resources_open_stream("/me/blq/notes/js/editor.html", GLib.ResourceLookupFlags.NONE);
                var html_bts = html_stream.read_bytes(int.MAX, null);
                webview.load_bytes(html_bts, null, null, null);
            } catch (Error e) {
                error("Failed to load html into webview: %s", e.message);
            }

            contents_box.append(new Gtk.ScrolledWindow() {
                child = webview,
            });

            editor_box.append(new Gtk.Separator(Gtk.Orientation.HORIZONTAL));

            var editor_toolbar = new EditorToolbar(app_state, this);
            editor_box.append(editor_toolbar);
            
            webview_ucm.script_message_received["activeAttributesChanged"].connect(editor_toolbar.on_editor_active_attributes_changed);
            webview_ucm.register_script_message_handler("activeAttributesChanged");

            win_state.notify["active-note"].connect(on_active_note_changed);
            style_manager.notify["dark"].connect(recolor_webview);

            webview.load_changed.connect((e) => {
                if (e == WebKit.LoadEvent.FINISHED)
                    recolor_webview();
            });
        }

        private void load_stylesheet_from_resource(string resource_path) {
            try {
                var res_stream = GLib.resources_open_stream(resource_path, GLib.ResourceLookupFlags.NONE);
                var res_bts = res_stream.read_bytes(int.MAX, null);

                var stylesheet = new WebKit.UserStyleSheet(
                    (string) res_bts.get_data(),
                    WebKit.UserContentInjectedFrames.ALL_FRAMES,
                    WebKit.UserStyleLevel.AUTHOR,
                    null,
                    null
                );
                webview_ucm.add_style_sheet(stylesheet);
            } catch (Error e) {
                error("Failed to read resource: %s", e.message);
            }
        }

        private void load_script_from_resource(string resource_path) {
            try {
                var res_stream = GLib.resources_open_stream(resource_path, GLib.ResourceLookupFlags.NONE);
                var res_bts = res_stream.read_bytes(int.MAX, null);
                var res_script = new WebKit.UserScript(
                    (string) res_bts.get_data(),
                    WebKit.UserContentInjectedFrames.ALL_FRAMES,
                    WebKit.UserScriptInjectionTime.END,
                    null,
                    null
                );
                webview_ucm.add_script(res_script);
            } catch (Error e) {
                error("Failed to read resource: %s", e.message);
            }
        }

        public void activate_attribute(string attribute) {
            webview.run_javascript.begin(@"toggleAttribute('$(attribute)');");
        }

        public void on_change_nesting_level_clicked(bool increase) {
            if (increase) {
                debug("Increasing nesting level.");
                webview.run_javascript.begin("element.editor.increaseNestingLevel();");
            } else {
                debug("Decreasing nesting level.");
                webview.run_javascript.begin("element.editor.decreaseNestingLevel();");
            }
        }

        public void give_webview_focus() {
            webview.grab_focus();
        }
    }

    public class EditorToolbar : Gtk.Box {

        private Gtk.ToggleButton bold_button;
        private Gtk.ToggleButton italic_button;
        private Gtk.ToggleButton underline_button;
        private Gtk.ToggleButton strikethrough_button;

        private Gtk.ToggleButton unordered_list_btn;
        private Gtk.ToggleButton ordered_list_btn;
        private Gtk.ToggleButton code_btn;
        private Gtk.ToggleButton quote_btn;

        private HashTable<string, Gtk.ToggleButton> btn_map = new HashTable<string, Gtk.ToggleButton>(null, null);
        private HashTable<Gtk.ToggleButton, string> btn_reverse_map = new HashTable<Gtk.ToggleButton, string>(null, null);

        private unowned Models.AppState app_state;
        private unowned Editor editor;

        public EditorToolbar(Models.AppState app_state, Editor editor) {
            Object(
                orientation: Gtk.Orientation.HORIZONTAL, 
                spacing: 0
            );
            this.app_state = app_state;
            this.editor = editor;
            css_classes = {"background"};
            build_ui();
        }

        public void on_editor_active_attributes_changed(WebKit.JavascriptResult payload) {
            var val = payload.get_js_value();
            btn_map.foreach((key, btn) => {
                var has_prop = val.object_has_property(key);
                if (has_prop) {
                    var active = val.object_get_property(key).to_boolean();
                    if (btn.active != active) 
                        btn.active = active;
                } else if (btn.active != false) { // Property not there, so turn it off.
                    btn.active = false;
                }
            });
        }

        private void on_attribute_button_clicked(Gtk.Button btn) {
            var tb = (Gtk.ToggleButton) btn;

            var attr = btn_reverse_map.get(tb);
            debug("Editor toggled %s", attr);
            editor.activate_attribute(attr);
            editor.give_webview_focus();
        }

        private void on_increase_nesting_level_clicked() {
            editor.on_change_nesting_level_clicked(true);
            editor.give_webview_focus();
        }

        private void on_decrease_nesting_level_clicked() {
            editor.on_change_nesting_level_clicked(false);
            editor.give_webview_focus();
        }

        private void build_ui() {
            // TODO: Why is there additional spacing after the left-most child?
            var inner_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 8) {
                halign = Gtk.Align.CENTER,
                hexpand = true,
                valign = Gtk.Align.CENTER,
                margin_top = 4,
                margin_bottom = 4,
            };
            append(inner_box);

            // Text weight

            var text_weight_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0) {
                css_classes = {"linked"}
            };
            inner_box.append(text_weight_box);

            bold_button = new Gtk.ToggleButton() {
                icon_name = "format-text-bold-symbolic",
            };
            bold_button.clicked.connect(on_attribute_button_clicked);

            text_weight_box.append(bold_button);
            italic_button = new Gtk.ToggleButton() {
                icon_name = "format-text-italic-symbolic",
            };
            text_weight_box.append(italic_button);
            italic_button.clicked.connect(on_attribute_button_clicked);

            underline_button = new Gtk.ToggleButton() {
                icon_name = "format-text-underline-symbolic",
            };
            text_weight_box.append(underline_button);
            underline_button.clicked.connect(on_attribute_button_clicked);

            strikethrough_button = new Gtk.ToggleButton() {
                icon_name = "format-text-strikethrough-symbolic"
            };
            text_weight_box.append(strikethrough_button);
            strikethrough_button.clicked.connect(on_attribute_button_clicked);

            var text_alignment_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0) {
                css_classes = {"linked"}
            };
            inner_box.append(text_alignment_box);

            // Lists buttons

            var lists_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0) {
                css_classes = {"linked"}
            };
            inner_box.append(lists_box);

            unordered_list_btn = new Gtk.ToggleButton() {
                icon_name = "view-list-symbolic"
            };
            lists_box.append(unordered_list_btn);
            unordered_list_btn.clicked.connect(on_attribute_button_clicked);

            ordered_list_btn = new Gtk.ToggleButton() {
                icon_name = "list-ol-symbolic",
            };
            lists_box.append(ordered_list_btn);
            ordered_list_btn.clicked.connect(on_attribute_button_clicked);

            code_btn = new Gtk.ToggleButton() {
                icon_name = "code-symbolic",
            };
            lists_box.append(code_btn);
            code_btn.clicked.connect(on_attribute_button_clicked);

            quote_btn = new Gtk.ToggleButton() {
                icon_name = "chat-box-symbolic",
            };
            lists_box.append(quote_btn);
            quote_btn.clicked.connect(on_attribute_button_clicked);

            // Indent buttons

            var indent_levels_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0) {
                css_classes = {"linked"}
            };
            inner_box.append(indent_levels_box);

            var right_indent_btn = new Gtk.Button() {
                icon_name = "format-indent-more-symbolic"
            };
            indent_levels_box.append(right_indent_btn);
            right_indent_btn.clicked.connect(on_increase_nesting_level_clicked);

            var left_indent_btn = new Gtk.Button() {
                icon_name = "format-indent-less-symbolic"
            };
            indent_levels_box.append(left_indent_btn);
            left_indent_btn.clicked.connect(on_decrease_nesting_level_clicked);

            btn_map.insert("bold", bold_button);
            btn_map.insert("italic", italic_button);
            btn_map.insert("underline", underline_button);
            btn_map.insert("strike", strikethrough_button);
            btn_map.insert("bullet", unordered_list_btn);
            btn_map.insert("number", ordered_list_btn);
            btn_map.insert("code", code_btn);
            btn_map.insert("quote", quote_btn);

            btn_map.foreach((key, btn) => btn_reverse_map.insert(btn, key));
        }
    }
}
