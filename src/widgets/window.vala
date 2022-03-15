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

namespace Notes {
	public class Window : Adw.ApplicationWindow {
		public Window (Gtk.Application app) {
			Object (application: app);
			build_ui();
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
			//  var sidebar_page = leaflet.append(sidebar_box);
			leaflet.append(sidebar_box);
			var sidebar_header = new Adw.HeaderBar();
			leaflet.bind_property("folded", sidebar_header, "show-end-title-buttons", GLib.BindingFlags.DEFAULT, null, null);

			sidebar_header.show_end_title_buttons = false;
			sidebar_box.append(sidebar_header);

			var add_note_btn = new Gtk.Button();
			add_note_btn.icon_name = "list-add-symbolic";
			sidebar_header.pack_start(add_note_btn);

			// Show hamburger menu here if leaflet is folded.

			var sidebar_menu_btn = new Gtk.Button();
			sidebar_menu_btn.visible = leaflet.folded;
			leaflet.bind_property("folded", sidebar_menu_btn, "visible", GLib.BindingFlags.DEFAULT, null, null);
			sidebar_menu_btn.icon_name = "view-more-symbolic";
			sidebar_header.pack_end(sidebar_menu_btn);

			var open_menu_btn = new Gtk.Button();
			open_menu_btn.icon_name = "open-menu-symbolic";
			sidebar_header.pack_end(open_menu_btn);

			// TODO: Change this to the note title, or the button when folded / not folded.

			var notes_dropdown_btn = new Gtk.Button();
			notes_dropdown_btn.height_request = 20; // Hack to make button not expand header a couple pixels.
			notes_dropdown_btn.add_css_class("flat");
			var notes_dropdown_btn_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 8);
			notes_dropdown_btn.child = notes_dropdown_btn_box;

			notes_dropdown_btn_box.append(new Gtk.Label(_("All Notes")));
			var down_arrow_icon = new Gtk.Image();
			down_arrow_icon.set_from_icon_name("pan-down-symbolic");
			notes_dropdown_btn_box.append(down_arrow_icon);

			sidebar_header.title_widget = notes_dropdown_btn;

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

			var menu_btn = new Gtk.Button();
			menu_btn.icon_name = "view-more-symbolic";
			content_header.pack_end(menu_btn);

			content_box.append(content_header);
			var content = new Editor();
			content_box.append(content);

			leaflet.navigate(Adw.NavigationDirection.FORWARD);
		}
	}
}
