{$I-,O+}

unit game;

interface

procedure Main (numplayers, numteams: byte; walls, ROOF, sound: boolean; ROOFdirt: byte);

implementation

uses Timer, KojakVGA, TSponge, SMix, SpEdit, FM, Speaker;

procedure AllFallDown (dodamage: boolean); forward;
procedure FallDown (p: byte; dodamage: boolean); forward;

const wBounce = 0;
      wHit = 1;
      wExpl = 2;
      wIntro = 3;
      pNoOne = 255;
      LastPlayerHurt: Byte = 255;
      PlayerPixel = 0;
      BGPixel = 1;
      FGPixel = 2;

var B: Pointer;
    Heights, ROOFs: Array [0..319] of Integer;
    players: array [0..15] of Player;
    thissponge: sponge;
    noROOF, wrapwalls: boolean;
    PlayersLiving: Byte;
    damagecaused: Single;
    SpongeSpeed: byte;
    no_sound, fmok: boolean;
    domove: boolean;



function Warn (j: single): byte;
begin
     if j < 20000 then warn := 4 else   {red}
     if j < 50000 then warn := 6 else   {yellow, brown}
     if j < 80000 then warn := 2 else   {green}
                       warn := 1        {blue}
end;

procedure PlaySound (N: Byte);
var X: Word;
begin
     if no_sound then exit;
     if blaster_avail then begin
        StartSound (Sounds[N], 1, false)
     end else if GetOptionString ('s') <> '-' then case N of
        wBounce: PlayRaw ('BOUNCE.RAW');
        wHit:    PlayRaw ('HIT.RAW');
        wExpl:   Playraw ('EXPLODE.RAW');
        wIntro:  Playraw ('INTRO.RAW');
     end
end;

procedure Wait;
begin
     if no_sound or not blaster_avail then exit;
     while SoundPlaying(1) do rdelay (14)
end;

procedure Height (N: Single);
const factor = 600.0;
      minfreq = 100;
      maxfreq = 4000;
begin
     if no_sound then exit;
     N := 192 - N;
     N := N / factor;
     N := minfreq + (maxfreq-minfreq)/(1+1/N);
     if fmok and (GetOptionString ('a') <> '-') then
        fm_play_tone(0,round(N),63)
     else
        if GetOptionString ('s') <> '-' then sound (round(n))
end;

procedure InitFM;
begin
     fmok := false;
     if (GetOptionString ('a') <> '-') and fm_detect then begin
        fmok := true;
        fm_reset;
        fm_load_patch (0, fm_get_patch_sine)
     end
end;

procedure StopFM;
begin
     if not no_sound then
        if fmok then fm_stop_tone(0) else nosound
end;

function Clip (X, XMin, XMax: Integer): Integer;
begin
     if X < XMin Then Clip := XMin Else if X > XMax Then Clip := XMax Else Clip := X
end;

function BGBitmap (X, Y: Word): Byte;
const kx = 8;
      ky = 5;
var mx, my: integer;
begin
     mx := kx*(x div kx) + kx div 2;
     my := ky*(y div ky) + ky div 2;
     BGBitmap := 16 + abs(x-mx) + abs(y-my)
end;

function PixelType (X, Y: Word): Byte;
begin
     case GetPixel (X, Y) of
          0..31: PixelType := BGPixel;
          32..63: PixelType := FGPixel;
          64..191: PixelType := PlayerPixel;
          192..255: PixelType := FGPixel;
          -1: PixelType := BGPixel
     end
end;


function ExplosionBitmap (R: integer): Byte;
begin
     ExplosionBitmap := 192 + 31 - trunc(R / ThisSponge.ES * 31)
end;

function FGBitmap (X, Y: Word): Byte;
const kx = 31;
      ky = 31;
var mx, my: integer;
begin
     mx := kx*(x div kx) + kx div 2;
     my := ky*(y div ky) + ky div 2;
     FGBitmap := 32 + abs(x-mx) + abs(y-my)
end;


const PlayerColor = 64;

procedure CreateHeightMap (Start, Ende, Delta: Word; XMin, XMax: Byte; DeltaROOF, XMinROOF, XMaxROOF: Byte);

