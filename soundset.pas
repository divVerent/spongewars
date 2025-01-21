{$M 16384, 32768, 32768}
{$G+,N+}

uses dos, tsponge;

function GetColor (FG, BG: Byte; Blink: Boolean): Byte; assembler;
asm
   mov al, blink
   mov bl, fg
   mov cl, bg
   and al, al
   jz @noblink
   add cl, 8
@noblink:
   shl cl, 4
   or bl, cl
   mov al, bl
end;

function GetPos (X, Y: Word): Word; assembler;
asm
   mov ax, y
   mov bx, 80
   xor dx, dx
   mul bx
   add ax, x
   shl ax, 1
end;

procedure WriteAt (P: Word; A: Byte; S: String); assembler;
asm
   push ds
   xor ch, ch
   lds bx, s
   mov cl, [bx]
   mov si, P
   mov ah, A
   push $B800
   pop es
@writechar:
   inc bx
   mov al, [bx]
   mov word ptr es:[si], ax
   inc si
   inc si
   loop @writechar
   pop ds
end;

procedure clrscr; assembler;
asm
   mov ax, $0700;
   push $B800
   pop es
   xor di, di
   mov cx, 80*25
   rep stosw
end;



var t: text;
    a, i, d: word;

const sMax = 3;
      sMin = 2;
      sInc = 1;
      sPos = 0;

      selectors: array [0..2, 0..3] of word = (
      (5, $10, $200, $2F0),
      (7, 1, 3, 15),
      (9, 1, 0, 7)
);

      svars: array [0..2] of ^word = (@a, @i, @d);

      active: byte = 0;


function hexstr (x: word): string;
const hex: array [0..15] of char = '0123456789ABCDEF';
var s: string;
begin

     s      := hex[x and $F000 shr 12] + hex[x and $0F00 shr 8]
             + hex[x and $00F0 shr 4]  + hex[x and $000F];
     while (s[0] <> #1) and (s[1] = '0') do s := copy (s, 2, 255);
     hexstr := s
end;

begin
     assign (t, 'TESTER.BAT');
     a := $220;
     i := $5;
     d := $1;
     clrscr;
     repeat
           writeat (GetPos(10, 2), GetColor (15,0, false), 'SOUND SET 1.0 by Rudolf Polzer');
           if active = 0
           then writeat (GetPos(10, 5), GetColor (15, 0, false), 'I/O port: ' + hexstr(a) + 'h')
           else writeat (GetPos(10, 5), GetColor (7, 0, false), 'I/O port: ' + hexstr(a) + 'h');
           if active = 1
           then writeat (GetPos(10, 7), GetColor (15, 0, false), 'IRQ:      ' + fstr(i) + 'd ')
           else writeat (GetPos(10, 7), GetColor (7, 0, false), 'IRQ:      ' + fstr(i) + 'd ');
           if active = 2
           then writeat (GetPos(10, 9), GetColor (15, 0, false), 'DMA:      ' + fstr(d) + 'd ')
           else writeat (GetPos(10, 9), GetColor (7, 0, false), 'DMA:      ' + fstr(d) + 'd ');
           writeat (GetPos(10, 12),GetColor (15,1, false), 'Test settings by <ENTER>');
           case readkey of
                #$48: active := (active + 2) mod 3;
                #$50: active := (active + 1) mod 3;
                #$4B: if svars[active]^ <> selectors[active, sMin] then dec (svars[active]^,selectors[active, sInc]);
                #$4D: if svars[active]^ <> selectors[active, sMax] then inc (svars[active]^,selectors[active, sInc]);
                #$1B: begin
                           clrscr;
                           halt
                end;
                #$0D: begin
                           rewrite (t);
                           writeln (t, '@echo off');
                           writeln (t, 'set blaster=A'+hexstr(a)+' I'+fstr(i)+' D'+fstr(d));
                           writeln (t, 'soundtst.exe');
                           close (t);
                           swapvectors;
                           exec (GetEnv('COMSPEC'), '/C TESTER.BAT');
                           swapvectors;
                           erase (t);
                           writeat (GetPos(10, 15), GetColor (14, 1, false), 'Did you hear the correct sound?');
                           if readkey in ['J','j','Y','y','Z','z'] then begin
                              assign (t, 'RUNME.BAT');
                              rewrite (t);
                              writeln (t, '@echo off');
                              writeln (t, 'set blaster=A'+hexstr(a)+' I'+fstr(i)+' D'+fstr(d));
                              writeln (t, 'sponge');
                              close (t);
                              clrscr;
                              halt
                           end;

                           clrscr
                end;


           end;
     until false
end.
