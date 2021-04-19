Some personal Irssi scripts. All of them are based on existing scripts that have been severly modified to fit my needs.

* Banaffects: creates a variable to be used in `/format` or in an Irssi theme that shows the affected nicks for a given ban. For some reason own bans do not show the affected nicks, so a separate line with the affected nicks is shown for own bans if it affects more the one nick.
* Previous nick: creates an expando variable to be used in an Irssi theme that show previous nicks when a user joins a channel. Each join is registered in a database file that is check on each join to gather previous nicks using the user's host.
It also provides two commands to save the database and to check a nick for previous aliases.