var Middle, Y: Word;
begin
     Middle := (Start + Ende) div 2;
     repeat
           Heights[Middle] := (Heights[Start] + Heights[Ende] + random (2 * Delta) - Delta) div 2
     until Heights[Middle] = Clip(Heights[Middle], XMin, XMax);
     repeat
           ROOFs[Middle] := (ROOFs[Start] + ROOFs[Ende] + random (2 * DeltaROOF) - DeltaROOF) div 2
     until ROOFs[Middle] = Clip(ROOFs[Middle], XMinROOF, XMaxROOF);
     For Y := 0 to 191 do
         if (Heights[Middle] < Y) OR (ROOFs[Middle] > Y) Then
            PutPixel (Middle, Y, FGBitmap (Middle, Y))
         Else
            PutPixel (Middle, Y, BGBitmap (Middle, Y));
     If Middle - Start > 1 Then CreateHeightMap (Start, Middle, Delta div 2, XMin, XMax, DeltaROOF div 2, XMinROOF, XMaxROOF);
     If Ende - Middle > 1 Then CreateHeightMap (Middle, Ende, Delta div 2, XMin, XMax, DeltaROOF div 2, XMinROOF, XMaxROOF)
end;

const StandardPlayerImage: PlayerImage = (
(255       , 1+0*5+0*25, 2+1*5+0*25, 3+2*5+1*25, 4+3*5+2*25, 3+2*5+1*25, 2+1*5+0*25, 1+0*5+0*25, 255       ),
(1+0*5+0*25, 2+1*5+0*25, 3+2*5+1*25, 4+3*5+2*25, 4+4*5+3*25, 4+3*5+2*25, 3+2*5+1*25, 2+1*5+0*25, 1+0*5+0*25),
(2+1*5+0*25, 3+2*5+1*25, 4+3*5+2*25, 4+4*5+3*25, 4+4*5+4*25, 4+4*5+3*25, 4+3*5+2*25, 3+2*5+1*25, 2+1*5+0*25),
(3+2*5+1*25, 4+3*5+2*25, 4+4*5+3*25, 4+4*5+4*25, 4+4*5+4*25, 4+4*5+4*25, 4+4*5+3*25, 4+3*5+2*25, 3+2*5+1*25),
(4+3*5+2*25, 4+4*5+3*25, 4+4*5+4*25, 4+4*5+4*25, 4+4*5+4*25, 4+4*5+4*25, 4+4*5+4*25, 4+4*5+3*25, 4+3*5+2*25),
(3+2*5+1*25, 4+3*5+2*25, 4+4*5+3*25, 4+4*5+4*25, 4+4*5+4*25, 4+4*5+4*25, 4+4*5+3*25, 4+3*5+2*25, 3+2*5+1*25),
(2+1*5+0*25, 3+2*5+1*25, 4+3*5+2*25, 4+4*5+3*25, 4+4*5+4*25, 4+4*5+3*25, 4+3*5+2*25, 3+2*5+1*25, 2+1*5+0*25),
(1+0*5+0*25, 2+1*5+0*25, 3+2*5+1*25, 4+3*5+2*25, 4+4*5+3*25, 4+3*5+2*25, 3+2*5+1*25, 2+1*5+0*25, 1+0*5+0*25),
(255       , 1+0*5+0*25, 2+1*5+0*25, 3+2*5+1*25, 4+3*5+2*25, 3+2*5+1*25, 2+1*5+0*25, 1+0*5+0*25, 255       )
);

procedure Explode (X, Y: integer); forward;

procedure GetSmallImage (X, Y: Integer; var S: SmallImage);
var XX, YY: Integer;
begin
     for YY := -1 to 1 do
         for XX := -1 to 1 do
             if (XX + X >= 0) and (YY + Y >= 0) and
                (XX + X <= 319) and (YY + Y <= 199) then
                S[XX, YY] := GetPixel (XX+X, YY+Y)
end;

procedure PutSmallImage (X, Y: Word; var S: SmallImage; T: Boolean);
var XX, YY: Integer;
begin
     for YY := -1 to 1 do
         for XX := -1 to 1 do if (not T or (S[XX, YY] <> 0))
             and (XX + X >= 0) and (YY + Y >= 0) and
                 (XX + X <= 319) and (YY + Y <= 199) then
                PutPixel (XX+X, YY+Y, S[XX, YY])
