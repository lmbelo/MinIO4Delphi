unit Main.Form;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.ComCtrls, Vcl.StdCtrls,
  Data.Cloud.MinIO, Data.Cloud.CloudAPI, Data.Cloud.AmazonAPI;

type
  TMainForm = class(TForm)
    btnListBuckets: TButton;
    btnListFiles: TButton;
    btnUpload: TButton;
    btnDownload: TButton;
    btnDelete: TButton;
    btnCreateBucket: TButton;
    btnDeleteBucket: TButton;
    lbBuckets: TListBox;
    btnClear: TButton;
    lvBucketFiles: TListView;
    pnlConnInfo: TPanel;
    Label3: TLabel;
    Label4: TLabel;
    btnConnect: TButton;
    editAccessKey: TEdit;
    editSecretKey: TEdit;
    OpenDialog1: TOpenDialog;
    Label2: TLabel;
    editEndereco: TEdit;
    edPrefix: TEdit;
    lbPrefix: TLabel;
    lbMax: TLabel;
    edMax: TEdit;
    SaveDialog1: TSaveDialog;
    pnlStorageService: TPanel;
    StatusBar1: TStatusBar;
    procedure btnConnectClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnListBucketsClick(Sender: TObject);
    procedure lbBucketsClick(Sender: TObject);
    procedure btnListFilesClick(Sender: TObject);
    procedure btnUploadClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnDownloadClick(Sender: TObject);
    procedure btnCreateBucketClick(Sender: TObject);
    procedure btnDeleteBucketClick(Sender: TObject);
  private
    FConnectionInfo: TMinIOConnectionInfo;
    FStorageService: TMinIOStorageService;
  private
    procedure CheckConnected();
    procedure ListBuckets();
    procedure CreateBucket(const ABucketName: string);
    procedure DeleteBucket(const ABucketName: string);
    procedure ListFiles(const ABucketName: string);
    procedure UploadFile(const ABucketName, ALocalFileName, ARemoteFileName: string);
    procedure DownloadFile(const ABucketName, ALocalFileName, ARemoteFileName: string);
    procedure DeleteFile(const ABucketName, ARemoteFileName: string);
    procedure ClearBucket(const ABucketName: string);

    function GetSelectedBucket(): string;
    function GetSelectedFile(): string;

    procedure CheckOperation(const AEval: boolean; const AResponseInfo: TCloudResponseInfo);
    procedure RaiseUnableToCompleteOp(const AStatusCode: integer; const AStatusMessage: string);
  end;

  ENotConnected = class(Exception);
  EFailedToConnect = class(Exception);
  ENoBucketSelected = class(Exception);
  ENoBucketFileSelected = class(Exception);
  EMinIOOperationFailed = class(Exception);

var
  MainForm: TMainForm;

implementation

uses
  System.IOUtils;

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FConnectionInfo := TMinIOConnectionInfo.Create(Self);
  FConnectionInfo.UseDefaultEndPoints := false;
  pnlStorageService.Enabled := false;
end;

procedure TMainForm.btnClearClick(Sender: TObject);
begin
  ClearBucket(GetSelectedBucket());
  ShowMessage('Cleaned successfully.');
  ListFiles(GetSelectedBucket());
end;

procedure TMainForm.btnConnectClick(Sender: TObject);
begin
  FConnectionInfo.StorageEndPoint := editEndereco.text;
  FConnectionInfo.AccountName := editAccessKey.text;
  FConnectionInfo.AccountKey := editSecretKey.text;
  FStorageService := TMinIOStorageService.Create(FConnectionInfo);

  try
    ListBuckets();
    pnlStorageService.Enabled := true;
    StatusBar1.Panels[0].Text := 'Connected!';
  except
    on E: Exception do begin
      StatusBar1.Panels[0].Text := 'Failed to connect.';
      raise EFailedToConnect.Create(
        'Failed to connect: '
        + sLineBreak
        + E.Message);
    end;
  end;
end;

procedure TMainForm.btnCreateBucketClick(Sender: TObject);
var
  LBucketName: string;
begin
  CheckConnected();
  if InputQuery('New bucket', 'Bucket name', LBucketName) then
    CreateBucket(LBucketName);
  ListBuckets();
end;

procedure TMainForm.btnDeleteBucketClick(Sender: TObject);
begin
  CheckConnected();
  DeleteBucket(GetSelectedBucket());
  ShowMessage('Deleted successfully.');
  ListBuckets();
end;

procedure TMainForm.btnDeleteClick(Sender: TObject);
begin
  CheckConnected();
  DeleteFile(GetSelectedBucket(), GetSelectedFile());
  MessageDlg('Deleted successfully.', mtInformation, [mbOk], 0);
  ListFiles(GetSelectedBucket());
end;

procedure TMainForm.btnDownloadClick(Sender: TObject);
begin
  CheckConnected();

  SaveDialog1.FileName := GetSelectedFile();
  if not SaveDialog1.Execute then
    Exit;

  DownloadFile(
    GetSelectedBucket(),
    SaveDialog1.FileName,
    GetSelectedFile());

  MessageDlg('Download complete.', mtInformation, [mbOk], 0);
end;

procedure TMainForm.btnListBucketsClick(Sender: TObject);
begin
  CheckConnected();
  ListBuckets();
end;

procedure TMainForm.btnListFilesClick(Sender: TObject);
begin
  CheckConnected();
  ListFiles(GetSelectedBucket());
end;

procedure TMainForm.btnUploadClick(Sender: TObject);
begin
  CheckConnected();
  if not OpenDialog1.Execute then
    Exit;

  UploadFile(
    GetSelectedBucket(),
    OpenDialog1.FileName,
    TPath.GetFileName(OpenDialog1.FileName));

  MessageDlg('Upload complete.', mtInformation, [mbOk], 0);

  ListFiles(GetSelectedBucket());
