; started: 8/13/18 
; last edit: 9/7/22
; Album Title: Dances 
; Orchestra: finger piano, bass finger piano, balloon drums, flute, oboe, clarinet, bassoon, french horn 
; 
<CsoundSynthesizer>

<CsOptions> 
;-o dac
-o /home/prent/Music/sflib/ball4.wav -W -G -m2 -3 

; -W -G -m2 -3 
</CsOptions> 

<CsInstruments> 
 giMoved = 0 
 ; I changed the sample rate to the maximum, 24 bit audio -3 option 
 ; sr = 192000 ; my laptop audio supports this high sample rate, but not the docking station 
 sr = 44100 
 ksmps = 5; any higher than 10 and I hear clicks - use 1 for final take 
; typically save 5x processing time by increasing ksmps by 10x 
 nchnls = 2 
 instr 1 
 
; p1 is always 1 
; p2 start time 
; p3 duration 
; p4 velocity, 60-80 works best 
; p5 tone - which tone is this note - 1-214 for 31-limit diamond Partch scale - maxequal in samples.pas 6/15/06 
; p6 Octave 
; p7 voice 
; p8 stereo - pan from left = 0 to right = 16 
; p9 envelope - one of several function tables for envelopes 1 - 16 
; p10 glissando - one of several function tables to modify pitch 
; p11 upsample - use a sample higher (>0) or lower (<256) than normal 
; p12 envelope for right channel - if blank, use the left channel envelope for both channels 
; p13 2nd glissando
; p14 3rd glissando
; p15 volume
 
 if p4 = 1 goto skipVel 
 
; ; table f2 has the iSampleType values indicating type of sample 
 iSampleType table p7,2 ; from McGill.dat col 6 1: mono 2: stereo 4: Akai MDF??? 5: Gigasample 
 
 iVelTemp = (p4 > 90 ? 90 : p4) ; make sure p4 velocity not greater than 90
 iVel = (iVelTemp < 50 ? 50 : iVelTemp) ; nor less than 50 
 iVoicet = (iSampleType = 5 ? (p7 + (iVel - 60)/2) : p7) ; alter voice if SampleType is 5, otherwise don't touch it 
 iVoice = round(iVoicet) 
 
; ; table f1 has the start location of the sample tables control functions 
 iSampWaveTable table iVoice,1 ; find the location of the sample wave tables base on input p7 
 ipitch table p5, 3 ; convert note number 0-213 (or whatever the root is) to oct.fract format - generated table of note cents f 3 
 ioct = p6 
 iMIDInumber = int(12 * ipitch / .12) + 12 * ioct
 iFtableTemp table iMIDInumber, iSampWaveTable ; map midi note number to the correct ftable for that note  
 iFtable = iFtableTemp + (p11 < 128 ? p11 : p11-256) ; up or down sample by parameter 11 modulo 256 
; The next section added on 5/4/22 to ensure that a sample file out of range is not selected. 
 iLength ftlen iSampWaveTable ; length of the table (128). How many steps it could hold. 
 indx = 0 
 iLowValue table indx, iSampWaveTable 
 iHighValue table iLength, iSampWaveTable 
 loop: 
 iCurValue table indx, iSampWaveTable 
 if iFtable == iCurValue goto iFound 
 loop_lt indx, 1, iLength, loop ; this is basically a conditional goto statement 
 ; it's not in the list of valid samples. It could be too low or too high - for now reset it to what it originally was 
 ; it went too far 
 ; if the upsample went to a higher sample file, set it to the maximum in the table 
 giMoved = giMoved + 1 
 ; printf_i "upsample moved sample number out of range of available samples. requested %i ", 1, iFtable 
 if iFtable > iFtableTemp then 
 iFtable = iHighValue 
 else 
 iFtable = iLowValue 
 endif 
 ; printf_i "switched to %i. giMoved now: %d\n", 1, iFtableTemp , giMoved 
 printf_i "voice: %i. switched sample from %i to %i. Total moved so far: %i\n", 1, iVoice, iFtableTemp, iFtable, giMoved 
 iFound: 
 
 iamp = ampdb(iVel) * p15 / 5 ; volume input is 60-80 - convert to amplitude 
 
 ; End of modification 5/4/22 
 i9 = 298-p9 ; valid envelope table number are 298, 297, 296, 295 etc. - left channel 
 i12 = 298-p12 ; valid envelope table number are 298, 297, 296, 295 etc. - right channel 
 i10 = p10 ; valid glissando table number are 800+
 i13 = p13 ; valid glissando table number are 800+
 ; print p10, i10 
 kamp_l oscil iamp, 1/p3, i9 ; create an envelope from a function table for left channel 
 kamp_r oscil iamp, 1/p3, i12 ; create an envelope from a function table for right channel 
 kpan_l tablei p8/16, 4, 1,0,1 ; pan with a sine wave using f table #4 - 2st value is reduced to max 1, normalized 
 kpan_r tablei 1.0 - p8/16, 4, 1,0,1 ; inverse of kpan_l 
 ibasno table iFtable-(3+iSampWaveTable), 1 + iSampWaveTable ; get midi note number the sample was recorded at 
 icent table iFtable-(3+iSampWaveTable), 2 + iSampWaveTable ; get cents to flatten each note 
 iloop table iFtable-(3+iSampWaveTable), 3 + iSampWaveTable ; get loop or not 
 ibasoct = ibasno/12 ; find the base octave 
 ibascps = cpsoct(ibasoct+(icent/1200)) ; flatten amount in icent table 
 
 inote = cpspch(ioct + ipitch) ; note plus the decimal fraction of a note from table ipitch is in divisions of the octave
 kcps = cpspch(ioct + ipitch) ; convert oct.fract to Hz at krate 
 if i10 > 0 then
      kcpsm oscili 1, 1/p3, i10 ; create an set of shift multiplicands from table - glissandi 
      kcps1 = kcps * kcpsm ; shift the frequency by values in glissando table 
 else      
      kcps1 = kcps 
 endif
 if i13 > 0 then
      kcpsm2 oscili 1, 1/p3, i13 ; create a 2nd set of shift multiplicands from table - glissandi 2 
      kcps2 = kcpsm2 * kcps1 ; shift the frequency by values in 2nd glissando table 
 else
      kcps2 = kcps1
 endif
 ; print p5, iMIDInumber, iFtable
 if iSampleType = 4 goto akaimono 
 if iSampleType = 1 goto noloopm 
 if iloop = 0 goto noloops 
 ; Stereo with loop 
 a3,a4 loscil 1, kcps2, iFtable, ibascps; stereo sample with looping 
 goto skipstereo 
 noloops: 
 ; Stereo without looping - something has happened here between csound 6.4 and 6.11 
 a3,a4 loscil 1, kcps2, iFtable, ibascps, 0, 1, 2 ; stereo sample without looping - note that 1,2 is bogus workaround 
 goto skipstereo 
 akaimono: 
 if iloop = 0 goto noloopm 
 ; Mono with looping 
 a3 loscil 1, kcps2, iFtable, ibascps ; mono sampling with loop - 
 a4 = a3 
 goto skipstereo 
 noloopm: 
 ; Mono without looping 
 a3 loscil 1, kcps2, iFtable, ibascps,0,1,2 ; mono AIFF sample without loop 
 a4 = a3 
 
 skipstereo: 
 a1 = a3 * kamp_l 
 a2 = a4 * kamp_r 
 ; 
 outs a1 * kpan_l ,a2 * kpan_r 
 skipVel: 
 endin 