end;

procedure PutPlayerImage (X, Y: Word; var S: PlayerImage; T: Boolean);
var XX, YY: Integer;
begin
     for YY := -4 to 4 do
         for XX := -4 to 4 do if (not T or (S[XX, YY] <> 255))
             and (XX + X >= 0) and (YY + Y >= 0) and
                 (XX + X <= 319) and (YY + Y <= 199) then
                PutPixel (XX+X, YY+Y, Clip (S[XX, YY] + PlayerColor, PlayerColor, 255))
end;

function GetPlayerImageColl (X, Y: Word; var S: PlayerImage; T: Boolean):Byte;
var XX, YY: Integer; C: Byte;
begin
     C := 0;
     for YY := -4 to 4 do
         for XX := -4 to 4 do if (not T or (S[XX, YY] <> 255))
             and (XX + X >= 0) and (YY + Y >= 0) and
                 (XX + X <= 319) and (YY + Y <= 199) then
                     if PixelType (XX+X, YY+Y) = FGPixel Then
                        Inc (C);
     GetPlayerImageColl := C
end;

procedure RemovePlayerImage (X, Y: Word; var S: PlayerImage; T: Boolean);
var XX, YY: Integer;
begin
     for YY := -4 to 4 do
         for XX := -4 to 4 do if (not T or (S[XX, YY] <> 255))
             and (XX + X >= 0) and (YY + Y >= 0) and
                 (XX + X <= 319) and (YY + Y <= 199) then
                PutPixel (XX+X, YY+Y, BGBitmap (XX+X, YY+Y))
end;

procedure DrawPlayers;
var i, x, y: integer;
begin
     for i := 0 to 15 do if players[i].living then
         PutPlayerImage (Players[i].X, players[i].y, Players[i].Image, true)
end;

procedure Death (i: byte);
begin
                  players[i].living := false;
                  RemovePlayerImage (players[i].X, players[i].Y, players[i].Image, true);
                  Explode (players[i].X, players[i].Y);
                  dec (PlayersLiving)
end;

function HurtPlayer (hurt: Word; n: Single): boolean;
var i: byte;
const DeathBonus = 20000;
begin
     if n = 0 then begin HurtPlayer := false; exit end else HurtPlayer := true;
     damagecaused := damagecaused + n;
     with players[hurt] do begin
          PutPlayerImage (x, y, image, true);
          if LastPlayerHurt <> hurt then
             PlaySound (wHit);
          LastPlayerHurt := hurt;
          MaxJoule := MaxJoule - n;
          if MaxJoule <= 0 then begin
             mustdie := true;
             damagecaused := damagecaused + MaxJoule + DeathBonus
          end
     end
end;

function CheckColl (X, Y: Word): Boolean;
begin
     If PixelType (X, Y) <> BGPixel Then CheckColl := True Else
                                         CheckColl := False
end;

procedure Explode (X, Y: Integer);
var x2, xx, yy: Integer;


procedure RemovePixel;
begin
     if wrapwalls then
        x2 := (xx + 320) mod 320
     else
        x2 := xx;
     if thissponge.IsDBomb then
        if thissponge.IsDigger and (Y <= yy) and (abs(X - x2) <= 5) then
           PutPixel (x2, yy, BGBitmap (x2, yy))
        else
           PutPixel (x2, yy, FGBitmap (x2, yy))
     else
        if thissponge.IsDigger then begin
           if (Y <= yy) and (abs(X - x2) <= 5) then
              PutPixel (x2, yy, BGBitmap (x2, yy))
        end
        else
           PutPixel (x2, yy, BGBitmap (x2, yy))
end;

procedure EPixel;
begin
     if wrapwalls then
        x2 := (xx + 320) mod 320
     else
        x2 := xx;
     if not thissponge.IsDigger or thissponge.IsDBomb or ((Y <= YY) and (abs(X - XX) <= 5)) then
        if thissponge.Shape in [sSquare, sStar] then
           if abs(xx-x) > abs(yy-y) then
              PutPixel (X2, YY, explosionbitmap(abs(xx-x)))
           else
              PutPixel (X2, YY, explosionbitmap(abs(yy-y)))
        else
           PutPixel (X2, YY, explosionbitmap(round((sqr(xx-x)+sqr(yy-y))/thissponge.ES)))
