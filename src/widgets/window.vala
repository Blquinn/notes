/* window.vala
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
	public class Window : Adw.ApplicationWindow {

		private Models.AppState app_state;
		public Models.WindowState state { get; private set; }
		
		private ActionEntry[] WIN_ACTIONS = {
			// Window actions
			{ "close", close },
			// Active note menu
			{ "active-note.open-in-new-window", on_active_note_open_in_new_window },
			{ "active-note.pin", on_active_note_pin },
			{ "active-note.move-to", on_active_note_move_to },
			{ "active-note.move-to-trash", on_active_note_move_to_trash },
			//  Window menu actions
			{ "open-keyboard-shortcuts", on_open_keyboard_shortcuts },
			{ "open-edit-notebooks", on_open_edit_notebooks },
		};

		private Gtk.Label notebooks_dropdown_btn_lbl;
		private Binding active_notebook_lbl_binding;

		public Window(Notes.Application app, Models.AppState app_state) {
			Object(application: app);
			this.app_state = app_state;
			this.state = new Models.WindowState(app_state, this);

			add_css_provider();

			this.add_action_entries(this.WIN_ACTIONS, this);
			
			// Couldn't get this to work with action entries :/
			var change_text_action = new SimpleAction.stateful("change-text-size", GLib.VariantType.STRING, "medium");
			change_text_action.activate.connect(on_change_text_size);
			this.add_action(change_text_action);

			var change_notebook_action = new SimpleAction.stateful("change-notebook", GLib.VariantType.STRING, Models.NOTEBOOK_ALL_NOTES);
			change_notebook_action.activate.connect(on_change_notebook);
			this.add_action(change_notebook_action);
			
			build_ui();
		}

		private void add_css_provider() {
			var provider = new Gtk.CssProvider();
			provider.load_from_resource("/me/blq/notes/css/style.css");
			Gtk.StyleContext.add_provider_for_display(get_display(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
		}

		private void on_add_note_btn_clicked() {
			debug("Add note clicked.");

			app_state.add_note(new Models.Note(app_state));
		}
		
		private void on_active_note_open_in_new_window() {
			debug("Opening active note in new window.");

			var new_win = new Window((Application) this.application, app_state);
			new_win.state.active_notebook = state.active_notebook;
			new_win.state.active_note = state.active_note;
			new_win.present();
		}
		
		private void on_active_note_pin() {
			debug("Pinning active note.");
			var n = state.active_note;
			if (n == null)
				return;
			n.is_pinned = !n.is_pinned;
		}
		
		private void on_active_note_move_to() {
			debug("Opening move active note to dialog.");

			if (state.active_note == null) {
				debug("Active note null, not opening move note diag.");
				return;
			}
			new MoveNoteDialog(app_state, state.active_note) {
				transient_for = this,
			}.present();
		}
	
		// TODO: Select top displayed note from notes list after note is moved to trash.
		private void on_active_note_move_to_trash() {
			debug("Moving active not to trash.");

			var n = state.active_note;
			if (n == null)
				return;

			if (n.deleted_at == null)
				n.deleted_at = new DateTime.now_local();
			else
				n.deleted_at = null;
		}
		
		private void on_open_keyboard_shortcuts() {
			debug("Opening keyboard shortcuts.");
			
			//  var shortcuts_win = new Gtk.ShortcutsWindow();
			var builder = new Gtk.Builder.from_resource("/me/blq/notes/gtk/shortcuts-window.ui");
			var win = (Gtk.ShortcutsWindow) builder.get_object("win");
			win.set_transient_for(this);
			win.show();
		}
		
		private void on_change_text_size(SimpleAction action, Variant? size) {
			debug("Changing text size to %s", size.get_string());
			action.set_state(size);
		}

		// TODO: Make sure active notebook label updates correctly.
		private void on_change_notebook(SimpleAction action, Variant? notebook) {
			var nb = notebook.get_string();
			debug("Changing active notebook to %s", nb);

			action.set_state(nb);

			// TODO: Change this reactively
			notebooks_dropdown_btn_lbl.label = nb;

			if (nb == Models.NOTEBOOK_TRASH) {
				state.active_notebook = Models.ActiveNotebookVariant.trash();
			} else if (nb == Models.NOTEBOOK_ALL_NOTES) {
				state.active_notebook = Models.ActiveNotebookVariant.all_notes();
			} else {
				// Find notebook by name
				Models.Notebook nb_obj = null;
				for (var i = 0; i < app_state.notebooks.get_n_items(); i++) {
					var list_nb = (Models.Notebook) app_state.notebooks.get_item(i);
					if (list_nb.name == nb) {
						nb_obj = list_nb;
						break;
					}
				}
				if (nb_obj == null)
					error("Didn't find notebook object for notebook %s.", nb);
				state.active_notebook = Models.ActiveNotebookVariant.from_notebook(nb_obj);
			}
		}

		private void on_open_edit_notebooks() {
			debug("Opening edit notebooks modal.");

			new EditNotebooksDialog(app_state) { transient_for = this }.present();
		}
		
		private MenuModel build_window_menu() {
			var menu = new Menu();
			
			// Text Size
			var section1 = new Menu();
			menu.append_section(_("Text Size"), section1);
			
			var set_text_large = new MenuItem(_("Large"), "win.change-text-size");
			set_text_large.set_attribute_value("target", "large");
			section1.append_item(set_text_large);
			
			var set_text_med = new MenuItem(_("Medium"), "win.change-text-size");
			set_text_med.set_attribute_value("target", "medium");
			section1.append_item(set_text_med);
			
			var set_text_small = new MenuItem(_("Small"), "win.change-text-size");
			set_text_small.set_attribute_value("target", "small");
			section1.append_item(set_text_small);
			
			// Section 2
			var section2 = new Menu();
			menu.append_section(null, section2);
			
			section2.append_item(new MenuItem(_("Keyboard Shortcuts"), "win.open-keyboard-shortcuts"));
			section2.append_item(new MenuItem(_("_About Notes"), "app.about"));
			
			return menu;
		}

		private MenuModel create_notebooks_menu() {
			var menu = new Menu();
			
			// Text Size
			var section1 = new Menu();
			menu.append_section(null, section1);
			
			var all_notes = new MenuItem(_("All notes"), "win.change-notebook");
			all_notes.set_attribute_value("target", Models.NOTEBOOK_ALL_NOTES);
			section1.append_item(all_notes);

			var section2 = new Menu();
			menu.append_section(_("Notebooks"), section2);

			// TODO: Notebooks needs to be stored separately.
			var notebooks = app_state.notebooks;
			for (int i = 0; i < notebooks.get_n_items(); i++) {
				var notebook = (Models.Notebook) notebooks.get_item(i);

				var notebook_menu_item = new MenuItem(notebook.name, "win.change-notebook");
				notebook_menu_item.set_attribute_value("target", notebook.name);
				section2.append_item(notebook_menu_item);
			}

			section2.append_item(new MenuItem(_("Edit Notebooks"), "win.open-edit-notebooks"));
			
			// Section 2
			var section3 = new Menu();
			menu.append_section(null, section3);

			var notebook_menu_item = new MenuItem(_("Trash"), "win.change-notebook");
			notebook_menu_item.set_attribute_value("target", Models.NOTEBOOK_TRASH);
			section3.append_item(notebook_menu_item);
			
			return menu;
		}

		private void bind_active_notebook_label() {
			if (active_notebook_lbl_binding != null)
				active_notebook_lbl_binding.unbind();

			active_notebook_lbl_binding = state.bind_property("active-notebook", notebooks_dropdown_btn_lbl, "label", BindingFlags.SYNC_CREATE, 
				(_, f, ref t) => {
					var nb = (Models.ActiveNotebookVariant) f;
					t.set_string(nb.to_string());
					return true;
				}, null);
		}
		
		private void build_ui() {
			this.default_height = 700;
			this.default_width = 950;
			this.title = _("Notes");
			
			var leaflet = new Adw.Leaflet();
			leaflet.can_swipe_back = true;
			content = leaflet;
			
			// Sidebar
			var sidebar_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
			sidebar_box.width_request = 300;

			leaflet.append(sidebar_box);
			var sidebar_header = new Adw.HeaderBar();
			leaflet.bind_property("folded", sidebar_header, "show-end-title-buttons", GLib.BindingFlags.DEFAULT, null, null);
			
			sidebar_header.show_end_title_buttons = false;
			sidebar_box.append(sidebar_header);
			
			var add_note_btn = new Gtk.Button();
			add_note_btn.icon_name = "list-add-symbolic";
			sidebar_header.pack_start(add_note_btn);
			add_note_btn.clicked.connect(on_add_note_btn_clicked);
			
			// Show hamburger menu here if leaflet is folded.
			
			var open_menu_btn = new Gtk.MenuButton();
			open_menu_btn.icon_name = "open-menu-symbolic";
			sidebar_header.pack_end(open_menu_btn);
			
			var window_actions_popover = new Gtk.PopoverMenu.from_model(build_window_menu());
			open_menu_btn.popover = window_actions_popover;
			open_menu_btn.activate.connect(window_actions_popover.present);
			
			// TODO: Change this to the note title, or the button when folded / not folded.
			
			var notebooks_dropdown_btn = new Gtk.Button();
			notebooks_dropdown_btn.height_request = 20; // Hack to make button not expand header a couple pixels.
			notebooks_dropdown_btn.add_css_class("flat");
			var notes_dropdown_btn_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 8);
			notebooks_dropdown_btn.child = notes_dropdown_btn_box;

			// TODO: When a notebook is added or removed, update this menu.
			var notebooks_popover = new Gtk.PopoverMenu.from_model(create_notebooks_menu());
			notebooks_popover.set_parent(this);

			notebooks_dropdown_btn.clicked.connect(() => {
				debug("Creating notebooks popover.");
				Gtk.Allocation alloc;
				notebooks_dropdown_btn.get_allocation(out alloc);
				notebooks_popover.pointing_to = alloc;
				notebooks_popover.popup();
			});
			notebooks_dropdown_btn_lbl = new Gtk.Label(Models.NOTEBOOK_ALL_NOTES);
			notes_dropdown_btn_box.append(notebooks_dropdown_btn_lbl);
			var down_arrow_icon = new Gtk.Image();
			down_arrow_icon.set_from_icon_name("pan-down-symbolic");
			notes_dropdown_btn_box.append(down_arrow_icon);
			sidebar_header.title_widget = notebooks_dropdown_btn;

			// Update menu any time the # of notebooks changes.
			bind_active_notebook_label();
			app_state.notebook_changed.connect(() => {
				notebooks_popover.menu_model = create_notebooks_menu();
				bind_active_notebook_label();
			});
			
			// SideBar Content
			
			var sidebar_content = new SideBar(app_state, state);
			sidebar_box.append(sidebar_content);
			
			// Separator
			
			var separator_page = leaflet.append(new Gtk.Separator(Gtk.Orientation.VERTICAL));
			separator_page.navigatable = false;
			
			//  Content
			
			var content_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
			content_box.hexpand = true;
			var content_page = leaflet.append(content_box);
			content_page.navigatable = true;
			
			var content_header = new Adw.HeaderBar();
			
			var navigate_back_btn = new Gtk.Button();
			content_header.pack_start(navigate_back_btn);
			navigate_back_btn.icon_name = "go-previous-symbolic";
			navigate_back_btn.visible = false;
			navigate_back_btn.clicked.connect(() => {
				leaflet.navigate(Adw.NavigationDirection.BACK);
			});
			leaflet.bind_property("folded", navigate_back_btn, "visible", GLib.BindingFlags.DEFAULT, null, null);
			
			var menu_btn = new Gtk.MenuButton() {
				icon_name = "view-more-symbolic",
			};
			content_header.pack_end(menu_btn);
			state.bind_property("active-note", menu_btn, "sensitive", GLib.BindingFlags.SYNC_CREATE, 
				(_, f, ref t) => { 
					t.set_boolean((((Models.Note?) f) != null));
					return true;
				}, null);
			
			var note_actions_popover = new Gtk.PopoverMenu.from_model(Widgets.create_note_actions_menu());
			menu_btn.popover = note_actions_popover;
			menu_btn.activate.connect(note_actions_popover.present);
			
			content_box.append(content_header);

			var content = new Editor(app_state, state);
			content_box.append(content);

			// Open editor page when active note changes.
			state.notify["active-note"].connect(() => {
				if (state.active_note != null)
					leaflet.navigate(Adw.NavigationDirection.FORWARD);
			});
		}
	}
}
