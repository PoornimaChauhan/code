// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
  BEGIN LICENSE

  Copyright (C) 2011 Giulio Collura <random.cpp@gmail.com>
  This program is free software: you can redistribute it and/or modify it
  under the terms of the GNU Lesser General Public License version 3, as published
  by the Free Software Foundation.

  This program is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranties of
  MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
  PURPOSE.  See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License along
  with this program.  If not, see <http://www.gnu.org/licenses/>

  END LICENSE
***/

using Gtk;
using Granite.Widgets;

using Scratch.Services;

namespace Scratch.Widgets {

    public class Toolbar : Gtk.Toolbar {

        private MainWindow window;

        public ToolButton new_button;
        public ToolButton open_button;
        public ToolButton save_button;
        //public ToolButton save_as_button;
        public ToolButton undo_button;
        public ToolButton repeat_button;
        public ToolButton revert_button;
        
        public Granite.Widgets.ToolArrow search_arrow;
        
        public ShareMenu share_menu;
        public Gtk.Menu menu;
        public ShareAppMenu share_app_menu;
        public AppMenu app_menu;
        
        Gtk.Menu menu_ui;
        
        public bool replace_active = false;
        public bool goto_active = false;

        public enum ToolButtons {
            NEW_BUTTON,
            OPEN_BUTTON,
            SAVE_BUTTON,
            UNDO_BUTTON,
            REPEAT_BUTTON,
            REVERT_BUTTON,
            SHARE_BUTTON,
            APP_MENU_BUTTON
        }

        public enum ToolEntry {
            SEARCH_ENTRY,
            REPLACE_ENTRY,
            GOTO_ENTRY
        }
        
        UIManager ui;
        public Scratch.Services.SearchManager search_manager;

        public Toolbar (MainWindow parent, UIManager ui, Gtk.ActionGroup action_group) {

            this.window = parent;
            this.ui = ui;

            // Toolbar properties
            // compliant with elementary HIG
            get_style_context ().add_class ("primary-toolbar");

            new_button = action_group.get_action("New tab").create_tool_item() as Gtk.ToolButton;
            open_button = action_group.get_action("Open").create_tool_item() as Gtk.ToolButton;
            //save_as_button = action_group.get_action("SaveFileAs").create_tool_item() as Gtk.ToolButton;
            save_button = action_group.get_action("SaveFile").create_tool_item() as Gtk.ToolButton;
            undo_button = action_group.get_action("Undo").create_tool_item() as Gtk.ToolButton;
            repeat_button = action_group.get_action("Redo").create_tool_item() as Gtk.ToolButton;
            revert_button = action_group.get_action("Revert").create_tool_item() as Gtk.ToolButton;
            
            search_arrow = new Granite.Widgets.ToolArrow ();
            search_arrow.clicked.connect(on_show_popover);
            
            add (new_button);
            add (open_button);
            add (save_button);
            //add (save_as_button);
            add (new SeparatorToolItem ());
            add (revert_button);
            add (undo_button);
            add (repeat_button);
            
            add (new SeparatorToolItem ());

            share_menu = new ShareMenu (this.window);
            share_app_menu = new ShareAppMenu (share_menu);
            
            menu = ui.get_widget ("ui/AppMenu") as Gtk.Menu;
            plugins.hook_main_menu(menu);
            app_menu = (window.get_application() as Granite.Application).create_appmenu(menu);
            plugins.toolbar = this;
            plugins.hook_toolbar();

            add (add_spacer ());

            //search_manager = new Scratch.Services.SearchManager (action_group);
            //Scratch.settings.schema.bind ("search-sensitive", search_manager, "case-sensitive", SettingsBindFlags.DEFAULT);

            add (search_manager.get_search_entry ());
            search_manager.get_search_entry ().set_margin_right (5);
            add (search_manager.get_replace_entry ());
            add (search_manager.get_go_to_entry ());
            add (search_arrow);
            
            add (share_app_menu);
            add (app_menu);
            
            settings.changed.connect (show_hide_button);
            
            /* Set up the context menu */
            menu_ui = ui.get_widget ("ui/ToolbarContext") as Gtk.Menu;
            
        }
        