</CsInstruments>

<CsScore> 
; f3.0 0.0 256.0 -2.0 0.0 0.0104955 0.020391 0.0297513 0.0386314 0.0470781 0.0551318 0.0628274 0.0701955 0.0772627 0.0840528 0.0905865 0.0968826 0.1029577 0.1088269 0.1145036 0.1095045 0.0 0.0098955 0.0192558 0.0281358 0.0365825 0.0446363 0.0523319 0.0597 0.0667672 0.0735572 0.080091 0.086387 0.0924622 0.0983313 0.104008 0.099609 0.1101045 0.0 0.0093603 0.0182404 0.0266871 0.0347408 0.0424364 0.0498045 0.0568717 0.0636618 0.0701955 0.0764916 0.0825667 0.0884359 0.0941126 0.0902487 0.1007442 0.1106397 0.0 0.0088801 0.0173268 0.0253805 0.0330761 0.0404442 0.0475114 0.0543015 0.0608352 0.0671313 0.0732064 0.0790756 0.0847523 0.0813686 0.0918642 0.1017596 0.1111199 0.0 0.0084467 0.0165004 0.0241961 0.0315641 0.0386314 0.0454214 0.0519551 0.0582512 0.0643263 0.0701955 0.0758722 0.0729219 0.0834175 0.0933129 0.1026732 0.1115533 0.0 0.0080537 0.0157493 0.0231174 0.0301847 0.0369747 0.0435084 0.0498045 0.0558796 0.0617488 0.0674255 0.0648682 0.0753637 0.0852592 0.0946195 0.1034996 0.1119463 0.0 0.0076956 0.0150637 0.0221309 0.028921 0.0354547 0.0417508 0.0478259 0.0536951 0.0593718 0.0571726 0.0676681 0.0775636 0.0869239 0.0958039 0.1042507 0.1123044 0.0 0.0073681 0.0144353 0.0212253 0.0277591 0.0340552 0.0401303 0.0459994 0.0516761 0.0498045 0.0603 0.0701955 0.0795558 0.0884359 0.0968826 0.1049363 0.1126319 0.0 0.0070672 0.0138573 0.020391 0.0266871 0.0327622 0.0386314 0.0443081 0.0427373 0.0532328 0.0631283 0.0724886 0.0813686 0.0898153 0.0978691 0.1055647 0.1129328 0.0 0.00679 0.0133238 0.0196198 0.025695 0.0315641 0.0372408 0.0359472 0.0464428 0.0563382 0.0656985 0.0745786 0.0830253 0.091079 0.0987747 0.1061427 0.11321 0.0 0.0065337 0.0128298 0.018905 0.0247741 0.0304508 0.0294135 0.039909 0.0498045 0.0591648 0.0680449 0.0764916 0.0845453 0.0922409 0.099609 0.1066762 0.1134663 0.0 0.0062961 0.0123712 0.0182404 0.0239171 0.0231174 0.033613 0.0435084 0.0528687 0.0617488 0.0701955 0.0782492 0.0859448 0.0933129 0.1003802 0.1071702 0.1137039 0.0 0.0060751 0.0119443 0.017621 0.0170423 0.0275378 0.0374333 0.0467936 0.0556737 0.0641204 0.0721741 0.0798697 0.0872378 0.094305 0.101095 0.1076288 0.1139249 0.0 0.0058692 0.0115458 0.0111731 0.0216687 0.0315641 0.0409244 0.0498045 0.0582512 0.0663049 0.0740006 0.0813686 0.0884359 0.0952259 0.1017596 0.1080557 0.1141308 0.0 0.0056767 0.0054964 0.015992 0.0258874 0.0352477 0.0441278 0.0525745 0.0606282 0.0683239 0.0756919 0.0827592 0.0895492 0.0960829 0.102379 0.1084542 0.1143233 0.12 
; f3 0 16 2 0 1 2 3 4 5 6 7 8 9 10 11
; George Secor's Victorian rational well-temperament (based on Ellis #2) in C
; f3 0 16 -2  0 0.0091260  0.0185738  0.0292217  0.0387788  0.0486861  0.0590156  0.0684491  0.0792180  0.0886842  0.0989189  0.1089010  0.1184236 
; VRWT in D 
f3 0 16 -2 0   0.0094335  0.0202024  0.0296686  0.0399032  0.0498854  0.0594080  0.0701104  0.0795582  0.0902061  0.0997632  0.1096705  0.1200000 
; George Secor's Victorian rational well-temperament (based on Ellis #2) in C
; f3 0 16 -2 0  0.0094662  0.0197009  0.0296830  0.0392056  0.0499080 
 0.0593558  0.0700037  0.0795608  0.0894681  0.0997976  0.1092311  0.1200000 
