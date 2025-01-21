unit TSponge; {$I-,O+,N+,G+}

interface

uses KojakVGA, SMix;

const VerStr = '2.0a';

      sCircle = 0;
      sSquare = 1;
      sStar = 2;
      starfactor = 40;

      blaster_avail: boolean = false;


var Sounds: array[0..4] of PSound;
    p: PaletteType;


type SmallImage = array [-1..1, -1..1] of Byte;
     PlayerImage = array [-4..4, -4..4] of Byte;

     Sponge = record
                    weight, r, Damage, FallDownDamage, Cost: Single;     {kg; s^(-1); m; J}
                    ES, SpongeNum: Word;
                    Exactness: Single;
                    IsDigger, IsDBomb: Boolean;
                    Shape: Byte;
                    Description: String [15]
              end;

     Player = record
                    X, Y: Word;
                    Living: Boolean;
                    LastAlpha, LastBetrag: Single;
                    MaxJoule: Single;
                    LastSponge: Word;
                    Image: PlayerImage;
                    MustDie: Boolean
              end;

procedure InitSponge;
function fstr (x: single): string;
procedure PutSponge (n: word; var s: sponge);
procedure GetSponge (n: word; var s: sponge);
procedure RemoveSponge (n: word);
function keypressed: boolean;
function readkey: char;
function CountSponges: word;
procedure InitPalette;
procedure NoSound;
procedure Delay (W: Word);
procedure Sound (F: Word);
procedure RotatePalette;
procedure FadePalette (factor: byte);
procedure RDelay (n: Word);
procedure FadeOut;
procedure FadeIn;
procedure ShowUsedBitmapWait;
function GetOptionString (c: char): string;
procedure PrintAtOutlined (X, Y: Word; S: String; C1, C2: Byte);

implementation

var Sponges: array [0..254] of Sponge;
    SpongesNum: byte;
    oldexitproc: pointer;
    f: file;



procedure PrintAtOutlined (X, Y: Word; S: String; C1, C2: Byte);
begin
     UseColour (C1);
     PrintAt (X-1, Y-1, S);
     PrintAt (X-1, Y, S);
     PrintAt (X-1, Y+1, S);
     PrintAt (X, Y-1, S);
     PrintAt (X, Y+1, S);
     PrintAt (X+1, Y-1, S);
     PrintAt (X+1, Y, S);
     PrintAt (X+1, Y+1, S);
     UseColour (C2);
     PrintAt (X, Y, S)
end;

procedure Delay (W: Word); assembler;
asm
   mov ax, w
   mov bx, 977
   xor dx, dx
   mul bx
   mov cx, dx
   mov dx, ax
   mov ah, 86h
   int 15h
end;

procedure Sound (F: Word); assembler;
asm
   mov bx, F
   mov ax, 13532
   mov dx, 18
   div bx
   push ax

   mov dx, 43h
   mov al, 10110110b
   out dx, al

   pop ax
   out 42h, al
   xchg al, ah
   out 42h, al

   in al, 61h
   or al, 00000011b
   out 61h, al
end;

procedure NoSound; assembler;
asm
   in al, 61h
   and al, 11111100b
   out 61h, al
end;

