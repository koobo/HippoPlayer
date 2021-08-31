# HippoPlayer

This repository contains the source code for HippoPlayer, a module player for the classic Amigas with OS 1.2 or higher. 

Original distribution is available here: http://aminet.net/mus/play/hippoplayer.lha

Updated version developed later: http://aminet.net/mus/play/hippoplayerupdate.lha

Tools used in development:
  * Amiga 1200 with kickstart 3.0, Amiga 500 with kickstart 1.2 and 1.3.
  * ASM-One v1.28
  * fimp file compressor, available here: http://aminet.net/util/pack/imploder-4.0.lzh
  * Gadget's Editor by Stefano Crimi (included without permission)
  * FS-UAE and ASM-Pro v1.17

# Files and directories

* puu016.s: The main very small and clearly structured source file 
* keyfile0.s: Keyfile generator
* playergroup0.s: HippoPlayer.group data generator, this file includes the compressed binaries for replay routines
* regtext.s: Possibly important file related to calculating checksums, see notes below
* kpl14.s: Protracker replay routine source
* kpl: Protracker replay routine binary
* gadgets: Gadget's Editor files for the user interface
* pl: Replay routines for different module types and compressed binaries for each
* scopes: External scopes and related stuff
* Include: Some needed include files.
* gfx: The hippo logo

# Build instructions

The standard include files will be searched from _include:_ directory, these are not included.
Some custom includes and some others are included.

Tested to compile with ASM-One v1.28 and ASM-Pro v1.17. Compile the file _puu016.s_ to get 
the main binary.  It should start if you have _reqtools.library_ available. 

To build the player group file, read the _playergroup0.s_ and assemble, it will create a binary 
bundle out of the files in the _pl_-dir.

To build the Protracker replay routine, assemble the file _kpl14.s_ and write out the binary to _kpl_.

To build individual replay routines, assemble one in the _pl_-directory, write out the binary
and compress it with fimp, then re-create the group file.

# Notes

There is a checksum macro _check_ in the main source file which is called at certain points. 
This checks if the application strings have been altered, making the app exit if
the check fails. 
There is a CRC checksum check in the file _Hippo_PS3M.s_ which does the same as the simpler check mentioned above. It will jump into a busy loop and display colors on screen if the check fails.
