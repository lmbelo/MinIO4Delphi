unit Data.Cloud.MinIO;

interface

uses
  System.IOUtils,
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Winapi.ActiveX,
  Winapi.Windows,
  Winapi.msxml,
  Data.Cloud.AmazonAPI,
  Data.Cloud.CloudAPI;

type
  TMinIOConnectionInfo = class(TAmazonConnectionInfo)
  private
    function GetServiceURL(const Host: string): string;
    function StorageURL(const BucketName: string = ''): string;
  end;

  TMinIOStorageService = class(TAmazonStorageService)
  private
    const nTAMANHO_PEDACO_PADRAO = 10485760; //5242880 - 5MB / 10485760 - 10MB
  private
    procedure ValidarArquivo(const psArquivo: string); inline;
    function FormatarReponseInfo(const poRespInfo: TCloudResponseInfo): string;
    procedure TestarEnvioMultipart(const pbSucesso: boolean; const poRespInfo: TCloudResponseInfo);
  protected
    function PrepareRequest(const HTTPVerb: string; Headers, QueryParameters: TStringList;
      const QueryPrefix: string; var URL: string; var Content: TStream): TCloudHTTP; overload; override;
  public
    procedure EnviarArquivoPequeno(const psBucketName, psArquivo: string; psNomeArquivo: string = '');
    procedure EnviarArquivoGrande(const psBucketName, psArquivo: string; psNomeArquivo: string = ''; pnTamanhoPedaco: integer = 0);
    procedure EnviarArquivo(const psBucketName, psArquivo: string; psNomeArquivo: string = '');
  end;

  EMinIO = class(Exception);
  EArquivoInvalido = class(EMinIO);
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
  Headers.Values['host'] := GetConnectionInfo.StorageEndpoint;
  Result := inherited;
end;

procedure TMinIOStorageService.ValidarArquivo(const psArquivo: string);
begin
  if not TFile.Exists(psArquivo) then
    raise EArquivoInvalido.CreateFmt('O arquivo %s é inválido.', [psArquivo]);
end;

function TMinIOStorageService.FormatarReponseInfo(const poRespInfo: TCloudResponseInfo): string;
begin
  Result := poRespInfo.StatusCode.ToString + ' - ' + poRespInfo.StatusMessage;
end;

procedure TMinIOStorageService.TestarEnvioMultipart(const pbSucesso: boolean;
  const poRespInfo: TCloudResponseInfo);
begin
  if not pbSucesso then
    raise EMultipartUpload.CreateFmt('Ocorreu um erro ao enviar o arquivo %s', [
      FormatarReponseInfo(poRespInfo)]);
end;

procedure TMinIOStorageService.EnviarArquivoPequeno(const psBucketName, psArquivo: string;
  psNomeArquivo: string);
var
  oResponseInfo: TCloudResponseInfo;
begin
  ValidarArquivo(psArquivo);

  if psNomeArquivo.IsEmpty then
    psNomeArquivo := TPath.GetFileName(psArquivo);

  oResponseInfo := TCloudResponseInfo.Create;
  try
    if not Self.UploadObject(psBucketName, psNomeArquivo, TFile.ReadAllBytes(psArquivo), false,
      nil, nil, amzbaPrivate, oResponseInfo) then
        raise ERegularUpload.CreateFmt('Ocorreu um erro ao enviar o arquivo. %s', [
          FormatarReponseInfo(oResponseInfo)]);
  finally
    oResponseInfo.Free;
  end;
end;

procedure TMinIOStorageService.EnviarArquivoGrande(const psBucketName, psArquivo: string;
  psNomeArquivo: string; pnTamanhoPedaco: integer);
var
  oResponseInfo: TCloudResponseInfo;
  LUploadId: string;
  LChunk: TArray<byte>;
  LPart: TAmazonMultipartPart;
  LParts: TList<TAmazonMultipartPart>;
  LBinaryReader: TBinaryReader;
begin
  ValidarArquivo(psArquivo);

  if psNomeArquivo.IsEmpty then
    psNomeArquivo := TPath.GetFileName(psArquivo);

  if (pnTamanhoPedaco = 0) then
    pnTamanhoPedaco := nTAMANHO_PEDACO_PADRAO;

  LParts := TList<TAmazonMultipartPart>.Create;
  try
    oResponseInfo := TCloudResponseInfo.Create;
    try
      LUploadId := InitiateMultipartUpload(psBucketName, psNomeArquivo, nil, nil, amzbaPrivate, oResponseInfo);
      try
        LBinaryReader := TBinaryReader.Create(psArquivo);
        try
          LChunk := LBinaryReader.ReadBytes(pnTamanhoPedaco);
          while Assigned(LChunk) do
          begin
            TestarEnvioMultipart(
              UploadPart(
                psBucketName,
                psNomeArquivo,
                LUploadId,
                LParts.Count,
                LChunk,
                LPart),
              oResponseInfo);

            LParts.Add(LPart);
            LChunk := LBinaryReader.ReadBytes(pnTamanhoPedaco);
          end;
        finally
          LBinaryReader.Free;
        end;
      finally
        TestarEnvioMultipart(
          CompleteMultipartUpload(psBucketName, psNomeArquivo, LUploadId, LParts, oResponseInfo),
          oResponseInfo);
      end;
    finally
      oResponseInfo.Free;
    end;
  finally
   LParts.Free;
  end;
end;

procedure TMinIOStorageService.EnviarArquivo(const psBucketName, psArquivo: string;
  psNomeArquivo: string);
begin
  with TFile.OpenRead(psArquivo) do
  try
    if (Size > nTAMANHO_PEDACO_PADRAO) then
      EnviarArquivoGrande(psBucketName, psArquivo, psNomeArquivo)
    else
      EnviarArquivoPequeno(psBucketName, psArquivo, psNomeArquivo);
  finally
    Free;
  end;
end;

end.
