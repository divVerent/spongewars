uses TSponge, Game, KojakVGA, SMix, InitSnd, SpEdit, DOS;

var _Checksum: byte;

var _Checksum_b: array [0..16383] of byte;

procedure Checksum (fn: string);
var f: file;
    i: integer;
    imax: integer;
begin
     if fn = '' then
     begin
          _Checksum := 0;
          exit;
     end;
     assign (f, fn);
     reset (f, 1);
     imax := 1;
     while imax >= 0 do
     begin
          blockread (f, _Checksum_b, 16384, imax);
          imax := imax - 1;
          for i := 0 to imax do
              _Checksum := _Checksum shl 1 + _Checksum shr 7 + _Checksum_b[i];
     end;
     close (f);
end;


function SearchFile (S: String): String;
var P,T: String;
    f: file;
begin
     P := GetEnv ('PATH');
     while P <> '' do begin
           T := Copy (P, 1, Pos(';', P)-1);
           P := Copy (P, Pos(';', P)-1, Byte(P[0])-Pos(';', P));
           If T[Byte(T[0])] <> '\' then T := T + '\';
           T := T + S;
           assign (f, T);
           reset (f, 1);
           if IOResult = 0 then begin
              close (f);
              SearchFile := T;
              exit
           end
     end;
     repeat
           writeln ('Couldn''t find '+S+'.');
           write ('Please enter full location: ');
           readln (T);
           if T = '' then halt;
           If T[Byte(T[0])] <> '\' then T := T + '\';
           T := T + S;
           assign (f, T);
           reset (f, 1);
           if IOResult = 0 then begin
              close (f);
              SearchFile := T;
              exit
           end
     until false
end;


procedure Remove (X1, Y1, X2, Y2: Word);
var x, y: integer;

function Colour: Byte;

function zigzag (x: integer): byte;
begin
     if (x and 7) >= 5 then zigzag := (8 - x and 7) else zigzag := x and 7
end;

begin
     Colour := 25 * zigzag ((x-y+4) div 2) + 1 * zigzag (y+4) + 5 * zigzag ((x+y+4) div 3)
end;

begin
     for y := Y1 to Y2 do
         for x := X1 to X2 do
             putpixel (x, y, 64 + Colour)
end;

procedure ClearScreen;
begin
     Remove (0, 0, 319, 199)
end;


var x, pnum, ROOFdirt, teams: byte;
    b: pointer;
    mywall, myROOF, mySound: boolean;
    t: text;
    s: string;
    c: char;
    fr: fonttype;

const walls: array [boolean] of string [8] = ('BOUNCING', 'WRAPPING');
      ROOFs: array [boolean] of string [8] = ('BOUNCING', 'NO ROOF');
      SOUNDs: array [boolean] of string [8] = ('NO SOUND','SOUND');