procedure InitPalette;
var i: byte;
begin
with p do begin
     RedLevel[ 0] :=   0; GreenLevel[ 0] :=   0; BlueLevel[ 0] :=   0;
     RedLevel[ 1] :=   0; GreenLevel[ 1] :=   0; BlueLevel[ 1] :=  47;
     RedLevel[ 2] :=   0; GreenLevel[ 2] :=  47; BlueLevel[ 2] :=   0;
     RedLevel[ 3] :=   0; GreenLevel[ 3] :=  47; BlueLevel[ 3] :=  47;
     RedLevel[ 4] :=  47; GreenLevel[ 4] :=   0; BlueLevel[ 4] :=   0;
     RedLevel[ 5] :=  47; GreenLevel[ 5] :=   0; BlueLevel[ 5] :=  47;
     RedLevel[ 6] :=  47; GreenLevel[ 6] :=  47; BlueLevel[ 6] :=   0;
     RedLevel[ 7] :=  47; GreenLevel[ 7] :=  47; BlueLevel[ 7] :=  47;
     RedLevel[ 8] :=  15; GreenLevel[ 8] :=  15; BlueLevel[ 8] :=  15;
     RedLevel[ 9] :=  15; GreenLevel[ 9] :=  15; BlueLevel[ 9] :=  63;
     RedLevel[10] :=  15; GreenLevel[10] :=  63; BlueLevel[10] :=  15;
     RedLevel[11] :=  15; GreenLevel[11] :=  63; BlueLevel[11] :=  63;
     RedLevel[12] :=  63; GreenLevel[12] :=  15; BlueLevel[12] :=  15;
     RedLevel[13] :=  63; GreenLevel[13] :=  15; BlueLevel[13] :=  63;
     RedLevel[14] :=  63; GreenLevel[14] :=  63; BlueLevel[14] :=  15;
     RedLevel[15] :=  63; GreenLevel[15] :=  63; BlueLevel[15] :=  63;
     for i := 0 to 15 do begin
         RedLevel[i+16] := i shl 2;
         GreenLevel[i+16] := i shl 2;
         BlueLevel[i+16] := i shl 2
     end;
     for i := 0 to 31 do begin
         RedLevel[i+32] := trunc(31+31*sin (i / 15 * pi));
         GreenLevel[i+32] := trunc(31+31*sin (i / 15 * pi + pi * 2 / 3));
         BlueLevel[i+32] := trunc(31+31*sin (i / 15 * pi + pi * 4 / 3))
     end;
     for i := 0 to 124 do begin
         RedLevel[i+64]   := (i)         mod 5 * 15;
         GreenLevel[i+64] := (i div 5)   mod 5 * 15;
         BlueLevel[i+64]  := (i div 25)  mod 5 * 15
     end;
     for i := 0 to 63 do begin
         RedLevel[i+192] := 63;
         GreenLevel[i+192] := trunc(32+31*cos (i / 16 * pi));
         BlueLevel[i+192] := 0
     end

end;
UsePalette (p)
end;

procedure RotatePalette;
var x, r, g, b: byte;
begin
     r := p.RedLevel[255];
     g := p.GreenLevel[255];
     b := p.BlueLevel[255];
     for x := 255 downto 193 do begin
         p.RedLevel[x] := p.RedLevel[x-1];
         p.GreenLevel[x] := p.GreenLevel[x-1];
         p.BlueLevel[x] := p.BlueLevel[x-1]
     end;
     p.RedLevel[192] := r;
     p.GreenLevel[192] := g;
     p.BlueLevel[192] := b;
     UsePalette (p)
end;

procedure FadeOut;
var x: byte;
begin
     for x := 255 div 3 downto 0 do begin
         FadePalette (x*3);
         Delay (14)
     end
end;

procedure FadeIn;
var x: byte;
begin
     for x := 0 to 255 div 3 do begin
         FadePalette (x*3);
         Delay (14)
     end
end;

procedure RDelay (n: Word);
begin
     while n >= 14 do begin
           vwait(1);
           RotatePalette;
           dec (n, 14)
     end;
     if n = 0 then exit;
     delay (n);
     RotatePalette
end;

procedure FadePalette (factor: byte);
var x: byte; p2: PaletteType;
begin
     for x := 0 to 255 do begin
         p2.RedLevel[x] := round(p.RedLevel[x] / 255 * factor);
         p2.GreenLevel[x] := round(p.GreenLevel[x] / 255 * factor);
         p2.BlueLevel[x] := round(p.BlueLevel[x] / 255 * factor)
     end;
     UsePalette (p2)
end;



procedure GetSponge (n: word; var s: sponge);
begin
     s := sponges[n]
end;

procedure PutSponge (n: word; var s: sponge);
begin
     sponges[n] := s;
     if n = spongesnum then spongesnum := n + 1
end;

procedure RemoveSponge (n: word);
var s: sponge;
    i: byte;
begin
     dec (spongesnum);
     for i := n to spongesnum do sponges[i] := sponges[i+1]
end;

function CountSponges: word;
begin
     CountSponges := spongesnum
end;

function fstr (x: single): string;
var s: string;
begin
     str (x:0:0, s);
     fstr := s
end;

function Readkey: Char; assembler;
asm
   xor ax, ax
   int 16h
   and al, al
   jnz @retkey
   mov al, ah
@retkey:
end;

