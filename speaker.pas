unit speaker;

{$DEFINE MODE2}

interface

  PROCEDURE PlayRAW (param: string);

implementation

uses dos;

VAR
  BytesRead:Word;
  BytesLeft: Longint;
  dataptr:pointer;
  f:file;

  PROCEDURE PlaySound(bufptr:pointer;bufctr:longint;ratediv,times:word)
;{assember;}
  var
    old_int8 : pointer;
    timesleft :word;
    savemask:byte;
  begin;
  ASM
        jmp     @PlayMain

  @int8_out_spk:
        xor     al,al
        out     42h,al
        mov     al,cl
        out     42h,al
        mov     ax,dx
        or      ax,si
        jz      @ready
        dec     bl
        jnz     @skip
        mov     bl,bh
        mov     al,es:[di]
{$IFDEF MODE2}
        xor     al, 80h
{$ENDIF}
        shr     al,1
        shr     al,1
        inc     al
        mov     cl,al
        inc     di
        jnz     @noseg
        mov     ax,es
        add     ax,1000h
        mov     es,ax
  @noseg:
        sub     si,+01
        sbb     dx,+00
  @skip:
        mov     al,20h
        out     20h,al
        iret
  @ready:
        mov     ch,0ffh
        jmp     @skip


  @PlayMain:
        cli
        mov     ax,3508h
        int     21h                    { get int vector 08 in es:bx }
        mov     word ptr old_int8,bx
        mov     word ptr old_int8+2,es
        in      al,21h                 { interruptmask }
        mov     savemask,al
        mov     al,0ffh                { disable all interrupts }
        out     21h,al
        sti
        push    ds
        mov     ax,cs
        mov     ds,ax
        mov     dx,offset @int8_out_spk
        mov     ax,2508h
        int     21h                    { set int vector 08 to ds:dx }
        pop     ds
        mov     al,34h
        out     43h,al                 { timer 0 mode }
        mov     al,36h                 { 22khz }
        out     40h,al
        xor     al,al
        out     40h,al
        mov     al,90h
        out     43h,al                 { timer 2 mode }
        in      al,61h                 { enable speaker }
        or      al,3
        out     61h,al
        mov     cx,times
        mov     timesleft,cx
        mov     cl,20h
        mov     bx,ratediv
        mov     bh,bl
        les     si,bufctr
        mov     dx,es
        les     di,bufptr
  @nexttime:
        push    di                     { bufptrlo }
        push    es                     { bufptrhi }
        push    si                     { bufctrlo }
        push    dx                     { bufctrhi }
        push    bx                     { ratediv  }
        xor     ch,ch                  { readyflag = false }
        mov     al,0feh                { enable timerinterrupt }
        out     21h,al
  @notready:
        or      ch,ch
        jz      @notready
        cli
        mov     al,0ffh                { disable all interrupts }
        out     21h,al
        sti
        pop     bx                     { ratediv }
        pop     dx                     { bufctrhi }
        pop     si                     { bufctrlo }
        pop     es                     { bufptrhi }
        pop     di                     { bufptrlo }
        dec     word ptr timesleft     { more times ? }
        jnz     @nexttime
        in      al,61h                 { disable speaker }
        and     al,0fch
        out     61h,al
        mov     al,34h
        out     43h,al                 { timer 0 mode }
        mov     al,0
        out     40h,al                 { timer 0 clock }
        out     40h,al                 { timer 0 clock }
        mov     al,0b6h
        out     43h,al                 { timer mode }
        mov     ax,533h
        out     42h,al                 { timer 2 spkr }
        mov     al,ah
        out     42h,al                 { timer 2 spkr }
        push    ds
        lds     dx,dword ptr old_int8
        mov     ax,2508h
        int     21h                    { set intrpt vector al to ds:dx }
        pop     ds
        mov     al,savemask            { enable timer and keyboard }
        out     21h,al
  END;
  end;


  const ChunkSize: Word = 32768;

  procedure PlayRAW (param: string);
  begin
       assign (f, param);
       reset (f, 1);
       DataPtr := nil;

       repeat
             getmem (DataPtr, ChunkSize);
             if DataPtr = nil then ChunkSize := ChunkSize shr 1
       until (DataPtr <> nil) or (ChunkSize = 1024);

       if DataPtr = nil then exit;

       BytesLeft := Filesize (f);

       repeat
             BlockRead (f, DataPtr^, ChunkSize, BytesRead);
             PlaySound(DataPtr, BytesRead, 2, 1);           {11025 Hz}
             BytesLeft := BytesLeft - BytesRead
       until (BytesLeft = 0) or (BytesRead = 0);

       freemem (DataPtr, ChunkSize);

       close (f)
  end;


BEGIN
END.
