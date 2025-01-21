unit SpEdit;    {$I-,O+}

interface

procedure Main;

implementation

uses TSponge;

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

const mysponge: sponge =
      (weight: 5.0; r: 0.1; Damage: 400;
       FallDownDamage: 300;Cost: 0; ES: 3;
       SpongeNum: 1; Exactness: 8; IsDigger: False;
       IsDBomb: False; Shape: 0; Description: 'DrySponge');

var activeselector: byte;
    spongenum: byte;
    m: single;

const helptexts: array [0..9] of string[80] = (
'The actually selected sponge. TAB loads, RETURN saves and DEL deletes it',
'The slowdown coefficent                                                 ',
'The damage caused when hit by this sponge on one pixel                  ',
'The damage caused when falling down one pixel                           ',
'The explosion circle size. Self-explaining :-)                          ',
'Throw more sponges at a time. Very expensive!                           ',
'Exactness of a spongethrow. Not very cheap, too!                        ',
'The SpongeType. Possible: NORM, DIGGER, DIRT, COMBO                     ',
'The Shape. Possible: ROUND, SQUARE, STAR                                ',
'The sponge''s name. MAX. 15 CHARS!                                       '
);
      ShapeName: array [0..2] of string[8] = ('ROUND', 'SQUARE', 'STAR');


procedure GetCost;

var i, k: shortint;
begin

     with MySponge do begin
          m := 0;
          for i := -4 to 4 do for k := -4 to 4 do if sqrt(i*i+k*k) <= ES then
              m := m + 1;
          m := SpongeNum * (damage * m + falldowndamage * 2 * es);
          cost := (m + 1000) * (100 + 1.0 * ES * ES * SpongeNum * SpongeNum / (0.001 + Exactness)) / 500;
          if Shape=sSquare then cost := cost * 4 / Pi;
          if (Shape=sStar) and not isdigger then cost := cost / 2.8;
          if isdbomb then cost := cost * 3.8;
          if isdigger then cost := cost * 5.3;
          weight := sqrt(cost) / 200 * (1 - r / 2);
          if m >= 75000 then
             cost := cost + m + 100000 - 75000;
          if cost < 1000 then cost := 0
     end
end;

function GetSpType (var s: Sponge): string;
begin
        if s.IsDBomb then
           if s.IsDigger then
              GetSpType := 'COMBO'
           else
              GetSpType := 'DIRT'
        else
           if s.IsDigger then
              GetSpType := 'DIGGER'
           else
              GetSpType := 'NORM'
end;

procedure view;
begin
     GetCost;
     clrscr;
     writeat (GetPos(3,0), GetColor(14,0,false), '--- Sponge Editor ---');
     if activeselector = 0 then
        writeat (GetPos(3,2), GetColor(15,0,false), 'Actual sponge: '+fstr(spongenum+1        )+' of '+fstr(countsponges))
     else
        writeat (GetPos(3,2), GetColor( 7,0,false), 'Actual sponge: '+fstr(spongenum+1        )+' of '+fstr(countsponges));
        writeat (GetPos(3,3), GetColor( 8,0,false), 'Weight:        '+fstr(mysponge.weight*1000   ));
     if activeselector = 1 then
        writeat (GetPos(3,4), GetColor(15,0,false), 'R:             '+fstr(mysponge.r*1000        ))
     else
        writeat (GetPos(3,4), GetColor( 7,0,false), 'R:             '+fstr(mysponge.r*1000        ));
     if activeselector = 2 then
        writeat (GetPos(3,5), GetColor(15,0,false), 'Damage:        '+fstr(mysponge.damage   ))
     else
        writeat (GetPos(3,5), GetColor( 7,0,false), 'Damage:        '+fstr(mysponge.damage   ));
     if activeselector = 3 then
        writeat (GetPos(3,6), GetColor(15,0,false), 'FDown Damage:  '+fstr(mysponge.falldowndamage   ))
     else
        writeat (GetPos(3,6), GetColor( 7,0,false), 'FDown Damage:  '+fstr(mysponge.falldowndamage   ));
     if m < 75000 then
        writeat (GetPos(3,7), GetColor( 8,0,false), 'Max. Damage:   '+fstr(m                 ))
     else
        writeat (GetPos(3,7), GetColor(14,4,false), 'Max. Damage:   '+fstr(m                 ));

     if mysponge.cost <= 100000 then
        writeat (GetPos(3,8), GetColor( 8,0,false), 'Costs:         '+fstr(mysponge.cost     ))
     else
        writeat (GetPos(3,8), GetColor(14,4,false), 'Costs:         '+fstr(mysponge.cost     ));
     if activeselector = 4 then
        writeat (GetPos(3,9), GetColor(15,0,false), 'ExplosionSize: '+fstr(mysponge.es       ))
     else
        writeat (GetPos(3,9), GetColor( 7,0,false), 'ExplosionSize: '+fstr(mysponge.es       ));
     if activeselector = 5 then
        writeat (GetPos(3,10), GetColor(15,0,false), 'MultiSponge:   '+fstr(mysponge.spongenum))
     else
        writeat (GetPos(3,10), GetColor( 7,0,false), 'MultiSponge:   '+fstr(mysponge.spongenum));
     if activeselector = 6 then
        writeat (GetPos(3,11), GetColor(15,0,false), 'Exactness:     '+fstr(mysponge.exactness*10))
     else
        writeat (GetPos(3,11), GetColor( 7,0,false), 'Exactness:     '+fstr(mysponge.exactness*10));
     if activeselector = 7 then
        writeat (GetPos(3,12), GetColor(15,0,false), 'Type:          '+getsptype(mysponge))
     else
        writeat (GetPos(3,12), GetColor( 7,0,false), 'Type:          '+getsptype(mysponge));
     if activeselector = 8 then
        writeat (GetPos(3,13), GetColor(15,0,false), 'Shape:         '+shapename[mysponge.shape])
     else
        writeat (GetPos(3,13), GetColor( 7,0,false), 'Shape:         '+shapename[mysponge.shape]);
     if activeselector = 9 then
        writeat (GetPos(3,14), GetColor(15,0,false), 'Description:   '+mysponge.description+'               ')
     else
        writeat (GetPos(3,14), GetColor( 7,0,false), 'Description:   '+mysponge.description+'               ');

     writeat (GetPos (3, 17), GetColor(14,1,false), helptexts[activeselector])