function keypressed: boolean; assembler;
asm
   mov ah, 1
   int 16h
   jz @no
   xor al, al
   not al
   jmp @end
@no:
   xor al, al
@end:
end;

procedure Done; far;

function ErrorString (n: integer): string;
begin
     case n of
            1: ErrorString:='Invalid function number';
            2: ErrorString:='File not found';
            3: ErrorString:='Path not found';
            4: ErrorString:='Too many open files';
            5: ErrorString:='File access denied';
            6: ErrorString:='Invalid file handle';
           12: ErrorString:='Invalid file access code';
           15: ErrorString:='Invalid drive number';
           16: ErrorString:='Cannot remove current directory';
           17: ErrorString:='Cannot rename across drives';
          100: ErrorString:='Disk read error';
          101: ErrorString:='Disk write error';
          102: ErrorString:='File not assigned';
          103: ErrorString:='File not open';
          104: ErrorString:='File not open for input';
          105: ErrorString:='File not open for output';
          106: ErrorString:='Invalid numeric format';
          150: ErrorString:='Disk is write-protected';
          151: ErrorString:='Bad drive request struct length (655)';
          152: ErrorString:='Drive not ready';
          154: ErrorString:='CRC error in data';
          156: ErrorString:='Disk seek error';
          157: ErrorString:='Unknown media type';
          158: ErrorString:='Sector Not Found';
          159: ErrorString:='Printer out of paper';
          160: ErrorString:='Device write fault';
          161: ErrorString:='Device read fault';
          162: ErrorString:='Hardware failure';
          200: ErrorString:='Division by zero';
          201: ErrorString:='Range check error';
          202: ErrorString:='Stack overflow error';
          203: ErrorString:='Heap overflow error';
          204: ErrorString:='Invalid pointer operation';
          205: ErrorString:='Floating point overflow';
          206: ErrorString:='Floating point underflow';
          207: ErrorString:='Invalid floating point operation';
          208: ErrorString:='Overlay manager not installed';
          209: ErrorString:='Overlay file read error';
          210: ErrorString:='Object not initialized';
          211: ErrorString:='Call to abstract method';
          212: ErrorString:='Stream registration error';
          213: ErrorString:='Collection index out of range';
          214: ErrorString:='Collection overflow error';
          else ErrorString:='Unknown error'
     end
end;

function hexaddr (x: pointer): string;
var l: longint;
const hex: array [0..15] of char = '0123456789ABCDEF';
begin
     l := longint(x);
     hexaddr := hex[(l shr 28) and 15] +
                hex[(l shr 24) and 15] +
                hex[(l shr 20) and 15] +
                hex[(l shr 16) and 15] + ':' +
                hex[(l shr 12) and 15] +
                hex[(l shr  8) and 15] +
                hex[(l shr  4) and 15] +
                hex[(l shr  0) and 15]
end;



begin
     exitproc := oldexitproc;
     assign (f, 'SPONGES.DAT');
     rewrite (f, 1);
     blockwrite (f, sponges, spongesnum * sizeof(sponge));
     close (f);
     if erroraddr <> nil then begin
        asm
           mov ax, 0003h
           int 10h
        end;
        writeln ('Runtime error ', exitcode, ' occured at address ', hexaddr (erroraddr), '.');
        writeln ('Error: ', errorstring (exitcode));
        writeln ('Please contact me per email at divVerent+sponge@gmail.com!');
        writeln ('Version: ', VerStr)
     end;
     halt
end;

procedure ShowUsedBitmapWait;
begin
     vwait (1);
     ShowUsedBitmap
end;

procedure InitSponge;
begin
     oldexitproc := exitproc;
     exitproc := @done;

     assign (f, 'SPONGES.DAT');
     reset (f, 1);
     spongesnum := filesize(f) div sizeof(sponge);
     blockread (f, sponges, spongesnum * sizeof(sponge));
     close (f)
end;

function GetOptionString (c: char): string;
var n: byte;
    s: string;
begin
     GetOptionString := 'default';
     for n := 1 to paramcount do begin
         s := paramstr(n);
         if s[1] in ['-','/'] then s := copy (s, 2, byte(s[0])-1);
         if s[1] = c then begin
            if s[0] = #1 then
               GetOptionString := '+'
            else
               GetOptionString := copy (s, 2, byte(s[0])-1);
            exit
         end
     end
end;

end.
