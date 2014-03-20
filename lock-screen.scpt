#!/usr/bin/osascript

-- http://lists.apple.com/archives/applescript-users/2007/Feb/msg00233.html

to click_menu_extra at menu_list
  tell application "System Events" to tell process "SystemUIServer"'s menu bar 1
    click (first menu bar item whose value of attributes contains menu_list's beginning)
    repeat with item_name in rest of menu_list
      click (first menu item of result's menu 1 whose name is item_name)
    end repeat
  end tell
end click_menu_extra

click_menu_extra at {"Keychain menu extra", "Lock Screen"}


-- old version
(*
tell application "System Events" to tell process "SystemUIServer"
  set menulets to menu bar items of menu bar 1
  repeat with aMenu in menulets
    if (description of aMenu) is "Keychain menu extra" then
      click aMenu -- we have to open it to access the menu items inside it
      --delay 0.2
      set clockMenuItems to menu items of menu 1 of aMenu
      repeat with aMenuItem in clockMenuItems
	if (title of aMenuItem) is "Lock Screen" then
	  click aMenuItem
	  exit repeat
	end if
      end repeat
    end if
  end repeat
end tell
*)
-- code from http://stackoverflow.com/questions/11081532/accesing-third-party-menu-extras-menulets-via-applescript