end;

begin
     ShowUsedBitmapWait;
     LastPlayerHurt := pNoOne;
     UseBitmap (Ptr($A000,$0000));
     case thissponge.shape of
     sSquare:
          for xx := x - thissponge.ES to x + thissponge.ES do
              for yy := y - thissponge.ES
                     to y + thissponge.ES do
                  EPixel;
     sCircle:
          for xx := x - thissponge.ES to x + thissponge.ES do
              for yy := y - thissponge.ES
                     to y + thissponge.ES do
                  if sqr(yy-y)+sqr(xx-x) <= sqr(thissponge.ES) then
                     EPixel;
     sStar:
          for xx := x - thissponge.ES to x + thissponge.ES do
              for yy := y - thissponge.ES
                     to y + thissponge.ES do
                  if (Longint(starfactor)*sqr(yy-y)+sqr(xx-x) <= sqr(thissponge.ES))
                  or (sqr(yy-y)+Longint(starfactor)*sqr(xx-x) <= sqr(thissponge.ES)) then
                     EPixel;
     end;

     PlaySound (wExpl);
     RDelay (400);
     for xx := 0 to 15 do with players[xx] do if living then
         if HurtPlayer (xx, GetPlayerImageColl (x, y, image, true)* thissponge.damage)
            then RDelay (300);
     UseBitmap (b);
     case thissponge.shape of
     sSquare:
          for xx := x - thissponge.ES to x + thissponge.ES do
              for yy := y - thissponge.ES
                     to y + thissponge.ES do
                  RemovePixel;
     sCircle:
          for xx := x - thissponge.ES to x + thissponge.ES do
              for yy := y - thissponge.ES
                     to y + thissponge.ES do
                  if sqr(yy-y)+sqr(xx-x) <= sqr(thissponge.ES) then
                     RemovePixel;
     sStar:
          for xx := x - thissponge.ES to x + thissponge.ES do
              for yy := y - thissponge.ES
                     to y + thissponge.ES do
                  if (Longint(starfactor)*sqr(yy-y)+sqr(xx-x) <= sqr(thissponge.ES))
                  or (sqr(yy-y)+Longint(starfactor)*sqr(xx-x) <= sqr(thissponge.ES)) then
                     RemovePixel;
     end;
     ShowUsedBitmapWait;
     DrawPlayers
end;

procedure Throw (Xs, Ys, vX, vY, wX, gY: single; player: byte; domove: boolean);
var X, Y, dx, dy, ddx, ddy: Single;
    t: Longint;
    s: SmallImage;
    p: byte;
    d, d2: boolean;
    scrx, scry: word;
    diff: integer;
    ok: boolean;


const Sponges: array [0..7] of SmallImage = (
               (
                ( 0, 0, 0),
                (14,14,14),
                (14,14,14)
               ),(
                ( 0, 0,14),
                ( 0,14,14),
                (14,14, 0)
               ),(
                ( 0,14,14),
                ( 0,14,14),
                ( 0,14,14)
               ),(
                (14,14, 0),
                ( 0,14,14),
                ( 0, 0,14)
               ),(
                (14,14,14),
                (14,14,14),
                ( 0, 0, 0)
               ),(
                ( 0,14,14),
                (14,14, 0),
                (14, 0, 0)
               ),(
                (14,14, 0),
                (14,14, 0),
                (14,14, 0)
               ),(
                (14, 0, 0),
                (14,14, 0),
                ( 0,14,14)
               )
);

const dt = 1/72;

