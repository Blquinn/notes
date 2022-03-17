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

		private const string ALL_NOTES = _("All Notes");
		private const string TRASH = _("Trash");

		private Gtk.Label notebooks_dropdown_btn_lbl;
		
		public Window (Gtk.Application app) {
			Object (application: app);
			this.add_action_entries(this.WIN_ACTIONS, this);
			
			// Couldn't get this to work with action entries :/
			var change_text_action = new SimpleAction.stateful("change-text-size", GLib.VariantType.STRING, "medium");
			change_text_action.activate.connect(on_change_text_size);
			this.add_action(change_text_action);

			var change_notebook_action = new SimpleAction.stateful("change-notebook", GLib.VariantType.STRING, ALL_NOTES);
			change_notebook_action.activate.connect(on_change_notebook);
			this.add_action(change_notebook_action);
			
			build_ui();
		}

		private void on_add_note_btn_clicked() {
			debug("Add note clicked.");
		}
		
		private void on_active_note_open_in_new_window() {
			debug("Opening active note in new window.");
		}
		
		private void on_active_note_pin() {
			debug("Pinning active note.");
		}
		
		private void on_active_note_move_to() {
			debug("Opening move active note to dialog.");
			new MoveNoteDialog(new Models.Note() {title = "foo"}) {
				transient_for = this,
			}.present();
		}
		
		private void on_active_note_move_to_trash() {
			debug("Moving active not to trash.");
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

		private void on_change_notebook(SimpleAction action, Variant? notebook) {
			var nb = notebook.get_string();
			debug("Changing active notebook to %s", nb);
			action.set_state(nb);
			notebooks_dropdown_btn_lbl.label = nb;
		}

		private void on_open_edit_notebooks() {
			debug("Opening edit notebooks modal.");

			new EditNotebooksDialog() { transient_for = this }.present();
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
			all_notes.set_attribute_value("target", ALL_NOTES);
			section1.append_item(all_notes);

			var section2 = new Menu();
			menu.append_section(_("Notebooks"), section2);

			string[] notebooks = {
				"Astronomy",
				"Personal",
				"Work",
			};

			foreach (var notebook in notebooks) {
				var notebook_menu_item = new MenuItem(notebook, "win.change-notebook");
				notebook_menu_item.set_attribute_value("target", notebook);
				section2.append_item(notebook_menu_item);
			}

			section2.append_item(new MenuItem(_("Edit Notebooks"), "win.open-edit-notebooks"));
			
			// Section 2
			var section3 = new Menu();
			menu.append_section(null, section3);

			var notebook_menu_item = new MenuItem(_("Trash"), "win.change-notebook");
			notebook_menu_item.set_attribute_value("target", TRASH);
			section3.append_item(notebook_menu_item);
			
			return menu;
		}
		
		private void build_ui() {
			this.default_height = 600;
			this.default_width = 800;
			this.title = _("Notes");
			
			var leaflet = new Adw.Leaflet();
			leaflet.can_swipe_back = true;
			content = leaflet;
			
			// Sidebar
			var sidebar_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
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
			
			var sidebar_menu_btn = new Gtk.Button();
			sidebar_menu_btn.visible = leaflet.folded;
			leaflet.bind_property("folded", sidebar_menu_btn, "visible", GLib.BindingFlags.DEFAULT, null, null);
			sidebar_menu_btn.icon_name = "view-more-symbolic";
			sidebar_header.pack_end(sidebar_menu_btn);
			
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
			notebooks_dropdown_btn_lbl = new Gtk.Label(ALL_NOTES);
			notes_dropdown_btn_box.append(notebooks_dropdown_btn_lbl);
			var down_arrow_icon = new Gtk.Image();
			down_arrow_icon.set_from_icon_name("pan-down-symbolic");
			notes_dropdown_btn_box.append(down_arrow_icon);
			sidebar_header.title_widget = notebooks_dropdown_btn;
			
			// SideBar Content
			
			var sidebar_content = new SideBar();
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
			
			var note_actions_popover = new Gtk.PopoverMenu.from_model(Widgets.create_note_actions_menu());
			menu_btn.popover = note_actions_popover;
			menu_btn.activate.connect(note_actions_popover.present);
			
			content_box.append(content_header);

			var content = new Editor();
			content_box.append(content);
			
			leaflet.navigate(Adw.NavigationDirection.FORWARD);
		}
	}
}
