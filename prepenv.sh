#!/bin/bash

set -x
set +e

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

DL="$SCRIPTPATH/download"
TMP="$SCRIPTPATH/temp"
INC="$SCRIPTPATH/sys-include"

echo $DL
echo $TMP
echo $INC

mkdir -p "$DL"

cd "$DL" && wget -nc -nv http://aminet.net/dev/misc/NDK3.2.lha
cd "$DL" && wget -nc -nv http://aminet.net/mus/play/Eagleplayer2.04-Sources.zip
cd "$DL" && wget -nc -nv http://sun.hasenbraten.de/vasm/release/vasm.tar.gz
cd "$DL" && wget -nc -nv  --content-disposition  https://github.com/askeksa/Shrinkler/archive/refs/heads/master.zip

mkdir -p "$TMP"

cd "$TMP" && lha xfq "$DL/NDK3.2.lha"
cd "$TMP" && lha xfq "$DL/ReqToolsDev.lha"
cd "$TMP" && unzip -oq "$DL/Eagleplayer2.04-Sources.zip"
cd "$TMP" && tar xfz "$DL/vasm.tar.gz"
cd "$TMP/vasm" && make -j4 CPU=m68k SYNTAX=mot
cd "$TMP" && unzip -oq "$DL/Shrinkler-master.zip"
cd "$TMP/Shrinkler-master" && make

mkdir -p "$INC"

cp -R "$TMP/Include_I/." "$INC"

cp "$INC/lvo/exec_lib.i" "$INC/exec/"
cp "$INC/lvo/dos_lib.i" "$INC/dos/"
cp "$INC/lvo/graphics_lib.i" "$INC/graphics/"
cp "$INC/lvo/intuition_lib.i" "$INC/intuition/"
cp "$INC/lvo/wb_lib.i" "$INC/workbench/"
cp "$INC/lvo/cia_lib.i" "$INC/resources/"
cp "$INC/lvo/diskfont_lib.i" "$INC/libraries/"
cp "$INC/lvo/layers_lib.i" "$INC/graphics/"

mkdir -p "$INC/math/"

cp "$INC/lvo/mathffp_lib.i" "$INC/math/"
cp "$INC/lvo/mathtrans_lib.i" "$INC/math/"
cp "$INC/lvo/timer_lib.i" "$INC/libraries/"


cat <<EOF >> "$INC/rexx/rxslib.i" 
	 ; The library entry point offsets

	 LIBINIT
	 LIBDEF   _LVORexx	       ; Main entry point
	 LIBDEF   _LVOrxParse	       ; (private)
	 LIBDEF   _LVOrxInstruct       ; (private)
	 LIBDEF   _LVOrxSuspend        ; (private)
	 LIBDEF   _LVOEvalOp	       ; (private)

	 LIBDEF   _LVOAssignValue      ; (private)
	 LIBDEF   _LVOEnterSymbol      ; (private)
	 LIBDEF   _LVOFetchValue       ; (private)
	 LIBDEF   _LVOLookUpValue      ; (private)
	 LIBDEF   _LVOSetValue	       ; (private)
	 LIBDEF   _LVOSymExpand        ; (private)

	 LIBDEF   _LVOErrorMsg
	 LIBDEF   _LVOIsSymbol
	 LIBDEF   _LVOCurrentEnv
	 LIBDEF   _LVOGetSpace
	 LIBDEF   _LVOFreeSpace

	 LIBDEF   _LVOCreateArgstring
	 LIBDEF   _LVODeleteArgstring
	 LIBDEF   _LVOLengthArgstring
	 LIBDEF   _LVOCreateRexxMsg
	 LIBDEF   _LVODeleteRexxMsg
	 LIBDEF   _LVOClearRexxMsg
	 LIBDEF   _LVOFillRexxMsg
	 LIBDEF   _LVOIsRexxMsg

	 LIBDEF   _LVOAddRsrcNode
	 LIBDEF   _LVOFindRsrcNode
	 LIBDEF   _LVORemRsrcList
	 LIBDEF   _LVORemRsrcNode
	 LIBDEF   _LVOOpenPublicPort
	 LIBDEF   _LVOClosePublicPort
	 LIBDEF   _LVOListNames

	 LIBDEF   _LVOClearMem
	 LIBDEF   _LVOInitList
	 LIBDEF   _LVOInitPort
	 LIBDEF   _LVOFreePort

	 LIBDEF   _LVOCmpString
	 LIBDEF   _LVOStcToken
	 LIBDEF   _LVOStrcmpN
	 LIBDEF   _LVOStrcmpU
	 LIBDEF   _LVOStrcpyA	       ; obsolete
	 LIBDEF   _LVOStrcpyN
	 LIBDEF   _LVOStrcpyU
	 LIBDEF   _LVOStrflipN
	 LIBDEF   _LVOStrlen
	 LIBDEF   _LVOToUpper

	 LIBDEF   _LVOCVa2i
	 LIBDEF   _LVOCVi2a
	 LIBDEF   _LVOCVi2arg
	 LIBDEF   _LVOCVi2az
	 LIBDEF   _LVOCVc2x
	 LIBDEF   _LVOCVx2c

	 LIBDEF   _LVOOpenF
	 LIBDEF   _LVOCloseF
	 LIBDEF   _LVOReadStr
	 LIBDEF   _LVOReadF
	 LIBDEF   _LVOWriteF
	 LIBDEF   _LVOSeekF
	 LIBDEF   _LVOQueueF
	 LIBDEF   _LVOStackF
	 LIBDEF   _LVOExistF

	 LIBDEF   _LVODOSCommand
	 LIBDEF   _LVODOSRead
	 LIBDEF   _LVODOSWrite
	 LIBDEF   _LVOCreateDOSPkt     ; obsolete
	 LIBDEF   _LVODeleteDOSPkt     ; obsolete
	 LIBDEF   _LVOSendDOSPkt       ; (private)
	 LIBDEF   _LVOWaitDOSPkt       ; (private)
	 LIBDEF   _LVOFindDevice       ; (private)

	 LIBDEF   _LVOAddClipNode
	 LIBDEF   _LVORemClipNode
	 LIBDEF   _LVOLockRexxBase
	 LIBDEF   _LVOUnlockRexxBase
	 LIBDEF   _LVOCreateCLI        ; (private)
	 LIBDEF   _LVODeleteCLI        ; (private)
	 LIBDEF   _LVOCVs2i
EOF

mkdir -p "$INC/misc/"
cp "$TMP/Eagleplayer2.04/Include/misc/DeliPlayer.i" "$INC/misc/deliplayer.i"
cp "$TMP/Eagleplayer2.04/Include/misc/EaglePlayer.i" "$INC/misc/eagleplayer.i"
cd "$INC" && patch -p0 <<EOF
--- misc/eagleplayer.i	2022-11-30 11:26:35.382115229 +0100
+++ misc/eagleplayer.i	2022-11-30 11:30:17.099611433 +0100
@@ -15,7 +15,7 @@
 EAGLEPLAYER_I	SET	1
 
 	IFND	DeliTracker_Player_i
-		Include	"Misc/DeliPlayer.i"
+		Include	"misc/deliplayer.i"
 	ENDC
 
EOF