begin
     t := 0;
     x := Xs;
     y := Ys;
     dx := vX;
     dy := -vY;
     repeat
           inc (t);
           ddx := (wX - dx) * thissponge.r;
           ddy := gY - thissponge.r * dy;
           dx := dx + ddx * dt;
           dy := dy + ddy * dt;
           x := x + dx * dt;
           y := y + dy * dt;
           if x < 0 then if wrapwalls then x := x + 320 else begin
              PlaySound (wBounce);
              dx := -dx;
              x := -x
           end;
           if y < 0 then if not noROOF then begin
              PlaySound (wBounce);
              dy := -dy;
              y := -y
           end;
           if x > 319 then if wrapwalls then x := x - 320 else begin
              PlaySound (wBounce);
              dx := -dx;
              x := 638-x
           end;
           if y > 190 then begin
              PlaySound (wBounce);
              dy := -dy;
              y := 381-y
           end;

           Height (y);

           scrx := clip(round(x), 0, 319);
           scry := clip(round(y), 0, 190);

           If CheckColl (scrx, scry) or (t >= 72 * 30) then begin
              StopFm;
              Explode (scrx, scry);
              t := thissponge.es;
              thissponge.es := thissponge.es div 2;
              repeat
                    d2 := false;
                    repeat
                          d := false;
                          for p := 0 to 15 do
                              if players[p].mustdie and players[p].living then begin
                                 death (p);
                                 d := true;
                                 d2 := true
                              end
                    until not d;
                    allfalldown (true);
                    for p := 0 to 15 do
                        if players[p].living and players[p].mustdie then d2 := true
              until not d2;
              thissponge.es := t;
              if domove and players[player].living then begin
                 diff := 0;
                 if scry > 186 then scry := 186;
                 repeat
                       scrx := scrx + diff;
                       ok := true;
                       if (scrx < 4) or (scrx > 315) then ok := false else
                          for p := 0 to 15 do
                              if players[p].living and
                                 (player <> p) and
                                 ( (scrx-players[p].x <= 8) or
                                   (players[p].x-scrx <= 8)    ) then ok := false;
                       if not ok then scrx := scrx - diff;
                       if diff < 0 then diff := -diff else diff := -diff-1
                 until ok;
                 removeplayerimage (players[player].x, players[player].y, players[player].image, true);
                 players[player].x := scrx;
                 players[player].y := scry;
                 putplayerimage (players[player].x, players[player].y, players[player].image, true);
                 falldown (player, false)
              end;
              Exit
           end;

           GetSmallImage (scrx, scry, s);
           if (scry - y > 0.5) or (scrx - x > 0.5) then
              PutPixel (scrx, scry, 14)
           else
              PutSmallImage (scrx, scry, sponges [(t shr 2) and 7], true);

           if t mod spongespeed = 0 then
              ShowUsedBitmapWait;

           if keypressed then case readkey of
              '/': if spongespeed <> 1 then dec (spongespeed);
              '*': if spongespeed <> 10 then inc (spongespeed);
              else spongespeed := 10
           end;

           PutSmallImage (scrx, scry, s, false)

     until false
end;

procedure FallDown (p: byte; dodamage: boolean);
var i: byte;
begin
     with players[p] do if living then repeat
           if (y < 187) and (getplayerimagecoll (x, y+1, image, true) < 5) and living then begin
              removeplayerimage (x, y, image, true);
              inc (y);
              inc (i);
              putplayerimage (x, y, image, true);
           end else begin
              if dodamage then
                 HurtPlayer (p, i * thissponge.falldowndamage);
              exit
           end
     until false
end;


procedure AllFallDown (dodamage: boolean);
var p: byte;
    i: array [0..15] of byte;
    b: array [0..15] of boolean;
    n: byte;
begin
     lastplayerhurt := pNoOne;
     for p := 0 to 15 do i[p] := 0;
     for p := 0 to 15 do b[p] := true;
     n := playersliving;

     repeat
           for p := 0 to 15 do
               with players[p] do if living and b[p] then
                    if (y < 187) and (getplayerimagecoll (x, y+1, image, true) < 5) and living then begin
                       removeplayerimage (x, y, image, true);
                       inc (y);
                       inc (i[p]);
                       putplayerimage (x, y, image, true);
                    end else begin
                       if dodamage then
                          HurtPlayer (p, i[p] * thissponge.falldowndamage);
                       b[p] := false;
                       dec (n)
                    end;
           if dodamage then ShowUsedBitmapWait
     until n = 0;
