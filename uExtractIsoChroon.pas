unit uExtractIsoChroon;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Mask, DUtils, OpWString, Math, uError;

type
  TForm1 = class(TForm)
    Label1: TLabel;
    EditWellLstFile: TEdit;
    OpenDialogWellLstFile: TOpenDialog;
    SaveDialog: TSaveDialog;
    Label2: TLabel;
    SaveButton: TButton;
    CheckBoxKleinerDan: TCheckBox;
    ComboBoxMinAquiferNr: TComboBox;
    Label3: TLabel;
    ComboBoxMaxAquiferNr: TComboBox;
    Label4: TLabel;
    ListBoxDays: TListBox;
    procedure ButtonSelectWellLstFileClick(Sender: TObject);
    procedure SaveButtonClick(Sender: TObject);
    procedure EditWellLstFileClick(Sender: TObject);
    procedure ComboBoxMaxAquiferNrExit(Sender: TObject);
    procedure ComboBoxMaxAquiferNrChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

procedure TForm1.ButtonSelectWellLstFileClick(Sender: TObject);
begin
  if OpenDialogWellLstFile.Execute then begin
    EditWellLstFile.Text := ExpandFileName( OpenDialogWellLstFile.FileName );
  end;
end;

procedure TForm1.SaveButtonClick(Sender: TObject);
Const
  WordDelims: CharSet = [' '];
var
  OutputTime, PrevTime, Time, X, Y : Double;
  MinAquifer, MaxAquifer, Len, aAquifer, RecNr: Integer;
  f, g, h: TextFile;
  WellListFile, MapFileName, ParFileName, Regel: String;

  Function TimeIsSelected( const PrevTime, Time: Double ): Boolean;
  var
    i: Integer;
    aTime: Double;
  begin
    Result := False;
    with ListBoxDays do begin
      for i := 0 to Count-1 do begin
        if selected[ i ] then begin
          aTime := StrToFloat( ListBoxDays.Items[ i ] );
          if ( CheckBoxKleinerDan.Checked and  (Time <= aTime )  ) or
            ( ( not CheckBoxKleinerDan.Checked ) and  ( (Time >= aTime) and ( PrevTime < aTime) ) ) then begin
            Result := True;
            Exit;
          end; {-if}
        end; {-if}
      end; {-for}
    end; {-with}
  end; {-function}

begin
  WellListFile := ExpandFileName( EditWellLstFile.Text );
  if not FileExists( WellListFile ) then begin
    MessageDlg( 'Well.lst file: "' + WellListFile + ' bestaat niet.', mtError, [mbOk], 0);
    Exit;
  end;
  Try
    MinAquifer := ComboBoxMinAquiferNr.ItemIndex+1;
    MaxAquifer := ComboBoxMaxAquiferNr.ItemIndex+1;
  except
    MessageDlg( 'Ongeldige waarde(n) voor aquifer.', mtError, [mbOk], 0);
    Exit;
  end;
  if ListBoxDays.selcount = 0 then begin
    MessageDlg( 'Geen isochroon waarde geselecteerd.', mtError, [mbOk], 0);
    Exit;
  end;

  if SaveDialog.Execute then begin
    MapFileName := ExpandFileName( SaveDialog.FileName );
    ParFileName := MapFileName;
    MapFileName := ChangeFileExt( MapFileName, '.ung' );
    ParFileName := ChangeFileExt( ParFileName, '.par' );
    AssignFile( f, MapFileName ); Rewrite( f );
    AssignFile( g, ParFileName ); Rewrite( g );
    AssignFile( h, WellListFile ); Reset( h);

    RecNr := 0;
    Readln( h, Regel );
    {TimeStr, xStr, yStr, AquiferStr}
    PrevTime := StrToFloat( ExtractWord( 2, Regel, WordDelims, Len ) );
    //WriteToLogFileFmt( '%g %g', [PrevTime, OutputTime] );
    while ( not EOF( h ) ) do begin
      Readln( h, Regel );
      {TimeStr, xStr, yStr, AquiferStr}
      Time := StrToFloat( ExtractWord( 2, Regel, WordDelims, Len ) );
      {Writeln( lf, Time:10:2, ' ', OutputTime:10:2 );}
      if TimeIsSelected( PrevTime, Time ) then begin
        {Writeln( lf, 'Gespecificeerde isochroon is gevonden.' );}
        aAquifer := StrToInt( ExtractWord( 6, Regel, WordDelims, Len ) );
        {Writeln( lf, aAquifer, ' ', Aquifer );}
        if ( aAquifer >= MinAquifer ) and ( aAquifer <= MaxAquifer ) then begin
          {Writeln( lf, 'Gespecificeerde aquifer is gevonden.' );}
          Inc( RecNr );
          X := StrToFloat( ExtractWord( 3, Regel, WordDelims, Len ) );
          Y := StrToFloat( ExtractWord( 4, Regel, WordDelims, Len ) );
          Writeln( f, RecNr, ' ', X:10:2, ' ', Y:10:2);
          Writeln( g, RecNr, ' ', Time );
        end;
      end;
      PrevTime := Time;
    end;
    Writeln( f, 'END' );
    CloseFile( h );
    CloseFile( f ); CloseFile( g );
    MessageDlg( 'Er zijn ' + IntToStr( RecNr ) + ' punten weggeschreven.',
               mtInformation, [mbOk], 0);
  end;
end;

procedure TForm1.ComboBoxMaxAquiferNrChange(Sender: TObject);
begin
  with ComboBoxMaxAquiferNr do
    ItemIndex := max( ComboBoxMinAquiferNr.ItemIndex, ComboBoxMaxAquiferNr.ItemIndex );
end;

procedure TForm1.ComboBoxMaxAquiferNrExit(Sender: TObject);
begin
  with ComboBoxMaxAquiferNr do
    ItemIndex := max( ComboBoxMinAquiferNr.ItemIndex, ComboBoxMaxAquiferNr.ItemIndex );
end;

procedure TForm1.EditWellLstFileClick(Sender: TObject);
begin
  if OpenDialogWellLstFile.Execute then begin
    EditWellLstFile.Text := ExpandFileName( OpenDialogWellLstFile.FileName );
  end;
end;


procedure TForm1.FormCreate(Sender: TObject);
begin
InitialiseLogFile;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
FinaliseLogFile;
end;

end.