; 0.1166383  0.1183273 ; ['51/26' '103/52'] At some point in the past I had these points also
; 
f4 0 1025 9 .25 1 0 ;The first quadrant of a sine for panning 
; The glissandi are note being dynamically generated as needed starting at 800 and going up
; Envelopes - tables 298 - 257 - grow away from the frequency alteration tables 301-536 
; autoscale all following tables to 1 
;#7 0 siz 
;#6 0 siz exp min values mid val max vals mid vals min val mid val max 
f298 0 1025 6 0 1 .5 1 1 496 1 496 1 15 .5 15 0.0 ; e0 - Attack and sustain with a relatively sharp ending 
;f297 0 1025 6 0 1 .9 1 1 486 1 486 1 25 .5 25 0.0 ; e1 - Attack and sustain with a relatively sharp ending 
f297 0 1025 6 0 4 .5 4 1 500 1 500 1 4 .5 4 0.0 ; e1 - Attack and sustain with a relatively sharp ending 
;#5 0 siz exp start take reach take reach 
; f296 0 512 5 1024 512 1 ; e2 - exponential - dead piano 
;           +-- cubic polynomials
;           | +-- start at 0
;           | | +-- take 2 to reach
;           | | | +-- reach 1/2 volumef296
;           | | | |  +-- take 2 to full volume
;           | | | |  | +-- reach full volume
;           | | | |  | | +-- take 126
;           | | | |  | | |   +-- half point
f296 0 256  6 0 2 .5 2 1 32 0.6 32 0.25 32 0.125 32 0.06 32 0.001
; f296 0 512 5 1024 512 1 ; e2 - exponential - dead piano 
;#6 0 siz exp min values mid val max val mid val min val mid val max val mid val min 
f295 0 1025 6 0 64 .5 64 1 128 .6 128 .3 128 .5 128 .6 192 .3 192 0 ; e3 big hump, small hump 
f294 0 1025 6 0 64 .15 64 .3 128 .25 128 .2 128 .6 128 1 192 .5 192 0 ; e4 small hump, big hump 
f293 0 1025 6 0 1 .5 1 1 447 .99 447 .98 64 0.5 64 0 ;e5 default woodwind envelope 
f292 0 1025 6 0 1 .5 1 1 447 0.60 447 0.20 32 0.21 32 0.22 32 0.11 32 0.00 ; e6 moving away slowly 
f291 0 1025 6 0 1 .5 1 1 128 0.60 128 0.20 256 0.15 254 0.10 128 0.05 128 0.00 ; e7 moving away faster 
;f290 0 1025 6 0 2 .5 2 1 501 .6 483 .3 18 .15 18 0 ; e8 hit and drop most 
f290 0 256  6 0 1 .5 1 1 128 .5 126 0 ; e8 hit and drop most 
f289 0 1025 6 0 1 .3 1 .6 479 .8 479 1 32 .5 32 0 ; e9 Start moderately and build, abrupt end 
f288 0 1025 6 0 64 .40 448 1 448 .6 64 0 ; e10 One long hump in the middle 
;           +-- cubic polynomials
;           | +-- start at 0
;           | | +-- take 1 to reach
;           | | | +-- reach 1/2 volume
;           | | | |  +-- take 1 to full volume
;           | | | |  | +-- reach full volume
;           | | | |  | | +-- take 368
;           | | | |  | | |   +-- almost full volume
;           | | | |  | | |   |   +-- take 368
;           | | | |  | | |   |   |    +-- almost full volume
;           | | | |  | | |   |   |    |  +-- take 16 to reach
;           | | | |  | | |   |   |    |  |   +-- 1/2 volume
;           | | | |  | | |   |   |    |  |   | +-- take 16 to reach
;           | | | |  | | |   |   |    |  |   | |  +-- zero
;           | | | |  | | |   |   |    |  |   | |  | stay there till the end - csound pads with zeros automatically
f287 0 1025 6 0 1 .5 1 1 368 .99 368 .98 16 .5 16 0  ; e11 hit and sustain 3/4 the normal length 
;               1    1   303     303     16    16
f286 0 1025 6 0 1 .5 1 1 323 .99 323 .98 16 .5 16 0  ; e12 hit and sustain 2/3 the normal length 
f285 0 1025 6 0 1 .5 1 1 248 .99 248 .98 16 .5 16 0  ; e13 hit and sustain 1/2 the normal length 
f284 0 1025 6 0 1 .5 1 1 124 .99 124 .98  4 .5  4 0  ; e14 hit and sustain 1/4 the normal length 
f283 0 1025 6 0 1 .5 1 1 84 .99 84 .98 1 .5 1 0  ; e15 hit and sustain 1/5 the normal length 
f282 0 1025 6 0 2 .2 2 .4 477 .7 479 1 32 .5 32 0 ; e16 sustain piano sound 
f281 0 1025 6 0 1 .1 1 .2 479 .6 479 1 32 .5 32 0 ; e17 sustain guitar sound 
;f280 0 1025 6 1 64 .7 64 .4 64 .4 64 .4 384 .7 352 1 16 .5 16 0 ; e18 Sharp attack, then less quiet, build to end 
;           +-- cubic polynomials
;           | +-- start at 1 loudest with no normalization
;           | | +-- take 64 to reach .7
;           | | |  +-- reach 1/2 way to target
;           | | |  |     +-- target .4
;           | | |  |     |  +-- take 64 to stay at this level
;           | | |  |     |  |  +-- target .4
;           | | |  |     |  |  |  +-- take another 64 to stay
;           | | |  |     |  |  |  |  +-- target .4
;           | | |  |     |  |  |  |  |  +-- take 368 to reach 1/2 way to full volume
;           | | |  |     |  |  |  |  |  |   +-- 1/2 volume
;           | | |  |     |  |  |  |  |  |   |  +-- take 368 to reach full volume
;           | | |  |     |  |  |  |  |  |   |  |   +-- full volume
;           | | |  |     |  |  |  |  |  |   |  |   | +-- take 16 to reach half way to zero
;           | | |  |     |  |  |  |  |  |   |  |   | |  +-- half way to zero
;           | | |  |     |  |  |  |  |  |   |  |   | |  |  +-- take 16 to reach 0
;           | | |  |     |  |  |  |  |  |   |  |   | |  |  |  +-- target zero
f280 0 1025 6 1 64 .7 64 .4 64 .4 64 .4 368 .7 368 1 16 .5 16 0 ; e18 Sharp attack, then less quiet, build to end 
f279 0 1025 6 0 1 .5 1 1.0 128 .7 228 .4 128 .4 28 .4 128 .5 128 .6 128 .3 126 0 ; e19 Moderate attack, then slightly quiet, build to end 
f278 0 1025 6 0 85 0.40 85 0.80 85 0.65 85 0.50 85 0.75 85 1.00 85 0.75 85 0.50 85 0.65 85 0.8 85 0.4 89 0.0 ; e20 3 humps - biggest in middle 
f277 0 1025 6 0 85 0.50 85 1.00 85 0.75 85 0.50 85 0.65 85 0.80 85 0.65 85 0.50 85 0.65 85 0.8 85 0.4 89 0.0 ; e21 3 humps - biggest early 
f276 0 1025 6 0 85 0.40 85 0.80 85 0.65 85 0.50 85 0.65 85 0.80 85 0.65 85 0.50 85 0.75 85 1.0 85 0.5 89 0.0 ; e22 3 humps - biggest late 
f275 0 1025 6 0 1 0.01 84 0.80 84 0.65 84 0.50 84 0.75 84 1.00 84 0.75 84 0.50 84 0.65 84 0.8 84 0.4 183 0.0 ; e24 3 humps - early biggest in middle 
f274 0 1025 6 0 1 0.01 84 1.00 84 0.75 84 0.50 84 0.65 84 0.80 84 0.65 84 0.50 84 0.65 84 0.8 84 0.4 183 0.0 ; e24 3 humps - early biggest early 
f273 0 1025 6 0 1 0.01 84 0.80 84 0.65 84 0.50 84 0.65 84 0.80 84 0.65 84 0.50 84 0.75 84 1.0 84 0.5 183 0.0 ; e25 3 humps - early biggest late 
f272 0 1025 6 0 64 .5 64 1 256 1 512 1 64 .5 64 0 ; e26 slow rise, sustain, slow drop 
; min pts mid pts max pts mid pts min pts mid pts max pts mid pts min 
;p1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 ; 
f265 0 1025 6 0 32 0.20 32 0.40 32 0.30 32 0.20 432 0.60 432 1.00 16 0.50 16 0.00 ; e33 channel one moving in gradually 
f264 0 1025 6 0 206 0.03 206 0.06 205 0.06 205 0.05 85 0.53 85 1.00 16 0.50 16 0.00 ; e34 channel 2 moving in at the end 
;#6 0 siz exp min values mid val max val mid val min val mid val max val mid val min 
f263 0 1025 6 0 2 .2 2 .6 4 .4 4 .3 500 .6 500 1 6 .5 7 0 ; e35 low bass piano inverse of h48 and above 
f262 0 1025 6 0 2 .2 2 .6 4 .4 4 .3 500 .32 500 .33 6 .2 7 0 ; e36 low bass piano inverse of h48 
f261 0 513 5 1024 384 1 ; e37- exponential - dead piano 
; end of function tables included in the .mac file. The rest are system generated to support sampling. 
; first table is a list of the function tables for the samples based on the midi number 
; +1 second is a list of midi numbers representing the base note of the sample files 
; +2 third is cent offset to flatten the note to the correct intonation 
; +3 fourth is loop or not 
; ibasno table iFtable#adj-(3+iSampWaveTable), 1 + iSampWaveTable ; get midi note number the sample was recorded at 
; icent table iFtable#adj-(3+iSampWaveTable), 2 + iSampWaveTable ; get cents to flatten each note 
; iloop table iFtable#adj-(3+iSampWaveTable), 3 + iSampWaveTable ; get loop or not 
; Orchestra: finger piano (112), bass finger piano (159), balloon drums (116, 118, 155, 156, 157, 158), flute (100), oboe (10), clarinet (77), bassoon (71), french horn (102) 
; here is where the orchestra samples and metadata go: 
f601 0 128 -17 0 605 25 606 29 607 32 608 34 609 37 610 39 611 42 612 44 613 46 614 49 615 51 616 53 617 56 618 58 619 61 620 63 621 65 622 66 623 68 624 73 625 75 626 78 627 80 628 82 629 85 
f602 0 64 -2 0  24  28  31  33  36  38  41  43  45  48  50  52  55  57  60  62  64  65  67  72  74  77  79  81  84 
f603 0 64 -2 0 +0  -4  0   0   0   0   0   0   0   0   -3  +5  +1  0   -1  +1  +4  +6  -1  -1  -1  0   -2  0   -1  
f604 0 64 -2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
f630 0 128 -17 0 634 20 635 21 636 23 637 25 638 27 639 32 640 34 641 37 642 39 643 41 644 43 645 46 646 47 647 49 648 51 649 54 650 57 651 59 652 63 653 67 654 70 655 75 
f631 0 64 -2 0  19  20  22  24  26  31  33  36  38  40  42  45  46  48  50  53  56  58  62  66  69  74 
f632 0 64 -2 0 +0  -31 -20 -16 +9  +18 +22 -11 -39 +12 +17 -33 -4  +16 +45 -31 +0  +43 -7  -1  +34 -41 
f633 0 64 -2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
f656 0 128 -17 0 660 62 
f657 0 64 -2 0  61 
f658 0 64 -2 0 -45 
f659 0 64 -2 0 0 
f661 0 128 -17 0 665 62 
f662 0 64 -2 0  61 
f663 0 64 -2 0 -45 
f664 0 64 -2 0 0 
f666 0 128 -17 0 670 56 
f667 0 64 -2 0  55 
f668 0 64 -2 0 +13 
f669 0 64 -2 0 0 
f671 0 128 -17 0 675 49 676 51 677 53 678 55 679 57 680 59 681 61 682 63 683 65 684 67 685 69 686 71 
f672 0 64 -2 0  48  50  52  54  56  58  60  62  64  66  68  70 
f673 0 64 -2 0 -55 -50 -50 -53 -31 -30 -28 -37 -41 -27 -22 -20 
f674 0 64 -2 0 1 1 1 1 1 1 1 1 1 1 1 1 
f687 0 128 -17 0 691 59 692 61 693 63 694 65 695 67 696 69 697 71 698 73 699 75 700 77 701 81 702 83 703 85 704 87 705 89 
f688 0 64 -2 0  58  60  62  64  66  68  70  72  74  76  80  82  84  86  88 
f689 0 64 -2 0 -13 +5  +3  +5  +7  +10 -12 -6  +14 +6  +4  +1  +12 +12 +16 
f690 0 64 -2 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 
f706 0 128 -17 0 710 51 711 53 712 55 713 57 714 59 715 61 716 65 717 67 718 69 719 71 720 73 721 75 722 77 723 79 724 81 725 83 726 85 727 87 
f707 0 64 -2 0  50  52  54  56  58  60  64  66  68  70  72  74  76  78  80  82  84  86 
f708 0 64 -2 0 -1  +7  +4  +3  +5  -2  -3  -2  -3  +3  +2  -1  0   +1  +5  -1  0   -2  
f709 0 64 -2 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 
f728 0 128 -17 0 732 35 733 37 734 39 735 41 736 43 737 45 738 47 739 49 740 51 741 53 742 55 743 57 744 59 745 61 746 63 747 65 
f729 0 64 -2 0  34  36  38  40  42  44  46  48  50  52  54  56  58  60  62  64 
f730 0 64 -2 0 +3  +3  +10 +2  -2  +2  +2  -2  0   -4  -12 -8  +4  -3  -3  -2  
f731 0 64 -2 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 
f748 0 128 -17 0 752 39 753 41 754 43 755 45 756 47 757 51 758 53 759 55 760 57 761 59 762 61 763 63 764 65 765 67 766 71 767 73 768 75 
f749 0 64 -2 0  38  40  42  44  46  50  52  54  56  58  60  62  64  66  70  72  74 
f750 0 64 -2 0 0   +4  0   +3  -3  -5  +10 -3  -8  -8  -5   0  +5  -3  -5  +2  +2  
f751 0 64 -2 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 
f769 0 128 -17 0 773 36 774 38 775 40 776 41 777 43 778 45 779 46 780 48 781 50 782 51 783 53 784 55 785 57 786 59 787 60 788 62 789 64 790 66 791 68 792 70 793 72 794 74 795 76 796 78 797 80 798 82 799 84 
f770 0 64 -2 0  35  37  39  40  42  44  45  47  49  50  52  54  56  58  59  61  63  65  67  69  71  73  75  77  79  81  83 
f771 0 64 -2 0 -9  -7  -6  -15 -4  -7  -9  +2  -5  -9  -5  +3  -6  +5  -14 -1  -1  +25 +6  -7  +2  -1  -2  +0  -2  -6  +11 
f772 0 64 -2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
; f799 0 256 -7 1 256 1 ; g0 = no change; 
f0 0 256 -7 1 256 1 ; this may also be created by the glissando
;t 60
f605 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/FingerP/c1.aif" 0 0 0
f606 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/FingerP/e1.aif" 0 0 0
f607 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/FingerP/g1.aif" 0 0 0
f608 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/FingerP/a1.aif" 0 0 0
f609 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/FingerP/c2.aif" 0 0 0
f610 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/FingerP/d2.aif" 0 0 0
f611 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/FingerP/f2.aif" 0 0 0
f612 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/FingerP/g2.aif" 0 0 0
f613 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/FingerP/a2.aif" 0 0 0
f614 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/FingerP/c3.aif" 0 0 0
f615 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/FingerP/d3.aif" 0 0 0
f616 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/FingerP/e3.aif" 0 0 0
f617 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/FingerP/g3.aif" 0 0 0
f618 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/FingerP/a3.aif" 0 0 0
f619 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/FingerP/c4.aif" 0 0 0
f620 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/FingerP/d4.aif" 0 0 0
f621 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/FingerP/e4.aif" 0 0 0
f622 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/FingerP/f4.aif" 0 0 0
f623 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/FingerP/g4.aif" 0 0 0
f624 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/FingerP/c5.aif" 0 0 0
f625 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/FingerP/d5.aif" 0 0 0
f626 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/FingerP/f5.aif" 0 0 0
f627 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/FingerP/g5.aif" 0 0 0
f628 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/FingerP/a5.aif" 0 0 0
f629 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/FingerP/c6.aif" 0 0 0
f634 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Bass FingerP/Piano 0 G +4.aif" 0 0 0
f635 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Bass FingerP/Piano 0 G# -30.aif" 0 0 0
f636 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Bass FingerP/Piano 0 A# -21.aif" 0 0 0
f637 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Bass FingerP/Piano 1 C -11.aif" 0 0 0
f638 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Bass FingerP/Piano 1 D +9.aif" 0 0 0
f639 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Bass FingerP/Piano 1 G +17.aif" 0 0 0
f640 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Bass FingerP/Piano 1 A +22.aif" 0 0 0
f641 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Bass FingerP/Piano 2 C -10.aif" 0 0 0
f642 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Bass FingerP/Piano 2 D -38.aif" 0 0 0
f643 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Bass FingerP/Piano 2 E +14.aif" 0 0 0
f644 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Bass FingerP/Piano 2 F# +17.aif" 0 0 0
f645 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Bass FingerP/Piano 2 A -32.aif" 0 0 0
f646 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Bass FingerP/Piano 2 A# -1.aif" 0 0 0
f647 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Bass FingerP/Piano 3 C +16.aif" 0 0 0
f648 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Bass FingerP/Piano 3 D +46.aif" 0 0 0
f649 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Bass FingerP/Piano 3 F -30.aif" 0 0 0
f650 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Bass FingerP/Piano 3 G# -1.aif" 0 0 0
f651 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Bass FingerP/Piano 3 A# +39.aif" 0 0 0
f652 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Bass FingerP/Piano 4 D -5.aif" 0 0 0
f653 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Bass FingerP/Piano 4 F# -2.aif" 0 0 0
f654 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Bass FingerP/Piano 4 A +32.aif" 0 0 0
f655 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Bass FingerP/Piano 5 D -41.aif" 0 0 0
f660 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition J/Balloon Drums/HandDrum1.wav" 0 0 0
f665 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition J/Balloon Drums/MediumHandDrum1.wav" 0 0 0
f670 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition J/Balloon Drums/SmallBalloonDrum5.wav" 0 0 0
f675 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition B/B.FLUTE W-VB/B.FLTV C3.aif" 0 0 0
f676 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition B/B.FLUTE W-VB/B.FLTV D3.aif" 0 0 0
f677 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition B/B.FLUTE W-VB/B.FLTV E3.aif" 0 0 0
f678 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition B/B.FLUTE W-VB/B.FLTV F#3.aif" 0 0 0
f679 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition B/B.FLUTE W-VB/B.FLTV G#3.aif" 0 0 0
f680 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition B/B.FLUTE W-VB/B.FLTV A#3.aif" 0 0 0
f681 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition B/B.FLUTE W-VB/B.FLTV C4.aif" 0 0 0
f682 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition B/B.FLUTE W-VB/B.FLTV D4.aif" 0 0 0
f683 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition B/B.FLUTE W-VB/B.FLTV E4.aif" 0 0 0
f684 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition B/B.FLUTE W-VB/B.FLTV F#4.aif" 0 0 0
f685 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition B/B.FLUTE W-VB/B.FLTV G#4.aif" 0 0 0
f686 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition B/B.FLUTE W-VB/B.FLTV A#4.aif" 0 0 0
f691 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition C/OBOE/OBOE A#3-f.aif" 0 0 0
f692 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition C/OBOE/OBOE C4.aif" 0 0 0
f693 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition C/OBOE/OBOE D4-f.aif" 0 0 0
f694 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition C/OBOE/OBOE E4-f.aif" 0 0 0
f695 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition C/OBOE/OBOE F#4.aif" 0 0 0
f696 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition C/OBOE/OBOE G#4-f.aif" 0 0 0
f697 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition C/OBOE/OBOE A#4-f.aif" 0 0 0
f698 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition C/OBOE/OBOE C5-f.aif" 0 0 0
f699 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition C/OBOE/OBOE D5-f.aif" 0 0 0
f700 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition C/OBOE/OBOE E5.aif" 0 0 0
f701 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition C/OBOE/OBOE G#5.aif" 0 0 0
f702 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition C/OBOE/OBOE A#5-f.aif" 0 0 0
f703 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition C/OBOE/OBOE C6-f.aif" 0 0 0
f704 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition C/OBOE/OBOE D6-f.aif" 0 0 0
f705 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition C/OBOE/OBOE E6-f.aif" 0 0 0
f710 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/B- CLARINET/CLARBB D3-f.aif" 0 0 0
f711 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/B- CLARINET/CLARBB E3-f.aif" 0 0 0
f712 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/B- CLARINET/CLARBB F#3-f.aif" 0 0 0
f713 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/B- CLARINET/CLARBB G#3-f.aif" 0 0 0
f714 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/B- CLARINET/CLARBB A#3-f.aif" 0 0 0
f715 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/B- CLARINET/CLARBB C4-f.aif" 0 0 0
f716 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/B- CLARINET/CLARBB E4-f.aif" 0 0 0
f717 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/B- CLARINET/CLARBB F#4-f.aif" 0 0 0
f718 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/B- CLARINET/CLARBB G#4-f.aif" 0 0 0
f719 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/B- CLARINET/CLARBB A#4-f.aif" 0 0 0
f720 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/B- CLARINET/CLARBB C5-f.aif" 0 0 0
f721 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/B- CLARINET/CLARBB D5-f.aif" 0 0 0
f722 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/B- CLARINET/CLARBB E5-f.aif" 0 0 0
f723 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/B- CLARINET/CLARBB F#5-f.aif" 0 0 0
f724 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/B- CLARINET/CLARBB G#5-f.aif" 0 0 0
f725 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/B- CLARINET/CLARBB A#5-f.aif" 0 0 0
f726 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/B- CLARINET/CLARBB C6-f.aif" 0 0 0
f727 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/B- CLARINET/CLARBB D6-f.aif" 0 0 0
f732 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/BASSOON/BASSOON A#1.aif" 0 0 0
f733 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/BASSOON/BASSOON C2.aif" 0 0 0
f734 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/BASSOON/BASSOON D2.aif" 0 0 0
f735 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/BASSOON/BASSOON E2.aif" 0 0 0
f736 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/BASSOON/BASSOON F#2.aif" 0 0 0
f737 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/BASSOON/BASSOON G#2.aif" 0 0 0
f738 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/BASSOON/BASS A#2.aif" 0 0 0
f739 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/BASSOON/BASS C3.aif" 0 0 0
f740 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/BASSOON/BASS D3.aif" 0 0 0
f741 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/BASSOON/BASS E3.aif" 0 0 0
f742 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/BASSOON/BASS F#3.aif" 0 0 0
f743 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/BASSOON/BASS G#3.aif" 0 0 0
f744 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/BASSOON/BASS A#3.aif" 0 0 0
f745 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/BASSOON/BASS C4.aif" 0 0 0
f746 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/BASSOON/BASS D4.aif" 0 0 0
f747 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition A/BASSOON/BASS E4.aif" 0 0 0
f752 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition B/FRENCH HORN/F.HORN D2.aif" 0 0 0
f753 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition B/FRENCH HORN/F.HORN E2.aif" 0 0 0
f754 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition B/FRENCH HORN/F.HORN F#2.aif" 0 0 0
f755 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition B/FRENCH HORN/F.HORN G#2.aif" 0 0 0
f756 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition B/FRENCH HORN/F.HORN A#2.aif" 0 0 0
f757 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition B/FRENCH HORN/F.HORN D3.aif" 0 0 0
f758 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition B/FRENCH HORN/F.HORN E3.aif" 0 0 0
f759 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition B/FRENCH HORN/F.HORN F#3.aif" 0 0 0
f760 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition B/FRENCH HORN/F.HORN G#3.aif" 0 0 0
f761 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition B/FRENCH HORN/F.HORN A#3.aif" 0 0 0
f762 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition B/FRENCH HORN/F.HORN C4.aif" 0 0 0
f763 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition B/FRENCH HORN/F.HORN D4.aif" 0 0 0
f764 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition B/FRENCH HORN/F.HORN E4.aif" 0 0 0
f765 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition B/FRENCH HORN/F.HORN F#4.aif" 0 0 0
f766 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition B/FRENCH HORN/F.HORN A#4.aif" 0 0 0
f767 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition B/FRENCH HORN/F.HORN C5.aif" 0 0 0
f768 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition B/FRENCH HORN/F.HORN D5-f.aif" 0 0 0
f773 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Baritone Guitar/H1B-19b.wav" 0 0 0
f774 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Baritone Guitar/H2C#-6.wav" 0 0 0
f775 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Baritone Guitar/H2D#-6.wav" 0 0 0
f776 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Baritone Guitar/H2E-15.wav" 0 0 0
f777 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Baritone Guitar/H2F#-2.wav" 0 0 0
f778 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Baritone Guitar/H2G#-7.wav" 0 0 0
f779 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Baritone Guitar/H2A-8.wav" 0 0 0
f780 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Baritone Guitar/H2B+3.wav" 0 0 0
f781 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Baritone Guitar/H3C#-4.wav" 0 0 0
f782 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Baritone Guitar/H3D-12.wav" 0 0 0
f783 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Baritone Guitar/H3E-11.wav" 0 0 0
f784 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Baritone Guitar/H3F#-5.wav" 0 0 0
f785 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Baritone Guitar/H3G#-6.wav" 0 0 0
f786 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Baritone Guitar/H3A#+2.wav" 0 0 0
f787 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Baritone Guitar/H3B-16.wav" 0 0 0
f788 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Baritone Guitar/H4C#+3.wav" 0 0 0
f789 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Baritone Guitar/H4D#+0.wav" 0 0 0
f790 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Baritone Guitar/H4F+24.wav" 0 0 0
f791 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Baritone Guitar/H4G+5.wav" 0 0 0
f792 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Baritone Guitar/H4A-5.wav" 0 0 0
f793 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Baritone Guitar/H4B+3.wav" 0 0 0
f794 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Baritone Guitar/H5C#+0.wav" 0 0 0
f795 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Baritone Guitar/H5D#+0.wav" 0 0 0
f796 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Baritone Guitar/H5F+0.wav" 0 0 0
f797 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Baritone Guitar/H5G+0.wav" 0 0 0
f798 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Baritone Guitar/H5A-5.wav" 0 0 0
; f799 0 0 1 "/home/prent/Dropbox/csound/McGill/Partition I/Baritone Guitar/H5B+13.wav" 0 0 0 encroches on the glissando at 799
; f0 200
f1 0 64 -2 0 601 630 656 661 666 671 687 706 728 748 769 
f2 0 64 -2 0 1 1 2 2 2 2 2 2 2 2 1
;Inst Start        Dur  Vel    Ton   Oct   Voice Stere Envlp Gliss Upsamp R-Env 2nd-gl 3rd Mult Line # ; Channel
;p1   p2           p3   p4     p5    p6    p7    p8    p9    p10   p11    p12   p13   p14  p15; Channel
i1  0.0000000000    16     1     0     0     1     8     1     0     0     1     0     0    35 ;    582     1
i1 16.0000000000    16     1     0     0     1     8     1     0     0     1     0     0    35 ;    583     1
i1 32.0000000000    16     1     0     0     1     8     1     0     0     1     0     0    35 ;    584     1
i1 48.0000000000    16     1     0     0     1     8     1     0     0     1     0     0    35 ;    585     1
i1 64.0000000000    16     1     0     0     1     8     1     0     0     1     0     0    35 ;    586     1
i1 80.0000000000    16     1     0     0     1     8     1     0     0     1     0     0    35 ;    587     1
i1 96.0000000000    16     1     0     0     1     8     1     0     0     1     0     0    35 ;    588     1
i1 112.0000000000    16     1     0     0     1     8     1     0     0     1     0     0    35 ;    589     1
i1 128.0000000000    16     1     0     0     1     8     1     0     0     1     0     0    35 ;    590     1
i1 144.0000000000    16     1     0     0     1     8     1     0     0     1     0     0    35 ;    591     1
i1 160.0000000000    16     1     0     0     1     8     1     0     0     1     0     0    35 ;    592     1
i1  0.0000000000     1    69     0     2     1     8     8     0     0     8     0     0    35 ;    582     2
i1  1.0000000000     1    69    71     2     1     8     8     0     0     8     0     0    35 ;    582     2
i1  2.0000000000     1    69   127     2     1     8     8     0     0     8     0     0    35 ;    582     2
i1  3.0000000000     1    69   175     2     1     8     8     0     0     8     0     0    35 ;    582     2
i1  4.0000000000     1    69     0     3     1     8     8     0     0     8     0     0    35 ;    582     2
i1  5.0000000000     1    69    71     3     1     8     8     0     0     8     0     0    35 ;    582     2
i1  6.0000000000     1    69   127     3     1     8     8     0     0     8     0     0    35 ;    582     2
i1  7.0000000000     1    69   175     3     1     8     8     0     0     8     0     0    35 ;    582     2
i1  8.0000000000     1    69     0     4     1     8     8     0     0     8     0     0    35 ;    582     2
i1  9.0000000000     1    69    71     4     1     8     8     0     0     8     0     0    35 ;    582     2
i1 10.0000000000     1    69   127     4     1     8     8     0     0     8     0     0    35 ;    582     2
i1 11.0000000000     1    69   175     4     1     8     8     0     0     8     0     0    35 ;    582     2
i1 12.0000000000     1    69     0     5     1     8     8     0     0     8     0     0    35 ;    582     2
i1 13.0000000000     1    69    71     5     1     8     8     0     0     8     0     0    35 ;    582     2
i1 14.0000000000     1    69   127     5     1     8     8     0     0     8     0     0    35 ;    582     2
i1 15.0000000000     1    69   175     5     1     8     8     0     0     8     0     0    35 ;    582     2
i1 16.0000000000     1    69     0     2     2     8     8     0     0     8     0     0    35 ;    583     3
i1 17.0000000000     1    69    71     2     2     8     8     0     0     8     0     0    35 ;    583     3
i1 18.0000000000     1    69   127     2     2     8     8     0     0     8     0     0    35 ;    583     3
i1 19.0000000000     1    69   175     2     2     8     8     0     0     8     0     0    35 ;    583     3
i1 20.0000000000     1    69     0     3     2     8     8     0     0     8     0     0    35 ;    583     3
i1 21.0000000000     1    69    71     3     2     8     8     0     0     8     0     0    35 ;    583     3
i1 22.0000000000     1    69   127     3     2     8     8     0     0     8     0     0    35 ;    583     3
i1 23.0000000000     1    69   175     3     2     8     8     0     0     8     0     0    35 ;    583     3
i1 24.0000000000     1    69     0     4     2     8     8     0     0     8     0     0    35 ;    583     3
i1 25.0000000000     1    69    71     4     2     8     8     0     0     8     0     0    35 ;    583     3
i1 26.0000000000     1    69   127     4     2     8     8     0     0     8     0     0    35 ;    583     3
i1 27.0000000000     1    69   175     4     2     8     8     0     0     8     0     0    35 ;    583     3
i1 28.0000000000     1    69     0     5     2     8     8     0     0     8     0     0    35 ;    583     3
i1 29.0000000000     1    69    71     5     2     8     8     0     0     8     0     0    35 ;    583     3
i1 30.0000000000     1    69   127     5     2     8     8     0     0     8     0     0    35 ;    583     3
i1 31.0000000000     1    69   175     5     2     8     8     0     0     8     0     0    35 ;    583     3
i1 32.0000000000     1    69     0     2     3     8     8     0     0     8     0     0    35 ;    584     4
i1 33.0000000000     1    69    71     2     3     8     8     0     0     8     0     0    35 ;    584     4
i1 34.0000000000     1    69   127     2     3     8     8     0     0     8     0     0    35 ;    584     4
i1 35.0000000000     1    69   175     2     3     8     8     0     0     8     0     0    35 ;    584     4
i1 36.0000000000     1    69     0     3     3     8     8     0     0     8     0     0    35 ;    584     4
i1 37.0000000000     1    69    71     3     3     8     8     0     0     8     0     0    35 ;    584     4
i1 38.0000000000     1    69   127     3     3     8     8     0     0     8     0     0    35 ;    584     4
i1 39.0000000000     1    69   175     3     3     8     8     0     0     8     0     0    35 ;    584     4
i1 40.0000000000     1    69     0     4     3     8     8     0     0     8     0     0    35 ;    584     4
i1 41.0000000000     1    69    71     4     3     8     8     0     0     8     0     0    35 ;    584     4
i1 42.0000000000     1    69   127     4     3     8     8     0     0     8     0     0    35 ;    584     4
i1 43.0000000000     1    69   175     4     3     8     8     0     0     8     0     0    35 ;    584     4
i1 44.0000000000     1    69     0     5     3     8     8     0     0     8     0     0    35 ;    584     4
i1 45.0000000000     1    69    71     5     3     8     8     0     0     8     0     0    35 ;    584     4
i1 46.0000000000     1    69   127     5     3     8     8     0     0     8     0     0    35 ;    584     4
i1 47.0000000000     1    69   175     5     3     8     8     0     0     8     0     0    35 ;    584     4
i1 48.0000000000     1    69     0     2     4     8     8     0     0     8     0     0    35 ;    585     5
i1 49.0000000000     1    69    71     2     4     8     8     0     0     8     0     0    35 ;    585     5
i1 50.0000000000     1    69   127     2     4     8     8     0     0     8     0     0    35 ;    585     5
i1 51.0000000000     1    69   175     2     4     8     8     0     0     8     0     0    35 ;    585     5
i1 52.0000000000     1    69     0     3     4     8     8     0     0     8     0     0    35 ;    585     5
i1 53.0000000000     1    69    71     3     4     8     8     0     0     8     0     0    35 ;    585     5
i1 54.0000000000     1    69   127     3     4     8     8     0     0     8     0     0    35 ;    585     5
i1 55.0000000000     1    69   175     3     4     8     8     0     0     8     0     0    35 ;    585     5
i1 56.0000000000     1    69     0     4     4     8     8     0     0     8     0     0    35 ;    585     5
i1 57.0000000000     1    69    71     4     4     8     8     0     0     8     0     0    35 ;    585     5
i1 58.0000000000     1    69   127     4     4     8     8     0     0     8     0     0    35 ;    585     5
i1 59.0000000000     1    69   175     4     4     8     8     0     0     8     0     0    35 ;    585     5
i1 60.0000000000     1    69     0     5     4     8     8     0     0     8     0     0    35 ;    585     5
i1 61.0000000000     1    69    71     5     4     8     8     0     0     8     0     0    35 ;    585     5
i1 62.0000000000     1    69   127     5     4     8     8     0     0     8     0     0    35 ;    585     5
i1 63.0000000000     1    69   175     5     4     8     8     0     0     8     0     0    35 ;    585     5
i1 64.0000000000     1    69     0     2     5     8     8     0     0     8     0     0    35 ;    586     6
i1 65.0000000000     1    69    71     2     5     8     8     0     0     8     0     0    35 ;    586     6
i1 66.0000000000     1    69   127     2     5     8     8     0     0     8     0     0    35 ;    586     6
i1 67.0000000000     1    69   175     2     5     8     8     0     0     8     0     0    35 ;    586     6
i1 68.0000000000     1    69     0     3     5     8     8     0     0     8     0     0    35 ;    586     6
i1 69.0000000000     1    69    71     3     5     8     8     0     0     8     0     0    35 ;    586     6
i1 70.0000000000     1    69   127     3     5     8     8     0     0     8     0     0    35 ;    586     6
i1 71.0000000000     1    69   175     3     5     8     8     0     0     8     0     0    35 ;    586     6
i1 72.0000000000     1    69     0     4     5     8     8     0     0     8     0     0    35 ;    586     6
i1 73.0000000000     1    69    71     4     5     8     8     0     0     8     0     0    35 ;    586     6
i1 74.0000000000     1    69   127     4     5     8     8     0     0     8     0     0    35 ;    586     6
i1 75.0000000000     1    69   175     4     5     8     8     0     0     8     0     0    35 ;    586     6
i1 76.0000000000     1    69     0     5     5     8     8     0     0     8     0     0    35 ;    586     6
i1 77.0000000000     1    69    71     5     5     8     8     0     0     8     0     0    35 ;    586     6
i1 78.0000000000     1    69   127     5     5     8     8     0     0     8     0     0    35 ;    586     6
i1 79.0000000000     1    69   175     5     5     8     8     0     0     8     0     0    35 ;    586     6
i1 80.0000000000     1    69     0     2     6     8     8     0     0     8     0     0    35 ;    587     7
i1 81.0000000000     1    69    71     2     6     8     8     0     0     8     0     0    35 ;    587     7
i1 82.0000000000     1    69   127     2     6     8     8     0     0     8     0     0    35 ;    587     7
i1 83.0000000000     1    69   175     2     6     8     8     0     0     8     0     0    35 ;    587     7
i1 84.0000000000     1    69     0     3     6     8     8     0     0     8     0     0    35 ;    587     7
i1 85.0000000000     1    69    71     3     6     8     8     0     0     8     0     0    35 ;    587     7
i1 86.0000000000     1    69   127     3     6     8     8     0     0     8     0     0    35 ;    587     7
i1 87.0000000000     1    69   175     3     6     8     8     0     0     8     0     0    35 ;    587     7
i1 88.0000000000     1    69     0     4     6     8     8     0     0     8     0     0    35 ;    587     7
i1 89.0000000000     1    69    71     4     6     8     8     0     0     8     0     0    35 ;    587     7
i1 90.0000000000     1    69   127     4     6     8     8     0     0     8     0     0    35 ;    587     7
i1 91.0000000000     1    69   175     4     6     8     8     0     0     8     0     0    35 ;    587     7
i1 92.0000000000     1    69     0     5     6     8     8     0     0     8     0     0    35 ;    587     7
i1 93.0000000000     1    69    71     5     6     8     8     0     0     8     0     0    35 ;    587     7
i1 94.0000000000     1    69   127     5     6     8     8     0     0     8     0     0    35 ;    587     7
i1 95.0000000000     1    69   175     5     6     8     8     0     0     8     0     0    35 ;    587     7
i1 96.0000000000     1    69     0     2     7     8     8     0     0     8     0     0    35 ;    588     8
i1 97.0000000000     1    69    71     2     7     8     8     0     0     8     0     0    35 ;    588     8
i1 98.0000000000     1    69   127     2     7     8     8     0     0     8     0     0    35 ;    588     8
i1 99.0000000000     1    69   175     2     7     8     8     0     0     8     0     0    35 ;    588     8
i1 100.0000000000     1    69     0     3     7     8     8     0     0     8     0     0    35 ;    588     8
i1 101.0000000000     1    69    71     3     7     8     8     0     0     8     0     0    35 ;    588     8
i1 102.0000000000     1    69   127     3     7     8     8     0     0     8     0     0    35 ;    588     8
i1 103.0000000000     1    69   175     3     7     8     8     0     0     8     0     0    35 ;    588     8
i1 104.0000000000     1    69     0     4     7     8     8     0     0     8     0     0    35 ;    588     8
i1 105.0000000000     1    69    71     4     7     8     8     0     0     8     0     0    35 ;    588     8
i1 106.0000000000     1    69   127     4     7     8     8     0     0     8     0     0    35 ;    588     8
i1 107.0000000000     1    69   175     4     7     8     8     0     0     8     0     0    35 ;    588     8
i1 108.0000000000     1    69     0     5     7     8     8     0     0     8     0     0    35 ;    588     8
i1 109.0000000000     1    69    71     5     7     8     8     0     0     8     0     0    35 ;    588     8
i1 110.0000000000     1    69   127     5     7     8     8     0     0     8     0     0    35 ;    588     8
i1 111.0000000000     1    69   175     5     7     8     8     0     0     8     0     0    35 ;    588     8
i1 112.0000000000     1    69     0     2     8     8     8     0     0     8     0     0    35 ;    589     9
i1 113.0000000000     1    69    71     2     8     8     8     0     0     8     0     0    35 ;    589     9
i1 114.0000000000     1    69   127     2     8     8     8     0     0     8     0     0    35 ;    589     9
i1 115.0000000000     1    69   175     2     8     8     8     0     0     8     0     0    35 ;    589     9
i1 116.0000000000     1    69     0     3     8     8     8     0     0     8     0     0    35 ;    589     9
i1 117.0000000000     1    69    71     3     8     8     8     0     0     8     0     0    35 ;    589     9
i1 118.0000000000     1    69   127     3     8     8     8     0     0     8     0     0    35 ;    589     9
i1 119.0000000000     1    69   175     3     8     8     8     0     0     8     0     0    35 ;    589     9
i1 120.0000000000     1    69     0     4     8     8     8     0     0     8     0     0    35 ;    589     9
i1 121.0000000000     1    69    71     4     8     8     8     0     0     8     0     0    35 ;    589     9
i1 122.0000000000     1    69   127     4     8     8     8     0     0     8     0     0    35 ;    589     9
i1 123.0000000000     1    69   175     4     8     8     8     0     0     8     0     0    35 ;    589     9
i1 124.0000000000     1    69     0     5     8     8     8     0     0     8     0     0    35 ;    589     9
i1 125.0000000000     1    69    71     5     8     8     8     0     0     8     0     0    35 ;    589     9
i1 126.0000000000     1    69   127     5     8     8     8     0     0     8     0     0    35 ;    589     9
i1 127.0000000000     1    69   175     5     8     8     8     0     0     8     0     0    35 ;    589     9
i1 128.0000000000     1    69     0     2     9     8     8     0     0     8     0     0    35 ;    590    10
i1 129.0000000000     1    69    71     2     9     8     8     0     0     8     0     0    35 ;    590    10
i1 130.0000000000     1    69   127     2     9     8     8     0     0     8     0     0    35 ;    590    10
i1 131.0000000000     1    69   175     2     9     8     8     0     0     8     0     0    35 ;    590    10
i1 132.0000000000     1    69     0     3     9     8     8     0     0     8     0     0    35 ;    590    10
i1 133.0000000000     1    69    71     3     9     8     8     0     0     8     0     0    35 ;    590    10
i1 134.0000000000     1    69   127     3     9     8     8     0     0     8     0     0    35 ;    590    10
i1 135.0000000000     1    69   175     3     9     8     8     0     0     8     0     0    35 ;    590    10
i1 136.0000000000     1    69     0     4     9     8     8     0     0     8     0     0    35 ;    590    10
i1 137.0000000000     1    69    71     4     9     8     8     0     0     8     0     0    35 ;    590    10
i1 138.0000000000     1    69   127     4     9     8     8     0     0     8     0     0    35 ;    590    10
i1 139.0000000000     1    69   175     4     9     8     8     0     0     8     0     0    35 ;    590    10
i1 140.0000000000     1    69     0     5     9     8     8     0     0     8     0     0    35 ;    590    10
i1 141.0000000000     1    69    71     5     9     8     8     0     0     8     0     0    35 ;    590    10
i1 142.0000000000     1    69   127     5     9     8     8     0     0     8     0     0    35 ;    590    10
i1 143.0000000000     1    69   175     5     9     8     8     0     0     8     0     0    35 ;    590    10
i1 144.0000000000     1    69     0     2    10     8     8     0     0     8     0     0    35 ;    591    11
i1 145.0000000000     1    69    71     2    10     8     8     0     0     8     0     0    35 ;    591    11
i1 146.0000000000     1    69   127     2    10     8     8     0     0     8     0     0    35 ;    591    11
i1 147.0000000000     1    69   175     2    10     8     8     0     0     8     0     0    35 ;    591    11
i1 148.0000000000     1    69     0     3    10     8     8     0     0     8     0     0    35 ;    591    11
i1 149.0000000000     1    69    71     3    10     8     8     0     0     8     0     0    35 ;    591    11
i1 150.0000000000     1    69   127     3    10     8     8     0     0     8     0     0    35 ;    591    11
i1 151.0000000000     1    69   175     3    10     8     8     0     0     8     0     0    35 ;    591    11
i1 152.0000000000     1    69     0     4    10     8     8     0     0     8     0     0    35 ;    591    11
i1 153.0000000000     1    69    71     4    10     8     8     0     0     8     0     0    35 ;    591    11
i1 154.0000000000     1    69   127     4    10     8     8     0     0     8     0     0    35 ;    591    11
i1 155.0000000000     1    69   175     4    10     8     8     0     0     8     0     0    35 ;    591    11
i1 156.0000000000     1    69     0     5    10     8     8     0     0     8     0     0    35 ;    591    11
i1 157.0000000000     1    69    71     5    10     8     8     0     0     8     0     0    35 ;    591    11
i1 158.0000000000     1    69   127     5    10     8     8     0     0     8     0     0    35 ;    591    11
i1 159.0000000000     1    69   175     5    10     8     8     0     0     8     0     0    35 ;    591    11
i1 160.0000000000     1    69     0     2    11     8     8     0     0     8     0     0    35 ;    592    12
i1 161.0000000000     1    69    71     2    11     8     8     0     0     8     0     0    35 ;    592    12
i1 162.0000000000     1    69   127     2    11     8     8     0     0     8     0     0    35 ;    592    12
i1 163.0000000000     1    69   175     2    11     8     8     0     0     8     0     0    35 ;    592    12
i1 164.0000000000     1    69     0     3    11     8     8     0     0     8     0     0    35 ;    592    12
i1 165.0000000000     1    69    71     3    11     8     8     0     0     8     0     0    35 ;    592    12
i1 166.0000000000     1    69   127     3    11     8     8     0     0     8     0     0    35 ;    592    12
i1 167.0000000000     1    69   175     3    11     8     8     0     0     8     0     0    35 ;    592    12
i1 168.0000000000     1    69     0     4    11     8     8     0     0     8     0     0    35 ;    592    12
i1 169.0000000000     1    69    71     4    11     8     8     0     0     8     0     0    35 ;    592    12
i1 170.0000000000     1    69   127     4    11     8     8     0     0     8     0     0    35 ;    592    12
i1 171.0000000000     1    69   175     4    11     8     8     0     0     8     0     0    35 ;    592    12
i1 172.0000000000     1    69     0     5    11     8     8     0     0     8     0     0    35 ;    592    12
i1 173.0000000000     1    69    71     5    11     8     8     0     0     8     0     0    35 ;    592    12
i1 174.0000000000     1    69   127     5    11     8     8     0     0     8     0     0    35 ;    592    12
i1 175.0000000000     1    69   175     5    11     8     8     0     0     8     0     0    35 ;    592    12
t0     60
</CsScore>
</CsoundSynthesizer>

;