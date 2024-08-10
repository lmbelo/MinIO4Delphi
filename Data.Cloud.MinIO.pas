(**************************************************************************)
(*                                                                        *)
(* Module:  Unit 'Data.Cloud.MinIO' Copyright (c) 2023                    *)
(*                                                                        *)
(*                                  Lucas Moura Belo - lmbelo             *)
(*                                  lucas.belo@live.com                   *)
(*                                  Brazil                                *)
(*                                                                        *)
(* Project page:                 https://github.com/lmbelo/MinIO4Delphi   *)
(**************************************************************************)
(*  Functionality:  MinIO Integration.                                    *)
(*                                                                        *)
(*                                                                        *)
(**************************************************************************)
(* This source code is distributed with no WARRANTY, for no reason or use.*)
(* Everyone is allowed to use and change this code free for his own tasks *)
(* and projects, as long as this header and its copyright text is intact. *)
(* For changed versions of this code, which are public distributed the    *)
(* following additional conditions have to be fullfilled:                 *)
(* 1) The header has to contain a comment on the change and the author of *)
(*    it.                                                                 *)
(* 2) A copy of the changed source has to be sent to the above E-Mail     *)
(*    address or my then valid address, if this is possible to the        *)
(*    author.                                                             *)
(* The second condition has the target to maintain an up to date central  *)
(* version of the component. If this condition is not acceptable for      *)
(* confidential or legal reasons, everyone is free to derive a component  *)
(* or to generate a diff file to my or other original sources.            *)
(**************************************************************************)
unit Data.Cloud.MinIO;

interface

uses
  System.IOUtils,
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Data.Cloud.CloudAPI,
  Data.Cloud.AmazonAPI;

type
  TMinIOConnectionInfo = class(TAmazonConnectionInfo)
  private
    function GetServiceURL(const Host: string): string;
    function StorageURL(const BucketName: string = ''): string;
  end;

  TMinIOStorageService = class(TAmazonStorageService)
  private
    const DEFAULT_DATA_CHUNK_SIZE = 10485760; //5242880 - 5MB / 10485760 - 10MB
  private
    procedure ValidateFile(const AFileName: string); inline;
    function FormatResponseInfo(const AResponseInfo: TCloudResponseInfo): string;
    procedure TestMultipartUpload(const ASuccess: boolean; const AResponseInfo: TCloudResponseInfo);
  protected
    function PrepareRequest(const HTTPVerb: string; Headers, QueryParameters: TStringList;
      const QueryPrefix: string; var URL: string; var Content: TStream): TCloudHTTP; overload; override;
  public
    procedure UploadSmallFile(const ABucketName, AFileName: string; ARemoteFileName: string = '');
    procedure UploadLargeFile(const ABucketName, AFileName: string; ARemoteFileName: string = '';
      ADataChunkSize: integer = 0);
    procedure UploadFile(const ABucketName, AFileName: string; ARemoteFileName: string = '');
  end;

  EMinIO = class(Exception);
  EInvalidFile = class(EMinIO);
  ERegularUpload = class(EMinIO);
  EMultipartUpload = class(EMinIO);

implementation

{ TMinIOConnectionInfo }

function TMinIOConnectionInfo.GetServiceURL(const Host: string): string;
begin
  //View all available endpoints here: http://developer.amazonwebservices.com/connect/entry.jspa?externalID=3912
  Result := Format('%s://%s', [Protocol, Host]);  //sqs.us-east-1.amazonaws.com
end;

function TMinIOConnectionInfo.StorageURL(const BucketName: string): string;
begin
  if BucketName = EmptyStr then
    Result := GetServiceURL(StorageEndpoint)
  else
    Result := GetServiceURL(Format('%s/%s', [StorageEndpoint, BucketName]));
end;

function TMinIOStorageService.PrepareRequest(const HTTPVerb: string; Headers,
  QueryParameters: TStringList; const QueryPrefix: string; var URL: string;
  var Content: TStream): TCloudHTTP;
begin
  URL := TMinIOConnectionInfo(GetConnectionInfo).StorageURL(QueryPrefix.Replace('/', '', []));

  if URL.Contains('?') and (not URL.EndsWith('?') and not URL.Contains('=')) then //?uploads
    URL := URL + '=';

  if Assigned(QueryParameters) then
    URL := BuildQueryParameterString(url, QueryParameters, False, True);

  Headers.Values['host'] := GetConnectionInfo.StorageEndpoint;
  Result := inherited;
