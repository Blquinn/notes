/* note_menu.vala
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
    public MenuModel create_note_actions_menu() {
        var menu = new Menu();
        var section1 = new Menu();
        menu.append_section(null, section1);

        section1.append_item(new MenuItem(_("_Open in New Window"), "win.active-note.open-in-new-window"));

        var section2 = new Menu();
        menu.append_section(null, section2);
        section2.append_item(new MenuItem(_("_Pin"), "win.active-note.pin"));
        section2.append_item(new MenuItem(_("_Move To..."), "win.active-note.move-to"));

        var section3 = new Menu();
        menu.append_section(null, section3);

        section3.append_item(new MenuItem(_("_Move to Trash"), "win.active-note.move-to-trash"));
        
        return menu;
    }
}