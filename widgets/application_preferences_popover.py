# -*- coding: utf-8 -*-
# Copyright (c) 2020, Benjamin Quinn <benlquinn@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this program; if not, see <http://www.gnu.org/licenses/>.
from gi.repository import Gtk

from widgets.about_dialog import AboutDialog


@Gtk.Template.from_file('ui/ApplicationPreferencesPopover.ui')
class ApplicationPreferencesPopover(Gtk.PopoverMenu):
    __gtype_name__ = 'ApplicationPreferencesPopover'

    def __init__(self, main_window):
        super(ApplicationPreferencesPopover, self).__init__()
        self.main_window = main_window
       
    @Gtk.Template.Callback('on_about_button_clicked') 
    def _on_about_button_clicked(self, btn):
        AboutDialog(transient_for=self.main_window.get_toplevel()).show()
