{
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒                                                     ▒▒
▒▒   Главная программы системы защиты, координирующая  ▒▒
▒▒   работу других модулей. Входит в комплект защиты   ▒▒
▒▒   от копирования.                                   ▒▒
▒▒                    (C) 1996  Колищак А.Н.           ▒▒
▒▒                                                     ▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
}


program Defence;
{$M 8192,8192,16192}
uses Dos, Crt, Objects, Drivers, Memory, Views, Menus, Dialogs,
  StdDlg, App , Strings;

const
     cmCrypt   = 100;
     cmHello   = 101;
var
   comm:array[1..15] of string[100];
function GetStartName:DirStr;
var
   s:PChar;
begin
  asm
    push es
    mov  ah,51h
    int  21h
    mov  es,bx
    mov  es,es:[2ch]
    xor  si,si
@rep:
    cmp  word ptr es:[si],0
    je   @end_rep
    inc  si
    jmp @rep
@end_rep:
    add  si,4
    mov  word ptr s,si
    mov  word ptr s+2,es
    pop  es
  end;
  GetStartName := StrPas(s);
end;
function GetStartDir:DirStr;
var
   s:DirStr;
   i:integer;
begin
  s := GetStartName;
  for i:=Length(s) downto 1
      do if s[i] = '\' then break;
  s[0] := chr(i-1);
  GetStartDir := s;
end;
function GetCurDir: DirStr; forward;
type
  PMyFileDialog = ^TMyFileDialog;
  TMyFileDialog = object(TFileDialog)
     constructor Init(AWildCard:TWildStr; const ATitle,
     InputName:string; AOptions:word; HistoryId:byte);
  end;
  PCryptorApp = ^TCryptorApp;
  TCryptorApp = object(TApplication)

    FileNameIn: FNameStr;
    FileNameOut:FNameStr;
    constructor Init;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure InitMenuBar; virtual;
    procedure MainDialog;
    procedure InitStatusLine; virtual;
{    procedure OutOfMemory; virtual;}
    procedure Hello;
  end;

constructor TmyFileDialog.Init(AWildCard:TWildStr;
               const ATitle, InputName:string;
                AOptions:word; HistoryId:byte);
var
   ScrollBar:PScrollBar;
   r:TRect;
{ Получение строки с названием текущего каталога }
begin
  { Создание окна диалога }
  r.Assign(15,1,64,20);
  TDialog.Init(r,ATitle);
  Options := Options or ofCentered;
  WildCard := AWildCard;

  { Строка ввода имени файла }
  r.Assign(3,3,31,4);
  FileName := New(PFileInputLine,Init(r,79));
  FileName^.Data^:=WildCard;
  Insert(FileName);
  r.Assign(2,2,6,3);
  Insert(New(PLabel,Init(r,InputName,FileName)));
  r.Assign(31,3,34,4);
  Insert(New(PHistory,Init(r,FileName,HistoryId)));
  { Линейка скролинга и список файлов }
  r.Assign(3,14,34,15);
  ScrollBar := New(PScrollBar,Init(r));
  Insert(ScrollBar);
  r.Assign(3,6,34,14);
  FileList := New(PFileList,Init(r,ScrollBar));
  Insert(FileList);
  r.Assign(2,5,8,6);
  Insert(New(PLabel,Init(r,'Файлы',FileList)));

  { Задание кнопок }
  r.Assign(35,3,46,5);
  if AOptions and fdOpenButton <> 0 then
     begin
       Insert(New(PButton,Init(
             r,'Открыть',cmFileOpen,bfDefault)));
       Inc(r.A.Y,3); Inc(r.B.Y,3);
     end;
  Insert(New(PButton,Init(
        r,'Отмена',cmCancel,bfNormal)));
  { Информационная панель с параметрами файла }
  r.Assign(1,16,48,18);
  Insert(New(PFileInfoPane,Init(r)));

  SelectNext(True);

  { Загрузка каталога }
  if AOptions and fdNoLoadDir = 0 then
     begin
       FileList^.ReadDirectory(WildCard);
       Directory := NewStr(GetCurDir);
     end;