begin
     Checksum ('');
     Checksum ('bounce.wav');
     Checksum ('bounce.raw');
     Checksum ('hit.wav');
     Checksum ('hit.raw');
     Checksum ('intro.wav');
     Checksum ('intro.raw');
     Checksum ('explode.wav');
     Checksum ('explode.raw');
     Checksum ('sponge.pcx');

     Dec (_Checksum, 143);

     if _Checksum <> 0 then begin
        writeln ('Invalid checksum! (', _Checksum, ' instead of 0)');
        writeln ('Please reinstall Sponge Wars. Maybe you have changed a file?');
        writeln ('If this doesn''t help, mail to divVerent+sponge@gmail.com');
        writeln ('for a correct SpongeWars distribution.');
        writeln ('=== please wait 15 seconds... ===');
        delay (15000);
     end;

     if GetOptionString ('?') = '+' then begin
        writeln ('Help for Sponge Wars:');
        writeln ('  SPONGE.EXE [params]');
        writeln ('    /b-:      don''t check for SoundBlaster');
        writeln ('    /a-:      don''t check for AdLib');
        writeln ('    /s-:      don''t use Speaker');
        writeln ('    /dcreate: create a boot disk for drive A:');
        writeln;
        exit
     end;
     if GetOptionString ('d') = 'create' then begin
        writeln ('Insert a HD disk in drive A:');
        writeln ('All files on it will get erased!');
        repeat
              write ('Press [Y] to proceed or [N] to cancel... ');
              c := readkey;
              writeln (c)
        until c in ['y','Y','n','N'];
        if c in ['n','N'] then halt;
        swapvectors;
            exec (SearchFile('FORMAT.COM'),'A: /S /U /AUTOTEST');
        swapvectors;
        if DosError = 8 then begin
           writeln ('Out of memory!')
        end else
        if dosexitcode <> 0 then begin
           writeln ('Couldn''t format disk successfully.');
           writeln ('Boot disk creation aborted.')
        end else begin
           assign (t, 'A:\CONFIG.SYS');
           rewrite (t);
           if ioresult <> 0 then begin
              writeln ('Couldn''t create CONFIG.SYS.');
              writeln ('Boot disk creation aborted.')
           end else begin
              writeln ('Searching for HIMEM.SYS...');
              writeln (t, 'DEVICE='+SearchFile('HIMEM.SYS'));
              writeln ('Searching for EMM386.EXE...');
              writeln (t, 'DEVICE='+SearchFile('EMM386.EXE')+' NOEMS D=48');
              writeln (t, 'DOS=HIGH');
              writeln (t, 'DOS=UMB');
              if DosVersion AND 255 >= $07 then writeln (t, 'DOS=SINGLE');
              close (t);
              assign (t, 'A:\AUTOEXEC.BAT');
              rewrite (t);
              if ioresult <> 0 then begin
                 writeln ('Couldn''t create AUTOEXEC.BAT.');
                 writeln ('Boot disk creation aborted.')
              end else begin
                 writeln (t, 'SET BLASTER='+GetEnv('BLASTER'));
                 writeln ('Do you want to load the german keyboard driver?');
                 repeat
                       write ('[Y] / [N]: ');
                       c := readkey;
                       writeln (c)
                 until c in ['y','Y','n','N'];
                 if c in ['y','Y'] then
                    writeln (t, 'LH '+SearchFile('KEYB.COM')+' GR,437,'+SearchFile('KEYBOARD.SYS'));
                 close (t);
                 writeln ('Boot disk successfully created.')
              end
           end
        end;
        exit
     end;

     InitSponge;
     Randomize;
     InitVGAMode;
     LoadFont ('VGA8x8.FNT',fr);
     UseLoadedFont (fr);
     InitPalette;

     FadePalette (0);

     ClearScreen;

     PrintAtOutlined (10, 20, 'SPONGE WARS - Version '+VerStr, 14, 1);
     PrintAtOutlined (10, 30, '  by Rudolf Polzer', 14, 1);
     PrintAtOutlined (10, 40, '  web:  https://divVerent.github.io', 14, 1);
     PrintAtOutlined (10, 50, '  mail: divVerent+sponge@gmail.com', 14, 1);
     PrintAtOutlined (10, 60, 'uses S.Tunstall''s KOJAKVGA', 14, 1);
     PrintAtOutlined (10, 70, ' and E.Brodsky''s SMIX', 14, 1);
     PrintAtOutlined (10, 90, 'Checking for blaster and XMS...', 14, 1);

     FadePalette (0);

     ShowUsedBitmap;

     FadeIn;

     x := 6;
     mywall := false;
     myROOF := false;
     mySound := true;
     ROOFdirt := 0;
     if GetOptionString ('b') <> '-' then
     s := InitSnd.InitBlaster
     else s := 'Blaster support disabled.';
     blaster_avail := s = '';
     if blaster_avail then begin
        PrintAtOutlined (10, 100, '  OK, SBpro+ found', 14, 1)
     end else begin
         PrintAtOutlined (10, 100, '  '+s, 14, 1);
         PrintAtOutlined (10, 110, '  Using PC speaker', 14, 1)
     end;

     ShowUsedBitmap;

     FadeOut;

     b := New64kBitmap;
     UseBitmap (b);
     FadePalette (0);
     LoadPCXToBitmap ('sponge.pcx', b, p, 0, 0, 320, 200);
     FadePalette (0);
     PrintAtOutlined (1, 190, 'SPONGE WARS '+VerStr+' (c) 1998,1999 R Polzer', 255, 0);
     ShowUsedBitmap;
     FadeIn;
     Delay (3000);
     FadeOut;

     InitPalette;
     FadePalette (0);

     ClearScreen;

     PrintAtOutlined (10, 20, 'SPONGE WARS - Version '+VerStr, 14, 1);
     PrintAtOutlined (10, 30, '  by Rudolf Polzer', 14, 1);
     PrintAtOutlined (10, 40, '  web:  https://divVerent.github.io', 14, 1);
     PrintAtOutlined (10, 50, '  mail: divVerent+sponge@gmail.com', 14, 1);
     PrintAtOutlined (10, 60, 'uses S.Tunstall''s KOJAKVGA', 14, 1);
     PrintAtOutlined (10, 70, ' and E.Brodsky''s SMIX', 14, 1);

     pnum := 1;
     teams := 4;

     ShowUsedBitmap;

     FadeIn;

     x := 0;

     repeat
           if x = 0 then
              PrintAtOutlined (100, 90,  'START GAME', 14, 1)
           else
              PrintAtOutlined (100, 90,  'START GAME', 0, 1);
           if x = 1 then
              PrintAtOutlined (100, 110, 'TEAMS: '+fstr(teams), 14, 1)
           else
              PrintAtOutlined (100, 110, 'TEAMS: '+fstr(teams), 0, 1);
           if x = 2 then
              PrintAtOutlined (100, 120, 'PLAYERS/TEAM: '+fstr(pnum), 14, 1)
           else
              PrintAtOutlined (100, 120, 'PLAYERS/TEAM: '+fstr(pnum), 0, 1);
           if x = 3 then
              PrintAtOutlined (100, 130, 'WALLS: '+walls[mywall], 14, 1)
           else
              PrintAtOutlined (100, 130, 'WALLS: '+walls[mywall], 0, 1);
           if x = 4 then
              PrintAtOutlined (100, 140, 'ROOF: '+ROOFs[myROOF], 14, 1)
           else
              PrintAtOutlined (100, 140, 'ROOF: '+ROOFs[myROOF], 0, 1);
           if x = 5 then
              PrintAtOutlined (100, 150, 'ROOF DIRT: '+fstr(ROOFdirt), 14, 1)
           else
              PrintAtOutlined (100, 150, 'ROOF DIRT: '+fstr(ROOFdirt), 0, 1);
           if x = 6 then
              PrintAtOutlined (100, 160, SOUNDs[mySound], 14, 1)
           else
              PrintAtOutlined (100, 160, SOUNDs[mySound], 0, 1);
           if x = 7 then
              PrintAtOutlined (100, 180, 'QUIT GAME', 14, 1)
           else
              PrintAtOutlined (100, 180, 'QUIT GAME', 0, 1);
           ShowUsedBitmap;
           case Readkey of
           #$4B: if (x = 1) and (teams > 2) then begin
                    Remove (99, 109, 260, 119);
                    dec (teams)
           end else if (x = 2) and (pnum > 1) then begin
                    Remove (99, 119, 260, 129);
                    dec (pnum)
           end else if (x = 5) and (ROOFdirt <> 0) then begin
                    Remove (99, 149, 260, 159);
                    dec (ROOFdirt)
           end;

           #$4D: if (x = 2) and ((pnum+1) * teams <= 16) then begin
                    Remove (99, 119, 260, 129);
                    inc (pnum)
           end else if (x = 5) and (ROOFdirt <> 10) then begin
                    Remove (99, 149, 260, 159);
                    inc (ROOFdirt)
           end else if (x = 1) and (pnum * (teams+1) <= 16) then begin
                    Remove (99, 109, 260, 119);
                    inc (teams)
           end;
           #$48: if x <> 0 then
                    dec (x);
           #$50: if x <> 7 then
                    inc (x);
           #$0D: case x of
                      0: begin
                              FadeOut;

                              UseBitmap (Ptr($A000,$0000));
                              FreeBitmap (b);

                              Game.Main (pnum*teams, teams, mywall, myROOF, mySound, ROOFdirt);

                              b := New64kBitmap;
                              UseBitmap (b);
                              ClearScreen;

                              PrintAtOutlined (10, 20, 'SPONGE WARS - Version '+VerStr, 14, 1);
                              PrintAtOutlined (10, 30, '  by Rudolf Polzer', 14, 1);
                              PrintAtOutlined (10, 40, '  web:  https://divVerent.github.io', 14, 1);
                              PrintAtOutlined (10, 50, '  mail: divVerent+sponge@gmail.com', 14, 1);
                              PrintAtOutlined (10, 60, 'uses S.Tunstall''s KOJAKVGA', 14, 1);
                              PrintAtOutlined (10, 70, ' and E.Brodsky''s SMIX', 14, 1);

                              ShowUsedBitmap;

                              FadeIn
                      end;
                      3: begin
                              Remove (99, 129, 260, 139);
                              mywall := not mywall
                      end;
                      4: begin
                              Remove (99, 139, 260, 149);
                              myROOF := not myROOF
                      end;
                      6: begin
                              Remove (99, 159, 260, 169);
                              mySound := not mySound
                      end;
                      7: begin
                              FadeOut;

                              UseBitmap (Ptr($A000,$0000));
                              FreeBitmap (b);

                              asm
                                 mov ax, 0003h
                                 int 10h
                              end;

                              Exit
                      end
           end
           end
     until false;

     if blaster_avail then ExitBlaster

end.
