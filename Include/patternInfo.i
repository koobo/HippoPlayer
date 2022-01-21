
; Hippo uses the EP_PatternInfo structure from EaglePlayer 
; to get pattern data from eagleplayers and hippo replayers.
; Some fields are used for different purposes on Hippo.

; STRUCTURE EP_Patterninfo,0
;        UWORD   PI_NumPatts             ;Overall Number of Patterns
;        UWORD   PI_Pattern              ;Current Pattern (from 0)
;        UWORD   PI_Pattpos              ;Current Position in Pattern (from 0)
;        UWORD   PI_Songpos              ;Position in Song (from 0)
;        UWORD   PI_MaxSongPos           ;Songlengh
;        UWORD   PI_BPM                  ;Beats per Minute
;        UWORD   PI_Speed                ;Speed
;        UWORD   PI_Pattlength           ;Length of Actual Pattern in Rows
;        UWORD   PI_Voices               ;Number of Voices (Patternstripes)
;        ULONG   PI_Modulo               ;Range from one note to the next
;        APTR    PI_Convert              ;Converts Note (a0)
;                                        ;to Period (D0),Samplenumber (D1),
;                                        ;Commandstring (D2) and Argument (D3)
;        LABEL   PI_Stripes              ;Address of first Patternstripe,
;                                        ;followed by the next one etc. of
;                                        ;current pattern

; PI_BPM is not used.
; Store current channel number there, so
; PI_Convert routine can check it:
PI_CurrentChannelNumber = PI_BPM

; PI_SongPos and PI_MaxSongPos are not used.
; Store note transposes for channels 1-4 here
; Used for Future Composer, BP SoundMon, THX/AHX
PI_NoteTranspose1   = PI_Songpos+0
PI_NoteTranspose2   = PI_Songpos+1
PI_NoteTranspose3   = PI_MaxSongPos+0
PI_NoteTranspose4   = PI_MaxSongPos+1

; PI_NumPatts and PI_Pattern are not used.
; Store sample transposes for channels 1-4 here:
; Used for Future Composer, BP SoundMon, THX/AHX
PI_SampleTranspose1   = PI_NumPatts+0
PI_SampleTranspose2   = PI_NumPatts+1
PI_SampleTranspose3   = PI_Pattern+0
PI_SampleTranspose4   = PI_Pattern+1

; This is set to negative if note indices are returned instead
; of period values from te PI_Convert routie:
PI_NotesOrPeriods   = PI_Speed