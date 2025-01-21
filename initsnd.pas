unit InitSnd;
interface
  function InitBlaster: String;
  procedure ExitBlaster;
implementation
  uses
    TSponge,
    Detect,
    SMix;
  const
    XMSRequired   = 40;    {XMS memory required to load the sounds (KBytes) }
    SharedEMB     = false;
      {TRUE:   All sounds will be stored in a shared EMB}
      {FALSE:  Each sound will be stored in a separate EMB}

  var
    BaseIO: word; IRQ, DMA, DMA16: byte;
    i: byte;
    Counter: LongInt;
    InKey: char;
    Stop: boolean;
    Num: byte;
    Temp: integer;
    OldExitProc: pointer;

  function HexW(W: word): string; {Word}
    const
      HexChars: array [0..$F] of Char = '0123456789ABCDEF';
    begin
      HexW :=
        HexChars[(W and $F000) shr 12] +
        HexChars[(W and $0F00) shr 8]  +
        HexChars[(W and $00F0) shr 4]  +
        HexChars[(W and $000F)];
    end;

  procedure OurExitProc; far;
   {If the program terminates with a runtime error before the extended memory}
   {is deallocated, then the memory will still be allocated, and will be lost}
   {until the next reboot.  This exit procedure is ALWAYS called upon program}
   {termination and will deallocate extended memory if necessary.            }
    var
      i: byte;
    begin
      for i := 0 to 3 do
        if Sounds[i] <> nil then FreeSound(Sounds[i]);
      if SharedEMB then ShutdownSharing;
      ExitProc := OldExitProc; {Chain to next exit procedure}
    end;

  function InitBlaster: String;
    begin
      Randomize;
      writeln;
      writeln('-------------------------------------------');
      writeln('Sound Mixing Library v1.25 by Ethan Brodsky');
      if not(GetSettings(BaseIO, IRQ, DMA, DMA16))
        then
          begin
               InitBlaster := 'BLASTER variable not found.';
               exit
          end
        else
          begin
            if not(InitSB(BaseIO, IRQ, DMA, DMA16))
              then
                begin
                     InitBlaster := 'Incorrect BLASTER settings.';
                     exit
                end
          end;
      if not(InitXMS)
        then
          begin
            InitBlaster := 'Cannot init XMS. Load HIMEM.SYS!';
            Exit
          end
        else
          begin
            if GetFreeXMS < XMSRequired
              then
                begin
                  InitBlaster := fstr(XMSRequired - GetFreeXMS)+' KBytes XMS missing.';
                  Exit
                end
              else
                begin
                  if SharedEMB then InitSharing;

                  LoadSound (Sounds[0], 'BOUNCE.RAW');
                  LoadSound (Sounds[1], 'HIT.RAW');
                  LoadSound (Sounds[2], 'EXPLODE.RAW');
                  LoadSound (Sounds[3], 'INTRO.RAW');

                  OldExitProc := ExitProc;
                  ExitProc := @OurExitProc;
                end
          end;
      InitMixing;

      if DSPVersion > 2 then begin
         port [BaseIO + 4] := $00; port [BaseIO + 5] := $00;       {Reset Mixer}
         port [BaseIO + 4] := $22; port [BaseIO + 5] := $FF;       {Master both channels maximum}
         port [BaseIO + 4] := $04; port [BaseIO + 5] := $FF;       {Master both channels maximum}
         port [BaseIO + 4] := $26; port [BaseIO + 5] := $FF        {FM both channels maximum}
      end;

      InitBlaster := '';
    end;

  procedure ExitBlaster;
    begin
      StopSound(0);

      port [BaseIO + 4] := $00; port [BaseIO + 5] := $00;       {Reset Mixer}

      ShutdownMixing;
      ShutdownSB;

      for i := 0 to 3 do
        FreeSound(Sounds[i]);
      if SharedEMB then ShutdownSharing;
      writeln
    end;

  begin
  end.