        void on_show_popover() {
            search_arrow.set_state (true);
            var search_popover = new Granite.Widgets.PopOver ();
            search_popover.move_to_widget (search_arrow);
            var box = search_popover.get_content_area() as Gtk.Box;
 
            var grid = new Gtk.Grid ();
            grid.row_spacing = 5;
            grid.column_spacing = 5;
            grid.margin_left = 12;
            grid.margin_right = 12;
            grid.margin_top = 12;
            grid.margin_bottom = 12;            
            
            int row = 0;
            
            var label = new Label (_("General:"));
            add_section (grid, label, ref row);            
            var case_sensitive = new Gtk.Switch ();
            Scratch.settings.schema.bind("search-sensitive", case_sensitive, "active", SettingsBindFlags.DEFAULT);
            label = new Label (_("Case sensitive search:"));
            add_option (grid, label, case_sensitive, ref row);
            
            label = new Label (_("Entries:"));
            add_section (grid, label, ref row);  
            unowned SList<Gtk.RadioButton> group = null;
            var search = new Gtk.RadioButton (group);
            Scratch.settings.schema.bind("show-search", search, "active", SettingsBindFlags.DEFAULT);
            label = new Label (_("Search:"));
            add_option (grid, label, search, ref row);
            var replace = new Gtk.RadioButton (search.get_group ());
            Scratch.settings.schema.bind("show-replace", replace, "active", SettingsBindFlags.DEFAULT);
            label = new Label (_("Replace:"));
            add_option (grid, label, replace, ref row);
            var go_to_line = new Gtk.RadioButton (search.get_group ());
            Scratch.settings.schema.bind("show-go-to-line", go_to_line, "active", SettingsBindFlags.DEFAULT);
            label = new Label (_("Go to line:"));
            add_option (grid, label, go_to_line, ref row);
            
            box.pack_start (grid);

            search_popover.show_all();
            search_popover.present();
            search_popover.run();
            search_popover.destroy();
            search_arrow.set_state(false);
        }
        
        void add_section (Gtk.Grid grid, Gtk.Label name, ref int row) {
            name.use_markup = true;
            name.set_markup ("<b>%s</b>".printf (name.get_text ()));
            name.halign = Gtk.Align.START;
            grid.attach (name, 0, row, 1, 1);
            row ++;
        }
        
        void add_option (Gtk.Grid grid, Gtk.Widget label, Gtk.Widget switcher, ref int row) {
            label.hexpand = true;
            label.halign = Align.END;
            label.margin_left = 20;
            switcher.halign = Gtk.Align.FILL;
            switcher.hexpand = true;
            
            if (switcher is Switch || switcher is CheckButton
                || switcher is Entry) { /* then we don't want it to be expanded */
                switcher.halign = Gtk.Align.START;
            }
            
            grid.attach (label, 0, row, 1, 1);
            grid.attach_next_to (switcher, label, Gtk.PositionType.RIGHT, 3, 1);
            row ++;
        }
        
        public void show_hide_button () {
            if (settings.autosave) save_button.hide ();
            else save_button.show ();
        }
        
        public override bool button_press_event (Gdk.EventButton event) {
            if (event.button == 3) {
                if (window.main_actions.get_action ("ShowContextView").visible == false &&
                        window.main_actions.get_action ("ShowBottomPanel").visible == false &&
                        window.main_actions.get_action ("ShowSidebar").visible == false &&
                        window.main_actions.get_action ("ShowStatusBar").visible == false) {
                    return true;       
                }
                else {
                (ui.get_widget ("ui/ToolbarContext") as Gtk.Menu).popup (null, null, null, event.button, Gtk.get_current_event_time ());
                }
                return true;
            }
            return base.button_press_event (event);
        }

        private ToolItem add_spacer () {

            var spacer = new ToolItem ();
            spacer.set_expand (true);

            return spacer;

        }
        
        public void set_actions (bool val) {
            share_app_menu.set_sensitive(val);
        }

        public void set_button_sensitive(int button, bool sensitive) {
            switch (button) {
            case ToolButtons.NEW_BUTTON:
                this.new_button.set_sensitive(sensitive);
                break;

            case ToolButtons.OPEN_BUTTON:
                this.open_button.set_sensitive(sensitive);
                break;

            case ToolButtons.SAVE_BUTTON:
                this.save_button.set_sensitive(sensitive);
                break;

            case ToolButtons.UNDO_BUTTON:
                this.undo_button.set_sensitive(sensitive);
                break;

            case ToolButtons.REPEAT_BUTTON:
                this.repeat_button.set_sensitive(sensitive);
                break;

            case ToolButtons.REVERT_BUTTON:
                this.revert_button.set_sensitive(sensitive);
                break;
            case ToolButtons.SHARE_BUTTON:
                controll_for_share_plugins ();
                break;

            case ToolButtons.APP_MENU_BUTTON:
                this.app_menu.set_sensitive(sensitive);
                break;
            }
        }

        public void controll_for_share_plugins () {
            share_app_menu.no_show_all = false;
            share_app_menu.show_all();
        }
    }
} // Namespace
