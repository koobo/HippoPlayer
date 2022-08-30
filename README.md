# HippoPlayer

This repository contains the source code for HippoPlayer, a module player for the classic Amigas with OS 1.2 or higher. 

Original distribution is available here, from the year 2000: http://aminet.net/mus/play/hippoplayer.lha

Updated version developed later, in 2021: http://aminet.net/mus/play/hippoplayerupdate.lha

Tools used in development:
  * Originally:
    * Amiga 500 with kickstart 1.3/3.0 + a hard drive. A500/kickstart 1.2 for testing. Later, Amiga 1200/kickstart 3.0.
    * ASM-One v1.28
    * Gadget's Editor by Stefano Crimi (included without permission)
    * FImp file compressor: http://aminet.net/util/pack/imploder-4.0.lzh
  * v2.46 onwards:
    * FS-UAE on Mac, Amiga 1200 (for testing)
    * ASM-Pro v1.17
    * Shrinkler file compressor v4.7: http://aminet.net/package/dev/cross/Shrinkler
  
# Files and directories

* _puu016.s_: The main very small and clearly structured source file. 
* _keyfile0.s_: Keyfile generator.
* _playergroup0.s_: HippoPlayer.group data generator, this file includes the compressed binaries for replay routines. Used for versions older than v2.48.
* _playergroup2.s_: New format group data generator, used from version v2.48 onwards. 
* _regtext.s_: Possibly important file related to calculating checksums, see notes below
* _kpl14.s_: Protracker replay routine source precompiled.
* _kpl_: Protracker replay routine binary.
* _gadgets_: Gadget's Editor files for the user interface.
* _pl_: Replay routines for different module types with precompiled binaries.
* _eagleplayers_: Supported eagleplayer plugins, gathered from aminet.
* _scopes_: External scopes and related stuff.
* _Include_: Some needed include files.
* _gfx_: The hippo logo.

# Build instructions

The standard include files will be searched from _include:_ directory, these are not included.
Some custom includes and some others are included. Tested to compile with ASM-One v1.28, ASM-Pro v1.17, vasm v1.9. 

## Manual

Build steps:
- Assemble _puu016.s_ to get the main binary.  It should start if you have _reqtools.library_ available. 
- Build the _HippoPlayer.group_ replayer binary bundle.
  - There are binaries in *pl/bin* and *eagleplayers/bin* which need to be compressed first.
  - Execute *pl/compress_im* and *eagleplayers/compress_im* in Amiga shell to get FImp compressed data.
  - Run *pl/compress_shr* and *eagleplayers/compress_shr* on Mac/Linux to get Shrinkler compressed data.
  - Assemble file _playergroup2.s_ and save the binary. Shr-files are used by default.
  
To build the Protracker replay routine, assemble the file _kpl14.s_ and save the binary as _kpl_. To build individual replay routines, assemble one in the _pl_ dir and save the binary (or executable) into _bin_. 
**NOTE**: Most of the replay routines are saved as Amiga executables so they can be relocated properly, a few are just binary blobs of PC-relative code.

## Makefile

Edit the include paths in the makefiles to suit your environment and ensure _vasmm68k_mot_ and _shrinkler_ are in path, then run _make_.

# Notes

**All anti-cracker measures have been disabled from v2.46 onwards.**

There is a checksum macro _check_ in the main source file which is called at certain points. 
This checks if the application strings have been altered, making the app exit if
the check fails. 
There is a CRC checksum check in the file _Hippo_PS3M3.s_ which does the same as the simpler check mentioned above. It will jump into a busy loop and display colors on screen if the check fails.