end;

constructor TCryptorApp.Init;
begin
  inherited Init;

end;
procedure TCryptorApp.HandleEvent(var Event: TEvent);

procedure Crypting(FirstFileName:FNameStr);
var
  c:char;
begin
  FileNameIn := FirstFileName;
  if ExecuteDialog(New(PMyFileDialog, Init(FirstFileName, 'Выберете файл',
    '~И~мя', fdOpenButton, 100)), @FileNameIn) <> cmCancel then
  begin
    MainDialog;
  end
end;
begin
  inherited HandleEvent(Event);
  case Event.What of
    evCommand:
      case Event.Command of
        cmCrypt  : begin Crypting('*.*') end;
        cmHello: Hello;
      else
        Exit;
      end;
  else
    Exit;
  end;
  ClearEvent(Event);
end;
procedure TCryptorApp.InitMenuBar;
var
  R: TRect;
begin
  GetExtent(R);
  R.B.Y := R.A.Y + 1;
  MenuBar := New(PMenuBar, Init(R, NewMenu(
    NewSubMenu('~Ф~айл', hcNoContext, NewMenu(
      NewItem('~П~ривязка      ', 'F2', kbF2, cmCrypt, hcNoContext,
      NewItem('~О~ программе      ', '', kbF1, cmHello, hcNoContext,
      NewItem('~В~ыход DOS      ', '', kbNoKey, cmDosShell, hcNoContext,
      NewItem('~З~авершение      ', 'Alt+X', kbAltX, cmQuit, hcNoContext,
      nil))))),nil))))
end;
procedure TCryptorApp.MainDialog;

const
     steps = 13;
var
  complete:string;
  i:integer;
  r:TRect;
  Dialog:PDialog;
   ParamText1,ParamText2:PParamText;
   ParText:record
            Par:pointer
   end;
  kComplete:real;
  s,StartDir,command,OldDir,bakfile:string[150];
  comspec:boolean;
function CompleteStr(num:word;ch:char):string;
var
   i:word;
   s:string;
begin
  s := Complete;
  for i:=1 to num do s[i]:=ch;
  CompleteStr := s;
end;
function fulfil(name:string):boolean;
var
  D: PDialog;
  R: TRect;

begin
  SwapVectors;
  Exec(command,'/C'+ name);
  SwapVectors;
  if DosError <> 0 then
  begin
    R.Assign(0, 0, 40, 11);
    D := New(PDialog, Init(R, 'Ошибка'));
    with D^ do
    begin
      Options := Options or ofCentered;
      R.Grow(-1, -1);
      Dec(R.B.Y, 3);
      Insert(New(PStaticText, Init(R,
      #13 +
      ^C'Отсутствует доступ '#13 +
      #13 +
      ^C'к файлу :'+
      #13 +
      ^C''+name)));

       R.Assign(15, 8, 25, 10);
       Insert(New(PButton, Init(R, 'O~K', cmOk, bfDefault)));
     end;
     if ValidView(D) <> nil then
     begin
       Desktop^.ExecView(D);
       Dispose(D, Done);
     end;
     fulfil := false
  end
  else fulfil := true
end;
var
   ext:boolean;
