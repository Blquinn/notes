/* application.vala
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
	public class Application : Adw.Application {

		private Models.AppState state;

		private ActionEntry[] APP_ACTIONS = {
			{ "about", on_about_action },
			{ "preferences", on_preferences_action },
			{ "quit", quit },
		};

		public Application () {
			Object (application_id: "me.blq.notes", flags: ApplicationFlags.FLAGS_NONE);

			this.state = new Models.AppState(this);

			this.add_action_entries(this.APP_ACTIONS, this);
			this.set_accels_for_action("app.quit", {"<primary>q"});
			this.set_color_scheme();
		}

		public override void activate () {
			base.activate();
			var win = this.active_window;
			if (win == null) {
				win = new Widgets.Window(this, state);
			}
			win.present ();
		}

		private void on_about_action () {
			string[] authors = {"Benjamin Quinn"};
			Gtk.show_about_dialog(this.active_window,
				                  "program-name", "notes",
				                  "authors", authors,
				                  "version", "0.1.0");
		}

		private void on_preferences_action () {
			message("app.preferences action activated");
		}

		private void set_color_scheme() {
			var gnome_settings = new Settings("org.gnome.desktop.interface");
			var gtk_theme = gnome_settings.get_string("gtk-theme");
			style_manager.set_color_scheme(get_adw_scheme(gtk_theme));
			gnome_settings.bind_with_mapping("gtk-theme", style_manager, "color-scheme", SettingsBindFlags.DEFAULT, 
				(value, variant, _) => {
					var scheme = get_adw_scheme(variant.get_string());
					value.set_enum(scheme);
					return true;
				}, 
				(a, b, c) => { return true; }, 
				null, null);
		}

		private static Adw.ColorScheme get_adw_scheme(string theme_name) {
			var gtk_settings = Gtk.Settings.get_default();
			var is_dark = (gtk_settings != null && gtk_settings.gtk_application_prefer_dark_theme == true)
				? true
				: theme_name.down().contains("dark");
			return is_dark ? Adw.ColorScheme.PREFER_DARK : Adw.ColorScheme.DEFAULT;
		}
	}
}
