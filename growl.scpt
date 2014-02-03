#!/usr/bin/osascript

set programName to "LucGrowlScript"
set allNotifcations to {"hans", "hans1", "hans2"}
set defaultNotifications to {"hans"}

tell application "System Events"
  set isRunning to (count of (every process whose bundle identifier is ¬
    "com.Growl.GrowlHelperApp")) > 0
end tell

if isRunning then
  tell application id "com.Growl.GrowlHelperApp"
    register as application programName ¬
      all notifications allNotifcations ¬
      default notifications defaultNotifications
    notify with name "hans1" ¬
      title "testtitle" ¬
      description "inhalt" ¬
      application name programName
  end tell
end if
