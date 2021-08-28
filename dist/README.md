Hello!

Here you will find binaries with changes
done after the original development stopped.

To use, copy the files over the files that you 
have from an existing installation. 
Check out aminet for the original package.

Or, just copy HiP somewhere and HippoPlayer.group to S:, 
then run HiP. That should work if you have the 
reqtools.library installed.

# Changes from v2.46b (15.6.2021) to v2.47b (?.?.2021) *NOT AVAILABLE YET*

Here's another version, since Amiga is fun :-)
In this one: new exotic music formats, favorite modules feature,
enhanced kickstart 1.3 support. Check out the details below.

## New fixes:
- Fixed two serious crash bugs introduced in v2.46b. When starting to play the next
  module (especially by double clicking) Hippo could get confused and crash.
  These problems were very likely to happen especially on OS 3.2.
- Tooltip fixes for buttons *Del*, *Pr*. Also increase tooltip delay a little bit.
- Fix the case where HiP is given modules without absolute path via command line
  or via icon launch (eg. *DefIcons*), and the added files can't be opened. Now works.
- The default unzip command in prefs was changed to *c:unzip >nil: -jo "%s"*, 
  this allows opening zipped modules where the module is within a subdirectory.
  Previously such modules would not be found from the zip file.

## New (very old) known bugs:
- _VisualPrefs_ tool can be used to adjust window bottom and top border, and window and screen title bar heights. Hippo can get confused and displays some extra vertical space below the window title bar when these are adjusted. 
  
## New supported music formats:

- Medley Sound and Future Player
  - The author of these and the superb Imploder themes Paul van der Valk has recently passed away. His sound was truly unique!
  - Future Player replayer adapted from Wanted Team EaglePlayer sources.
  - Medley Sound replayer ripped from Imploder 4.
- Ben Daglish
  - Also adapted from EaglePlayer sources by Wanted Team.
- DeliTracker Custom
  - There are hundreds of these modules available, with varying quality. Many modules work fine but some behave badly. They may do illegal memory accesses or crash spectacularly. The same happens also when played with DeliTracker. 
  - One version of _Lemmings_ tries to do file accesses to load separate sample files, this is not supported by Hippo and will probably crash.
  - A few modules do not get recognized as the important bits are not close enough to the start of the file.
  - Minor issue: Some modules display the subsong range in the titlebar so that the first song is #2 instead of #1. 
- Beathoven Synthesizer
- Game Music Creator (*Jumping Jack'Son!*)
- Digital Mugician
- PumaTracker
- SidMon 2 (SidMon 1 is already supported)
 
## New features:

- _Prefs_ option for toggling button tooltips on and off. By default it is on.

- Support for _gzipped_ archives. (This was once supported but was removed at some point.)

- Recursive subdirectory scan when adding modules is now supported on kickstart 1.3.
  
  It has been possible to select directories in the filerequester when adding files.
  These directories would be scanned recursively to add all the files inside.
  This has only worked on kickstart 2.0 or newer until now, due to the usage of a kickstart 2.0 DOS-library specific function.
  
  Previously on older kickstarts only the top level files of the selected directories were added.
  
- New ARexx commands *CHOOSEPREV* and *CHOOSENEXT*. These work similarly as when the user presses arrow up and down to choose a module in the list. *GET VERS* command returns the app version. *GET VOLU* returns the current volume setting.

- Favorite modules! You can now right click on a module to favorite it. Favorite
  modules are displayed in **bold font**. To view the favorites, there's a new button
  on top of the filebox slider gadget to click. It switches between normal listview
  and favorites view.

  Favorites are automatically saved after the user has been idle for a while,
  or when exiting the program, to file "**S:HippoFavorites.prg**".

  To enable this feature toggle the _Favorite modules_ switch on the
  _General_ subpage in prefs. This feature probably doesn't make any sense if you are using floppies.
  
  
# Changes from v2.45 (10.1.2000) to v2.46b (15.6.2021)

There was an actual user request (by daxb) in the English Amiga Board 
a few years back to remove the module list size restriction.
This turned out to be a fun challenge. The code assumed
the module list index to be a positive 16-bit number, and
also used the same index with some magic values to mean 
a few things. There were a lot of places to change to make this work. 
The restriction is now at 0x1ffff (131071), which is a crazy amount.

Such a large list eats a lot of memory and is quite slow to 
process, as it is a doubly linked list. List iteration
operations needed some optimization to be usable on an A500.
(Next challenge: get rid of the linked list approach.)

Random play bookkeeping previously worked only for lists of up 
to 8192 (0x1fff) modules, this limit is now removed as well.

I decided to challenge myself with some UI changes. The main window
buttons are quite cryptic with both left and right mouse button actions,
which I have conveniently forgot about. I implemented a modern feeling
tooltip which will pop up a helpful text for each button. 
Maybe this is the first tooltip on kick1.3?

Right clicks on the buttons don't really work like
left clicks. I don't know why the past-me left them like that, 
they're ugly and non-user friendly that way. I changed
the buttons to have a proper visualization for right clicks as well.

I also added a few wait pointers to places with long running operations.

Another thing that motivated me to do some hippo coding was the realization
that the multitasking approaches used in HiP are bad.
At the time I had no idea about thread safe programming. This could
lead to some random crashes at times due to bad luck with timing.

Exec provides semaphores to protect shared data,
so these were added to a lot of places. Some safety regarging
interrupts relying on some data was also added. 
External applications using the HippoPort still use all data freely.

## Fixes:
- Extraneous requester pop up removed when loading TFMX modules.
- Fixed a case where unpacked modules were not identified as modules, or 
  a non-module file was identified as a valid module (due to badly initialized
  memory).
- A memory leak removed from the file requester.
- Memory usage is lowered in several situations:
  - Random play bookkeeping now uses a dynamically allocated table.
  - Each modulelist entry is now about 30 bytes smaller, for 1000 modules that means memory savings of
    about 30 kB! :-)
  - Unnecessary library loading removed from startup. This also speeds up starting on slow machines.
- Improved stability
  - Starting and stopping playback and loading modules like a crazy person is now not so 
    prone to crashing. This is achieved by adding exclusive access checks to
    module data and module list in several places (see above).
- Other general bad behaviour removed from many places, not directly visible to user.
- May survive low memory situations better when loading module programs or adding files.
- A bunch of smaller fixes, such as enforcer hit removals at a few places.
- Code refactoring! It's still quite a mess in many places.