end;

procedure TMainForm.lbBucketsClick(Sender: TObject);
begin
  if lbBuckets.ItemIndex <> -1 then
    ListFiles(GetSelectedBucket());
end;

procedure TMainForm.CheckConnected;
begin
  if not Assigned(FStorageService) then
    raise ENotConnected.Create('Please, conenct first!');
end;

procedure TMainForm.ListBuckets;
begin
  var LResponseInfo := TCloudResponseInfo.Create;
  try
    lbBuckets.Items.Clear;
    var LBucketList := FStorageService.ListBuckets(LResponseInfo);
    try
      CheckOperation(not Assigned(LBucketList), LResponseInfo);

      for var I := 0 to Pred(LBucketList.Count) do
        lbBuckets.Items.Add(LBucketList.Names[I]);
    finally
      LBucketList.Free;
    end;
  finally
    LResponseInfo.Free;
  end;
end;

procedure TMainForm.CreateBucket(const ABucketName: string);
begin
  var LResponseInfo := TCloudResponseInfo.Create;
  try
    CheckOperation(
      not FStorageService.CreateBucket(
        ABucketName, TAmazonACLType.amzbaPrivate, String.Empty, LResponseInfo),
      LResponseInfo);
  finally
    LResponseInfo.Free();
  end;
end;

procedure TMainForm.DeleteBucket(const ABucketName: string);
begin
  var LResponseInfo := TCloudResponseInfo.Create;
  try
    CheckOperation(
      not FStorageService.DeleteBucket(ABucketName, LResponseInfo),
      LResponseInfo);
  finally
    LResponseInfo.Free();
  end;
end;

procedure TMainForm.ClearBucket(const ABucketName: string);
begin
  var LResponseInfo := TCloudResponseInfo.Create();
  try
    var LBucketInfo := FStorageService.GetBucket(ABucketName, nil, LResponseInfo);

    CheckOperation(not Assigned(LBucketInfo), LResponseInfo);

    for var LObjectInfo in LBucketInfo.Objects do
      DeleteFile(ABucketName, LObjectInfo.Name);
  finally
    LResponseInfo.Free();
  end;
end;

procedure TMainForm.ListFiles(const ABucketName: string);
begin
  lvBucketFiles.Clear();

  var LOptionalParams := TStringList.Create();
  try
    LOptionalParams.Values['delimiter'] := '/';
    if (edPrefix.text <> '') then
      LOptionalParams.Values['prefix'] := edPrefix.text;

    if (edMax.text <> '') then
      LOptionalParams.Values['max-keys'] := edMax.text;

    var LResponseInfo := TCloudResponseInfo.Create();
    try
      var LBucketInfo := FStorageService.GetBucket(
        ABucketName, LOptionalParams, LResponseInfo);

      CheckOperation(not Assigned(LBucketInfo), LResponseInfo);

      for var LObjectInfo in LBucketInfo.Objects do begin
        var LItem := lvBucketFiles.Items.Add();
        LItem.Caption := LObjectInfo.Name;
        LItem.SubItems.Add(IntToStr(LObjectInfo.Size));
        LItem.SubItems.Add(LObjectInfo.LastModified);
      end;

      for var LPrefix in LBucketInfo.Prefixes do
      begin
        var LItem := lvBucketFiles.Items.Add();
        LItem.Caption := LPrefix;
      end;
    finally
      LResponseInfo.Free();
    end;
  finally
    LOptionalParams.Free();
  end;
end;

procedure TMainForm.UploadFile(const ABucketName, ALocalFileName,
  ARemoteFileName: string);
begin
  FStorageService.UploadFile(ABucketName, ALocalFileName, ARemoteFileName);
end;

procedure TMainForm.DownloadFile(const ABucketName, ALocalFileName,
  ARemoteFileName: string);
begin
  var LStream := TFileStream.Create(ALocalFileName, fmCreate or fmOpenWrite);
  try
    var LResponseInfo := TCloudResponseInfo.Create();
    try
      CheckOperation(
        not FStorageService.GetObject(
          ABucketName, ARemoteFileName, LStream, LResponseInfo),
        LResponseInfo);
    finally
      LResponseInfo.Free();
    end;
  finally
    LStream.Free();
  end;
end;

procedure TMainForm.DeleteFile(const ABucketName, ARemoteFileName: string);
begin
  var LResponseInfo := TCloudResponseInfo.Create();
  try
    CheckOperation(
      not FStorageService.DeleteObject(
        ABucketName, ARemoteFileName, LResponseInfo),
      LResponseInfo);
  finally
    LResponseInfo.Free();
  end;
end;

function TMainForm.GetSelectedBucket: string;
begin
  if (lbBuckets.ItemIndex < 0) then
    raise ENoBucketSelected.Create('Please, select a bucket in the list.');

  Result := lbBuckets.Items[lbBuckets.ItemIndex];
end;

function TMainForm.GetSelectedFile: string;
begin
  if not Assigned(lvBucketFiles.Selected) then
    raise ENoBucketFileSelected.Create(
      'Please, select a file in the bucket files list.');

  Result := lvBucketFiles.Selected.Caption;
end;

procedure TMainForm.CheckOperation(const AEval: boolean;
  const AResponseInfo: TCloudResponseInfo);
begin
  if not AEval then
    Exit;

  RaiseUnableToCompleteOp(AResponseInfo.StatusCode, AResponseInfo.StatusMessage);
end;

procedure TMainForm.RaiseUnableToCompleteOp(const AStatusCode: integer;
  const AStatusMessage: string);
begin
  raise EMinIOOperationFailed.CreateFmt('Unable to delete file: %d - %s', [
    AStatusCode, AStatusMessage]);
end;

end.


