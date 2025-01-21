uses InitSnd, SMix, TSponge;

var s: string;

begin
     s := initblaster;
     if s = '' then begin
        StartSound (Sounds[0], 1, false);
        delay (1000);
        repeat until keypressed or not soundplaying(1);
        exitblaster
     end else
        writeln (s);
end.