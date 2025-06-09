
*=======================================================================*
*                                                                       *
*       C64 MUSIC EMULATOR FOR AMIGA                                    *
*       (C) 1990-1994 H?KAN SUNDELL & RON BIRK                          *
*                                                                       *
*=======================================================================*

This version of playsid.library provides several different sound
output methods:

- The original SID emulation by Per Sundell & Ron Birk (kick 1.3, 68000)
- The reSID emulation engine by Dag Lem (68040/060 or similar)
- SIDBlaster-USB, a device that uses a SID chip for sound (kick 2.0+, 68020)
- ZorroSID, a zorro card with a SID chip (68000)
- USBSID-Pico, a device with support for dual/triple/quad SIDs (kick 2.0+, 68020)

To use, copy "playsid.library" into LIBS:, replacing the original
version. By default it will use the original SID emulation mode.

Applications using "playsid.library" will automatically be enhanced.
These are at least: PlaySID, HippoPlayer, DeliTracker, Magic64, Frodo. 
HippoPlayer also provides additional integration in the user interface.


Configuring with environment variables
--------------------------------------
- Set operating mode: normal/classic mode, reSID 6581, reSID 8580, 
  reSID auto detect, SIDBlaster USB, ZorroSID or USBSID-Pico
  Variable: "PlaySIDMode", values: "Norm,6581,8580,Auto,Sidb,Zorr,UsbP"

- Set reSID mode: normal, oversample 2x, 3x, 4x
  Variable: "PlaySIDreSIDMode", values: "Norm,Ovs2,Ovs3,Ovs4"

- Enable: reSID AHI output by specifying the AHI mode identifier:
  Variable: "PlaySIDreSIDAHI", value: 8-digit hex number

- Set reSID output volume boost
  Variable: "PlaySIDreSIDBoost", values: "0,1,2,3,4"

- Toggle reSID filter settings, internal on, internal+external on, both off
  Variable: "PlaySIDreSIDFilter", values: "onIn,on,off"

- Toggle reSID debug colors:
  Variable: "PlaySIDDebug", values: "on,off"

- Set ZorroSID address:
  Variable: "PlaySIDZorroSID", value: 8-digit hex number, 
  example: "00EE0000"

reSID
-----

reSID provides an accurate, cycle exact emulation of both the 6581 
and the 8580 SID chips, with filter support. 

reSID is very heavy on the CPU. CPU usage depends on the tune
and settings. 68060@50MHz should work fine, 68040@40MHz 
is also usable with some tunes and settings. An FPU is not required.

In reSID mode the library is able to play stereo SIDs (2SID),
outputting six SID channels, and 3SIDs with 9 SID channels.

Sometimes the sound output may be noisy. This is sampling noise, 
result of the reSID "fast sampling" method. A few other sampling
modes are also available to reduce the noise. 

If the tune being played and/or the chosen sampling mode is too 
heavy, data will be skipped to avoid slowing down the system too much.
This will cause the sound to be distorted.

The filters can be enabled or disabled. The main filter is responsible
for the distinctive SID sound. The external filter does not have
much of an audible effect, it may reduce the sampling noise somewhat.

The sound is output using the Paula 14-bit mode, except in 3SID
mode where SID 2 and SID 3 are output in 8-bit mode. AHI output 
is available, too.

reSID v0.16 Amiga port and integration by K-P


SIDBlaster / USBSID-Pico
------------------------

SIDBlaster & USBSID-Pico are USB devices that can utilize an actual SID chip
and allow playback using it, providing a truly authentic sound. 

2SID/3SID playback is possible by connecting multiple devices and SIDs.

In addition to some extra hardware and USB connectivity, 
the Poseidon USB stack needs to be installed. 

Digisamples will not be heard. The playsid.library sample handling 
is not usable with SIDBlaster/USBSID-Pico.

USB driver and integration by eriQue


ZorroSID
--------

ZorroSID is a zorro compatible card with a SID chip.
The card address can be configured with an env variable,
the default address is $EE0000.

For an MMU enabled system you need to configure the
memory range properly. If you have Thor's MMU libraries
and related tools installed this can be done for example by adding
the following line to file ENVARC:MMU-Configuration:
"SetCacheMode from 0xEE0000 size 0x10000 valid cacheinhibit io"

.. or by running the shell command:
"MuSetCacheMode from 0xEE0000 size 0x10000 valid cacheinhibit io"

You can also use the EnableSID and DisableSID commands 
found in the FrodoV2.4.lha archive on aminet.

Digisamples will not be heard. The playsid.library sample handling 
is not usable with ZorroSID.


Changelog
---------
- 2022-10:  - Initial version, reSID v0.16
- 2022-11:  - SIDBlaster support, new reSID sampling modes, 
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
- 2023-11   - Improved SIDBlaster support, faster and more stable.
  v1.6        Lower CPU requirement than before, works on 68020.
            - Support for digisample playback with reSID, as 
              heard in "Skate or Die" or "Arkanoid", for example.
              NOTE: Digisamples not supported in AHI mode.
            - Fix volume setting so that it also changes the 
              digisample volume in the original mode.
            - Add support for reSID volume boost.
            - Library compatible with kick 1.3.
            - Allow "Oversample" modes to work with AHI.
            - Enhanced environment variables for more control.
- 2024-05   - Support for 3SID files with 9 SID channels, 
  v1.7        in reSID mode. In Paula mode SID1 uses 14-bit out, 
              SIDs 2 and 3 use 8-bit outputs.        
            - Some reSID speed optimizations, about 18% faster on
              68060 than before. 
- 2025-02   - Support for USBSID-Pico
  v1.9      - Support for 2SID and 3SID via multiple SIDBlasters
            - Support for ZorroSID
            - Fix reSID Auto mode not selecting the chip 
              version correctly.
            - reSID compatibility improvements, helps at least with:
               - Aliens by Paul Clansey 
               - Vangelis Is Not Dead by Martin Demsky
               - Timewarp Spheres 2SID by F7sus4
- 2025-05   
  v1.10     - Allow configuring ZorroSID base address