end;

procedure Rect (X1, Y1, X2, Y2: Word; C: Byte);
var x: word;
begin
     UseColour (C);
     for x := X1 to X2 do begin
         PutPixel (X, Y1, C);
         PutPixel (X, Y2, C)
     end;
     for x := Y1 to Y2 do begin
         PutPixel (X1, X, C);
         PutPixel (X2, X, C)
     end
end;

procedure BarGraph (X1, Y1, X2, Y2: Word; C: Byte; Z, N: Single);
var x, y: word;
begin
     for x := X1 to round (X1 + (X2-X1) * Z / N) do
         for y := Y1 to Y2 do
             PutPixel (X, Y, C);
     for x := X1 downto round (X1 + (X2-X1) * Z / N) do
         for y := Y1 to Y2 do
             PutPixel (X, Y, C)
end;

procedure Main (numplayers, numteams: byte; walls, ROOF, sound: boolean; ROOFdirt: byte);

var X, Y: Word;

    p, s, s2, teamsliving: Byte;
    vX, vY, alpha, betrag: Single;
    ok, wasinedit: boolean;

    mysponge: word;
    f: text; f2: file of playerimage;
    st: string;
    thiscost: single;
    playerdrawn: byte;

const Wind: Single = 0;
      g = 9.81;
      StartMaxJoule = 100000; {1 kg; ca. 300 m/s}
      rough = 4;
      ROOFrough = 10;
      DrawGame = 'DRAW GAME';
      WonGameS = 'TEAM ';
      WonGameE = ' HAS WON';
      EnterS = 'PRESS [ENTER]';
      playerdrawn_period = 10;