begin
  Complete := '';
  for i:=1 to 56 do Complete := Complete + '░';
  r.Assign(10,6,70,12);
  Dialog := New(PDialog,Init(r,'Выполнено'));
  r.Assign(2,2,58,3);
  ParamText1 := New(PParamText,Init(r,'%s',1));
  Dialog^.Insert(ParamText1);
  r.Assign(2,3,58,4);
  ParamText2 := New(PParamText,Init(r,'%s',1));
  Dialog^.Insert(ParamText2);
  ParText.Par := @Complete;
  ParamText1^.SetData(ParText);
  ParamText2^.SetData(ParText);
  DeskTop^.Insert(Dialog);

  StartDir := GetStartDir;
  kComplete := 56 / steps;
  {есть ли COMSPEC ?}
  comspec := false;
  command := 'C:\COMMAND.COM';
  for i := 1 to EnvCount do
  begin
    s := EnvStr(i);
    s[0] := chr(7);
    if s = 'COMSPEC' then begin
       comspec := true;
       command := GetEnv('COMSPEC');
       break;
    end
  end;
  ext := false;
  bakfile := FileNameIn;
  for i:= Length(bakfile) downto 1
     do if bakfile[i] = '.' then begin
           ext := true;
           break;
        end;
  if ext then begin
    bakfile[0] := chr(i);
    bakfile := bakfile + 'bak';
  end
  else bakfile := bakfile + 'bak';

  GetDir(0,OldDir);
  ChDir(StartDir);
  comm[1]  := 'copy '+FileNameIn+' '+bakfile+' >nul';
  comm[2]  := 'copy '+FileNameIn+ ' asd.exe >nul';
  comm[3]  := 'unp asd.exe >nul';
  comm[4]  := 'unp x asd.exe >nul';
  comm[5]  := 'copy tail.org tail.com >nul';
  comm[6]  := '';{'trace.com >nul';}
  comm[7]  := 'encrypt.com >nul';
  comm[8]  := 'com2end asd.exe tail.com >nul';
  comm[9]  := 'del tail.com >nul';
  comm[10]  :='dcrypt asd.exe >nul';
  comm[11] := 'del asd.bak >nul';
  comm[12] := 'copy asd.exe '+FileNameIn +' >nul';
  comm[13] := 'del asd.exe >nul';
  for i := 1 to steps do
  begin
    if not fulfil(comm[i]) then exit;
    if i = 6 then begin
       DeskTop^.draw;
       MenuBar^.draw;
       StatusLine^.draw;
    end;
    Complete := CompleteStr(Round(kComplete*i),'▓');
    ParamText1^.SetData(ParText);
    ParamText2^.SetData(ParText);
  end;
  Dispose(Dialog,Done);
  ChDir(OldDir);
end;

procedure TCryptorApp.InitStatusLine;
var
  R: TRect;
begin
  GetExtent(R);
  R.A.Y := R.B.Y - 1;
  New(StatusLine, Init(R,
    NewStatusDef(0, $FFFF,
      NewStatusKey('~F2~ Привязать файл к машине', kbF2, cmCrypt,
      NewStatusKey('', kbF10, cmMenu,
      nil)),
    nil)));
end;

procedure TCryptorApp.Hello;
var
  D: PDialog;
{  Control: PView;}
  R: TRect;
begin
  R.Assign(0, 0, 40, 11);
  D := New(PDialog, Init(R, 'О программе'));
  with D^ do
  begin
    Options := Options or ofCentered;

    R.Grow(-1, -1);
    Dec(R.B.Y, 3);
    Insert(New(PStaticText, Init(R,
      #13 +
      ^C'Защита программ от копирования'#13 +
      #13 +
      ^C'Copyright (c) 1996'#13 +
      #13 +
      ^C'Колищак А.Н. v 1.0')));

    R.Assign(15, 8, 25, 10);
    Insert(New(PButton, Init(R, 'O~K', cmOk, bfDefault)));
  end;
  if ValidView(D) <> nil then
  begin
    Desktop^.ExecView(D);
    Dispose(D, Done);
  end;

end;

var
  CryptorApp:TCryptorApp;
function GetCurDir: DirStr;
var
   CurDir:DirStr;
begin
  GetDir(0,CurDir);
  if Length(CurDir) > 3 then
     begin
       Inc(CurDir[0]);
       CurDir[Length(CurDir)] := '\'
     end;
   GetCurDir := CurDir;
end;


begin
  CryptorApp.Init;
  CryptorApp.Run;
  CryptorApp.Done;
end.


