
*=======================================================================*
*                                                                       *
*       C64 MUSIC EMULATOR FOR AMIGA                                    *
*       (C) 1990-1994 HÅKAN SUNDELL & RON BIRK                          *
*                                                                       *
*=======================================================================*

This version of playsid.library provides three different sound
output methods:

- The original SID emulation by Per Sundell & Ron Birk
- The reSID emulation engine by Dag Lem
- SIDBlaster-USB, a device that uses a SID chip for sound

To use, copy "playsid.library" into LIBS:, replacing the original
version. By default it will use the original SID emulation mode.

To select the output mode, set the environment variable "PlaySIDMode"
to a number, eg. 'setenv PlaySIDMode 1', where the numbers are:
0 = Original
1 = reSID 6581
2 = reSID 8580
3 = SIDBlaster USB

Applications using "playsid.library" will automatically be enhanced.
These are at least: HippoPlayer, DeliTracker, Magic64, Frodo. 

HippoPlayer also provides additional integration in the user interface: output
mode selection, sampling mode, filter and volume setting, scope display. With
Hippo the environment variable setting is not used.

If you're running kickstart 1.3 or 68000 you should use the original 
library version.


reSID
-----

reSID provides an accurate, cycle exact emulation of both the 6581 
and the 8580 SID chips, with filter support. 

reSID is very heavy on the CPU. Depending on the tune, it will
use about half of the available CPU power on an A1200 with a 50MHz 68060.
An FPU is not required.

Samples will not be heard. This is because the samples have typically 
had some special handling in SID players and emulators. The 
playsid.library sample handling is not usable with reSID.

Multispeed tunes are supported, as well as stereo SIDs (2SIDs). 
A 50MHz 68060 can play most of these with filters enabled.

Sometimes the sound output may be noisy. This is sampling noise, 
result of the reSID "fast sampling" method. A few other sampling
modes are also available to reduce the noise. These are heavier and 
may not run on a 50 MHz 68060. The "Oversample 2x" should be fine
with 50 MHz.

If the tune being played and/or the chosen sampling mode is too 
heavy, data will be skipped to avoid slowing down the system too much.
This will cause the sound to be distorted.

The filters can be enabled or disabled. The main filter is responsible
for the distinctive SID sound. The external filter does not have
much of an audible effect, it may reduce the sampling noise somewhat.

The sound is output using the Paula 14-bit mode.

'setenv PlaySIDDebug 1' will enable reSID raster bar CPU measurement visual, 0
will disable it.

reSID v0.16 Amiga port and integration by K-P


SIDBlaster
----------

SIDBlaster is a USB device that can utilize an actual SID chip
and allow playback using it, providing a truly authentic sound. 

In addition to some extra hardware and USB connectivity, 
the Poseidon USB stack needs to be installed. 

Samples will not be heard. The playsid.library sample handling 
is not usable with SIDBlaster.

SIDBlaster driver and integration by Erique


Changelog
---------
- 2022-10: Initial version, reSID v0.16
- 2022-11: SIDBlaster support, new reSID sampling modes, 
           reSID speed optimizations, some fixes
- 2022-11-19: Fix bug where playback would get stuck for a while, 
              example tune: JCH/Hawaii
- 2023-02   - Added support for 2SIDs, stereo SIDs with 6 audio
  v1.4        channels. This works only in reSID mode, and takes about
              double the amount of CPU compared to ordinary SIDs.
            - Full support for multispeed tunes added, earlier only
              speeds up to four worked properly.
            - A bunch of reSID speed optimizations, enabling 
              the heavier Oversample x2 and x3 modes to with most
              tunes on 50MHz 060. About 20% faster compared
              to previous.
- 2023-03   - Add AHI support for reSID output.
  v1.5      - Fix hang and crash bug which could happen when 
              starting playback.
            - Fix another crash bug related to earlier reSID  
              modifications.
