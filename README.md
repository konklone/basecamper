===============================================================================
               Basecamper - Command line time tracker for Basecamp
===============================================================================

Basecamper is a command line interface to log and manage your times on your
Basecamp.  It uses and extends the Basecamp API Ruby wrapper.  Perhaps in the
future it will do more than time tracking.  This time is not now.


=== Install ===

gem sources -a http://gems.github.com
sudo gem install Klondike-basecamper

=== Usage ===

Configure the tracker with your Basecamp URL, login details, and whether the
Basecamp uses SSL.  This will take a while as it caches project information 
from your Basecamp. Example:

  track configure example.clientsection.com username password true

Set a project as "current", so any times logged are assumed to be meant for
that project.

  track project "Johnson Industries"
  track project joh

Log a time by giving the duration, or by giving two times. You can optionally
specify the project to log time to, which won't change the default project.

  track log 0.25 "Log message"
  track log :15 "Log message" "Johnson Industries"
  track log 2:30p 5:30pm "Log message"
  track log 10:00 1:00 "Log message" joh

  In the last case (10:00 to 1:00), the tracker will assume that the 2nd time
  is later than the 1st one, and calculate it as 3 hours, not -9.

Log time by starting a timer.  If you don't specify a starting time, it's
assumed you're starting now.  You can optionally specify a project, which 
will change the default project.

  track start
  track start "Johnson Industries"
  track start 3:15
  track start 3:15 "Johnson Industries"

Stop the timer to log elapsed time.  If you don't specify an ending time, it's
assumed you're stopping now.

  track stop "Log message"
  track stop 5:15pm "Log message"

Pause and unpause the timer.

  track pause

Cancel all time tracking and reset counters to 0, if the timer is running or 
paused.

  track cancel

List times logged that day, including totals:

  track times

Delete a logged time from Basecamp with "undo".  If you don't specify an
ID, it's assumed you want to delete the last logged time.

  track undo
  track undo 6861536

Set a variable, such as the minute increment to round times to, or any Basecamp
authorization credentials.

  track set rounding 15

See the list of available projects to track time against.

  track projects

See whether the tracker is configured correctly, the current project, and 
if/when the timer was started or paused:

  track status

See a general or command-specific help message:

  track help
  track help log


== General ==

  * Project names can be entered as starting fragments.  For example, if
    "Johnson Industries" was the only project beginning with "joh", you could
    reference it as "joh" (e.g. "track project joh").  If more than one
    project starts with a fragment, the first one that matches is chosen.

  * Times:
    - Valid formats for times of day are:    10:00, 9:00pm, 23:30, 8, 1am, 10p
    - Invalid formats for times of day are:  1230, 1120pm, 22:00am
  
  * When calculating elapsed time, minutes are rounded up to be integers, and 
    then rounded to the nearest 15 minute increment, by default.  So a 1-minute
    time will be logged as 15, 15 as 15, 16 as 30, etc.  Use the 'set' command
    to change the increment that times are rounded to.  Times logged using the
    'log' command will not be rounded.
