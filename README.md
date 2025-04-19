# Screen_Time
![Alt text](./ss.jpg)

Pre requirement:
- WIndowss OS
- Autohotkey v2/v1 installed. you can try which one worked best.

Usage: copy the script, and right click on the file -> run script.


Feature:
- The timer only tickin if the window is active/has focus.
- visual counter of specifig windows by title you can change from the source code.
- Save the log on csv file on same directory of the script.
- New app restart will resume the count (2 variable) if current date = date of last line log.
- auto save logging every hour (can change on source code).

It will visualize 5 stats and also auto logging every 1 hours:
- Total time of windows active/focus.
- Total time of windows active/focus, without afk more than 5 minutes.
- Current session time (without loses focus).
- Pause count (change window / loses focus count).
- 5 mins AFK count.

ToDo:
- can connect to database, for many usage like graphing etc.
- can make it always open, can't be closed (for monitoring in working staff).
- may usage and add functionality.
