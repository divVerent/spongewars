{$I-,O+}
uses KOJAKVGA, TSponge;

const ThisImage: PlayerImage = (
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

var color, oc: byte;
    ox, oy, cx, cy: integer;
    c: char;
    b: pointer;
    f: file of playerimage;


procedure View;
var x, y: integer;
begin
     usecolour(0);
     rectangle ((oc div 5) * 5 + 16,
                (oc mod 5) * 5 + 170,
                (oc div 5) * 5 + 21,
                (oc mod 5) * 5 + 175);
     rectangle ((ox+5)*16-1, (oy+5)*16-1, (ox+5)*16+15, (oy+5)*16+15);
     for y := -4 to 4 do
         for x := -4 to 4 do if ThisImage [x, y] = 255 then begin
             fillarea ((x+5) * 16, (y+5) * 16, (x+5) * 16 + 14, (y+5) * 16 + 14, 0);
             fillarea ((x+5) * 16, (y+5) * 16, (x+5) * 16 + 6, (y+5) * 16 + 6, 8);
             fillarea ((x+5) * 16 + 8, (y+5) * 16 + 8, (x+5) * 16 + 14, (y+5) * 16 + 14, 8);
             fillarea ((x+5) * 16 + 8, (y+5) * 16, (x+5) * 16 + 14, (y+5) * 16 + 6, 7);
             fillarea ((x+5) * 16, (y+5) * 16 + 8, (x+5) * 16 + 6, (y+5) * 16 + 14, 7)
         end else
             fillarea ((x+5) * 16, (y+5) * 16, (x+5) * 16 + 14, (y+5) * 16 + 14, ThisImage [x, y] + 64);
     fillarea (199, 0, 319, 199, color + 64);
     usecolour(15);
     rectangle ((cx+5)*16-1, (cy+5)*16-1, (cx+5)*16+15, (cy+5)*16+15);
     for x := 0 to 124 do
         fillarea ((x div 5) * 5 + 17, (x mod 5) * 5 + 171, (x div 5) * 5 + 20, (x mod 5) * 5 + 174, x + 64);
     rectangle ((color div 5) * 5 + 16,
                (color mod 5) * 5 + 170,
                (color div 5) * 5 + 21,
                (color mod 5) * 5 + 175);
     ShowUsedBitmap
end;

 
begin
     assign (f, paramstr(1));
     reset (f);
     read (f, thisimage);
     close (f);
     InitVGAMode;
     b := New64kBitmap;
     UseBitmap (b);
     Cls;
     InitPalette;

     cx := 0;
     cy := 0;
     ox := 0;
     oy := 0;
     color := 0;
     oc := 0;

     repeat
           View;
           ox := cx;
           oy := cy;
           oc := color;
           c := readkey;
           case c of
                #$1B: ;
                #$20: ThisImage [cx, cy] := color;
                #$4B: if cx <> -4 then dec (cx);
                #$4D: if cx <> 4 then inc (cx);
                #$48: if cy <> -4 then dec (cy);
                #$50: if cy <> 4 then inc (cy);
                #$53: ThisImage [cx, cy] := 255;
                'r': Color := (Color div 5) * 5 + (Color mod 5 + 1) mod 5;
                'R': Color := (Color div 5) * 5 + (Color mod 5 + 4) mod 5;
                'g': Color := (Color div 25) * 25 + Color mod 5 + (((Color div 5) mod 5 + 1) mod 5) * 5;
                'G': Color := (Color div 25) * 25 + Color mod 5 + (((Color div 5) mod 5 + 4) mod 5) * 5;
                'b': Color := Color mod 25 + 25 * ((Color div 25 + 1) mod 5);
                'B': Color := Color mod 25 + 25 * ((Color div 25 + 4) mod 5);
                #$08: Color := ThisImage [cx, cy];
                'n': begin
                          for cx := -4 to 4 do
                              for cy := -4 to 4 do
                                  ThisImage [cx, cy] := 255;
                          cx := 0;
                          cy := 0
                     end;
                #$0D: begin
                           assign (f, paramstr(1));
                           rewrite (f);
                           write (f, thisimage);
                           close (f)
                      end
           end
     until c = #$1B;

     freebitmap(b);

     asm
        mov ax, 0003h
        int 10h
     end
end.
