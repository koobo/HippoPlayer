Hello!

Here you will find binaries with changes
done after the original development stopped.

To use, copy the files over the files that you 
have from an existing installation. 
Check out aminet for the original package.

Or, just copy HiP somewhere and HippoPlayer.group to S:, 
then run HiP. That should work if you have the 
reqtools.library installed.


Changes from v2.45 (10.1.2000) to v2.46b (15.6.2021)
----------------------------------------------------

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
Maybe this is a first tooltip on kick1.3?

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

Fixes:
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