end;

procedure TMinIOStorageService.ValidateFile(const AFileName: string);
begin
  if not TFile.Exists(AFileName) then
    raise EInvalidFile.CreateFmt('Invalid file %s.', [AFileName]);
end;

function TMinIOStorageService.FormatResponseInfo(const AResponseInfo: TCloudResponseInfo): string;
begin
  Result := AResponseInfo.StatusCode.ToString + ' - ' + AResponseInfo.StatusMessage;
end;

procedure TMinIOStorageService.TestMultipartUpload(const ASuccess: boolean;
  const AResponseInfo: TCloudResponseInfo);
begin
  if not ASuccess then
    raise EMultipartUpload.CreateFmt('An error occurred in the upload. %s', [
      FormatResponseInfo(AResponseInfo)]);
end;

procedure TMinIOStorageService.UploadSmallFile(const ABucketName, AFileName: string;
  ARemoteFileName: string);
var
  LResponseInfo: TCloudResponseInfo;
begin
  ValidateFile(AFileName);

  if ARemoteFileName.IsEmpty then
    ARemoteFileName := TPath.GetFileName(AFileName);

  LResponseInfo := TCloudResponseInfo.Create;
  try
    if not Self.UploadObject(ABucketName, ARemoteFileName, TFile.ReadAllBytes(AFileName), false,
      nil, nil, amzbaPrivate, LResponseInfo) then
        raise ERegularUpload.CreateFmt('An error occurred in the upload. %s', [
          FormatResponseInfo(LResponseInfo)]);
  finally
    LResponseInfo.Free;
  end;
end;

procedure TMinIOStorageService.UploadLargeFile(const ABucketName, AFileName: string;
  ARemoteFileName: string; ADataChunkSize: integer);
var
  LResponseInfo: TCloudResponseInfo;
  LUploadId: string;
  LChunk: TArray<byte>;
  LPart: TAmazonMultipartPart;
  LParts: TList<TAmazonMultipartPart>;
  LBinaryReader: TBinaryReader;
begin
  ValidateFile(AFileName);

  if ARemoteFileName.IsEmpty then
    ARemoteFileName := TPath.GetFileName(AFileName);

  if (ADataChunkSize = 0) then
    ADataChunkSize := DEFAULT_DATA_CHUNK_SIZE;

  LParts := TList<TAmazonMultipartPart>.Create;
  try
    LResponseInfo := TCloudResponseInfo.Create;
    try
      LUploadId := InitiateMultipartUpload(ABucketName, ARemoteFileName, nil, nil, amzbaPrivate, LResponseInfo);
      TestMultipartUpload(not LUploadId.IsEmpty(), LResponseInfo);
      try
        LBinaryReader := TBinaryReader.Create(AFileName);
        try
          LChunk := LBinaryReader.ReadBytes(ADataChunkSize);
          while Assigned(LChunk) do
          begin
            TestMultipartUpload(
              UploadPart(
                ABucketName,
                ARemoteFileName,
                LUploadId,
                Succ(LParts.Count),
                LChunk,
                LPart),
              LResponseInfo);

            LParts.Add(LPart);
            LChunk := LBinaryReader.ReadBytes(ADataChunkSize);
          end;
        finally
          LBinaryReader.Free;
        end;
      finally
        TestMultipartUpload(
          CompleteMultipartUpload(ABucketName, ARemoteFileName, LUploadId, LParts, LResponseInfo),
          LResponseInfo);
      end;
    finally
      LResponseInfo.Free;
    end;
  finally
    LParts.Free;
  end;
end;

procedure TMinIOStorageService.UploadFile(const ABucketName, AFileName: string;
  ARemoteFileName: string);
begin
  with TFile.OpenRead(AFileName) do
  try
    if (Size > DEFAULT_DATA_CHUNK_SIZE) then
      UploadLargeFile(ABucketName, AFileName, ARemoteFileName)
    else
      UploadSmallFile(ABucketName, AFileName, ARemoteFileName);
  finally
    Free;
  end;
end;

end.