begin
     initfm;
     wrapwalls := walls;
     noROOF := ROOF;
     ROOFdirt := ROOFdirt + 1;
     no_sound := not sound;
     B := New64kBitmap;
     UseBitmap (B);
     Cls;
     setwindow (0, 8, 319, 199);
     Heights [0] := random (100) + 40;
     if walls then
        Heights[319] := Heights[0] else
        Heights [319] := random (100) + 40;
     ROOFs [0] := random (ROOFdirt);
     if walls then
        ROOFs[319] := ROOFs[0] else
        ROOFs [319] := random (ROOFdirt);
     For Y := 0 to 191 do
         if (ROOFs[0] > Y) OR (Heights[0] < Y) Then
            PutPixel (0, Y, FGBitmap (0, Y))
         Else
            PutPixel (0, Y, BGBitmap (0, Y));
     For Y := 0 to 191 do
         if (ROOFs[319] > Y) OR (Heights[319] < Y) Then
            PutPixel (319, Y, FGBitmap (319, Y))
         Else
            PutPixel (319, Y, BGBitmap (319, Y));
     CreateHeightMap (0, 319, rough * 100, 40, 139, ROOFrough * ROOFdirt, 0, ROOFdirt-1);


     assign (f, 'SPONGE.INI');
     reset (f);

     for x := 0 to numplayers-1 do begin
         if x mod numteams = 0 then reset (f);
         readln (f, st);
         players[x].X := round (320 / numplayers * (x + 0.5));
         players[x].Y := 20;
         players[x].Living := true;
         players[x].lastbetrag := 10;
         players[x].lastalpha := 0;
         players[x].MaxJoule := StartMaxJoule;
         players[x].LastSponge := 0;
         players[x].Image := StandardPlayerImage;
         players[x].mustdie := false;
         assign (f2, st);
         reset (f2);
         read (f2, players[x].image);
         close (f2)
     end;
     for x := numplayers to 15 do players[x].living := false;

     playersliving := numplayers;

     close (f);

     allFallDown (false);
     DrawPlayers;

     ShowUsedBitmapWait;

     FadeIn;

     p := 0;

     PlaySound (wIntro);

     repeat
           domove := false;
           mysponge := players[p].lastsponge;
           betrag := wind;
           repeat
                 Wind := betrag + 10 * (random - 0.5);
           until abs(Wind) < 25;
           X := players[p].X;
           Y := players[p].Y-5;
           alpha := players[p].lastalpha;
           betrag := players[p].lastbetrag;
           ok := false;
           playerdrawn := 0;
           repeat
                 if playerdrawn = playerdrawn_period then
                    removeplayerimage (Players[p].X, players[p].y, Players[p].Image, true)
                 else if playerdrawn = 0 then
                    PutPlayerImage (Players[p].X, players[p].y, Players[p].Image, true);
                 playerdrawn := (playerdrawn + 1) mod (2*playerdrawn_period);
                 wasinedit := false;
                 while mysponge >= countsponges do begin
                                mysponge := 0;
                                FadeOut;
                                asm
                                   mov ax, 0003h
                                   int 10h
                                end;
                                SpEdit.Main;
                                wasinedit := true
                 end;
                 getSponge(mysponge, thissponge);
                 while thissponge.cost >= players[p].MaxJoule do begin
                       Dec (MySponge);
                       mysponge := (mysponge + countsponges) mod countsponges;
                       getSponge(mysponge, thissponge)
                 end;
                 if not domove then thiscost := thissponge.cost else begin
                    thiscost := 4 * thissponge.cost + 10000;
                    if thiscost >= players[p].MaxJoule then begin
                       domove := false;
                       thiscost := thissponge.cost
                    end
                 end;
                 if betrag < 1 then betrag := 1;
                 if alpha > 180 then alpha := 0;
                 if alpha < 0 then alpha := 180;
                 mysponge := (mysponge + countsponges) mod countsponges;
                 getSponge(mysponge, thissponge);
                 if betrag*betrag*thissponge.weight/2 > players[p].MaxJoule-thiscost then
                    betrag := sqrt ((players[p].MaxJoule-thiscost) * 2 / thissponge.weight);
                 vX := betrag * cos (alpha * pi / 180);
                 vY := betrag * sin (alpha * pi / 180);
                 s2 := getpixel (x + round(vX / betrag * 10), y - round(vY / betrag * 10));
                 putpixel (x + round(vX / betrag * 10), y - round(vY / betrag * 10), 12);
                 s := getpixel (x + round(vX), y - round(vY));
                 putpixel (x + round(vX), y - round(vY), 14);
                 setwindow (0, 0, 319, 199);
                 UseColour (0);
                 PrintAt (0, 0, 'лллллллллллллллллллллллллллллллллллллллл');
                 UseColour (15);
                 PrintAt (0, 0, 'P'+fstr(p+1));
                 if domove then
                    UseColour (14)
                 else if 4 * thissponge.cost + 10000 >= players[p].MaxJoule then
                    UseColour (8)
                 else
                    UseColour (9);

                 PrintAt (24, 0, #29);
                 UseColour (15);
                 PrintAt (200, 0, thissponge.Description);
                 Rect (113, 1, 191, 6, 15);
                 BarGraph (114, 2, 190, 5, Warn(players[p].maxjoule), players[p].MaxJoule, StartMaxJoule);
                 BarGraph (114, 2, 190, 5, Warn(players[p].maxjoule-thiscost)+8,
                          players[p].MaxJoule-thiscost, StartMaxJoule);
                 BarGraph (114, 3, 190, 4, 0, betrag*betrag*thissponge.weig ht/2, StartMaxJoule);
                 BarGraph (70, 2, 71, 5, 4, Wind, 1);
                 Rect (44, 1, 70, 6, 15);
                 Rect (70, 1, 96, 6, 15);
                 if wasinedit then begin
                                InitVGAMode;
                                InitPalette;
                                FadePalette (0);
                                ShowUsedBitmapWait;
                                FadeIn;
                                X := players[p].X
                 end else       ShowUsedBitmapWait;
                 setwindow (0, 8, 319, 199);
                 putpixel (x + round(vX), y - round(vY), s);
                 putpixel (x + round(vX / betrag * 10), y - round(vY / betrag * 10), s2);
                 if keypressed then case readkey of
                      #$48: betrag := betrag + 1;
                      #$50: betrag := betrag - 1;
                      #$4B: alpha := alpha + 1;
                      #$4D: alpha := alpha - 1;
                      #$49: betrag := betrag + 10;
                      #$51: betrag := betrag - 10;
                      #$73: alpha := alpha + 10;
                      #$74: alpha := alpha - 10;
                      #$84: betrag := betrag + 100;
                      #$76: betrag := betrag - 100;
                      #$0D, #$20: ok := true;
                      '+': begin
                                Inc (MySponge);
                                mysponge := (mysponge + countsponges) mod countsponges;
                                getSponge(mysponge, thissponge);
                                while thissponge.cost >= players[p].MaxJoule do begin
                                      Inc (MySponge);
                                      mysponge := (mysponge + countsponges) mod countsponges;
                                      getSponge(mysponge, thissponge)
                                end
                      end;
                      '-': begin
                                Dec (MySponge);
                                mysponge := (mysponge + countsponges) mod countsponges;
                                getSponge(mysponge, thissponge);
                                while thissponge.Cost >= players[p].MaxJoule do begin
                                      Dec (MySponge);
                                      mysponge := (mysponge + countsponges) mod countsponges;
                                      getSponge(mysponge, thissponge)
                                end
                      end;
                      'e': mysponge := countsponges;    {will lead to editor}
                      #$09:  domove := not domove;
                      #$1B: begin
                                 FadeOut;

                                 freebitmap(b);

                                 setwindow (0, 0, 319, 199);
                                 exit
                      end;
                 end
           until ok;
           PutPlayerImage (Players[p].X, players[p].y, Players[p].Image, true);
           players[p].lastalpha := alpha;
           players[p].lastbetrag := betrag;
           players[p].lastsponge := mysponge;
           Players[p].MaxJoule := Players[p].MaxJoule - thiscost;
           spongespeed := (GetProcTime(ShowUsedBitmapWait, 72000)+500) div 1000;
           if spongespeed > 10 then spongespeed := 10;
           if spongespeed = 0 then spongespeed := 1;
           damagecaused := 0;
           for s := 1 to thissponge.spongenum do begin
               alpha := alpha + (random - 0.5) * thissponge.exactness;
               if alpha > 180 then alpha := 180;
               if alpha < 0 then alpha := 0;
               vX := betrag * cos (alpha * pi / 180);
               vY := betrag * sin (alpha * pi / 180);
               Throw (X, Y, vX, vY, Wind, g, p, domove and (s = thissponge.spongenum))
           end;
           with players[p] do if living then begin
                maxjoule := maxjoule + damagecaused / 2;
                if maxjoule > 100000 then maxjoule := 100000;
                setwindow (0, 0, 319, 199);
                for s := 0 to 4 do begin
                    if players[p].maxjoule <> 0 then
                       BarGraph (114, 2, 190, 5, 0, 1, 1);
                    VWait (1);
                    ShowUsedBitmapWait;
                    Delay (50);
                    if players[p].maxjoule <> 0 then
                       BarGraph (114, 2, 190, 5, Warn(players[p].maxjoule)+8, players[p].MaxJoule, StartMaxJoule);
                    VWait (1);
                    ShowUsedBitmapWait;
                    Delay (50)
                end;
                setwindow (0, 8, 319, 199);
                Delay (300)
           end;
           wait;
           repeat p := (p + 1) and 15 until players[p].living or (PlayersLiving = 0);
           while keypressed do readkey;
           TeamsLiving := 0;
           for s := 0 to numteams-1 do begin
               ok := false;
               for s2 := 0 to numplayers div numteams - 1 do
                   if players[s2*numteams+s].living then ok := true;
               if ok then TeamsLiving := TeamsLiving + 1
           end
     until TeamsLiving <= 1;
     setwindow (0, 0, 319, 199);
     if PlayersLiving = 0 then
        PrintAtOutlined (160 - 4 * Length(DrawGame), 100-10, DrawGame, 8, 7)
     else
        PrintAtOutlined (160 - 4 * Length(WonGameS+fstr(p mod numteams+1)+WonGameE), 100-10,
                               WonGameS+fstr(p mod numteams+1)+WonGameE, 14, 1);

     PrintAtOutlined (160 - 4 * Length(EnterS), 100, EnterS, 15, 0);

     ShowUsedBitmapWait;
     repeat until readkey = #13;
     fadeOut;

     freebitmap(b);
     setwindow (0, 0, 319, 199)
end;

end.