end;

procedure Main;

var c: char;


begin
     If CountSponges <> 0 then GetSponge (0, MySponge);
     spongenum := 0;
     clrscr;
     activeselector := 0;
     repeat
           view;
           case readkey of
                #$0D: if activeselector = 0 then PutSponge (spongenum, mysponge) else
                      if activeselector = 9 then begin
                         repeat
                               view;
                               c := readkey;
                               case c of
                                    #$0D: ;
                                    #$08: if mysponge.description[0] <> #0 then dec (byte(mysponge.description[0]));
                                          else if mysponge.description[0] <> #15 then mysponge.description :=
                                               mysponge.description + c
                                          else write (^g)
                                 end
                         until c = #$0D
                      end;
                #$50: inc (activeselector);
                #$48: dec (activeselector);
                #$09: if (activeselector = 0) and (spongenum < countsponges) then GetSponge (spongenum, mysponge);
                #$4B: case activeselector of
                           0: if spongenum  >= 1 then dec (spongenum);
                           1: if mysponge.r >= 0.001 then mysponge.r := mysponge.r - 0.001;
                           2: if mysponge.damage >= 5 then mysponge.damage := mysponge.damage - 5;
                           3: if mysponge.falldowndamage >= 5 then mysponge.falldowndamage := mysponge.falldowndamage - 5;
                           4: if mysponge.es >= 3 then dec(mysponge.es);
                           5: if mysponge.spongenum >= 2 then dec(mysponge.spongenum);
                           6: if mysponge.exactness >= 0.2 then mysponge.exactness := mysponge.exactness - 0.1;
                           7: with mysponge do begin
                                   isdigger := not isdigger;
                                   if isdigger then
                                      isdbomb := not isdbomb
                           end;
                           8: mysponge.shape := (mysponge.shape + 2) mod 3

                      end;
                #$4D: case activeselector of
                           0: if spongenum <> countsponges then inc (spongenum);
                           1: if mysponge.r <= 0.999 then mysponge.r := mysponge.r + 0.001;
                           2: if mysponge.damage <= 995 then mysponge.damage := mysponge.damage + 5;
                           3: if mysponge.falldowndamage <= 995 then mysponge.falldowndamage := mysponge.falldowndamage + 5;
                           4: if mysponge.es <= 99 then inc(mysponge.es);
                           5: if mysponge.spongenum <= 19 then inc(mysponge.spongenum);
                           6: if mysponge.exactness <= 9.9 then mysponge.exactness := mysponge.exactness + 0.1;
                           7: with mysponge do begin
                                   isdigger := not isdigger;
                                   if not isdigger then
                                      isdbomb := not isdbomb
                           end;
                           8: mysponge.shape := (mysponge.shape + 1) mod 3
                      end;
                #$73: case activeselector of
                           0: if spongenum  >= 1 then dec (spongenum);
                           1: if mysponge.r >= 0.02 then mysponge.r := mysponge.r - 0.02;
                           2: if mysponge.damage >= 50 then mysponge.damage := mysponge.damage - 50;
                           3: if mysponge.falldowndamage >= 50 then mysponge.falldowndamage := mysponge.falldowndamage - 50;
                           4: if mysponge.es >= 12 then dec(mysponge.es, 10);
                           5: if mysponge.spongenum >= 2 then dec(mysponge.spongenum);
                           6: if mysponge.exactness >= 1.1 then mysponge.exactness := mysponge.exactness - 1;
                           7: if not mysponge.isdigger then begin
                                 mysponge.isdigger := true;
                                 mysponge.isdbomb := not mysponge.isdbomb
                              end else
                                 mysponge.isdigger := false
                      end;
                #$74: case activeselector of
                           0: if spongenum <> countsponges then inc (spongenum);
                           1: if mysponge.r <= 0.98 then mysponge.r := mysponge.r + 0.02;
                           2: if mysponge.damage <= 950 then mysponge.damage := mysponge.damage + 50;
                           3: if mysponge.falldowndamage <= 950 then mysponge.falldowndamage := mysponge.falldowndamage + 50;
                           4: if mysponge.es <= 90 then inc(mysponge.es, 10);
                           5: if mysponge.spongenum <= 19 then inc(mysponge.spongenum);
                           6: if mysponge.exactness <= 9.0 then mysponge.exactness := mysponge.exactness + 1;
                           7: if mysponge.isdigger then begin
                                 mysponge.isdigger := false;
                                 mysponge.isdbomb := not mysponge.isdbomb
                              end else
                                 mysponge.isdigger := true
                      end;
                #$1B: begin
                           clrscr;
                           exit
                      end;
                #$53: if (activeselector = 0) and (spongenum < countsponges) then RemoveSponge (spongenum)
           end;
           if activeselector = 255 then activeselector := 9;
           if activeselector = 10 then activeselector := 0

     until false
end;

end.