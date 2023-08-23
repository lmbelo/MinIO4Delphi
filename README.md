# MinIO4Delphi - Based on Delphi's Amazon Cloud API

## High Performance Object Storage for AI

#### MinIO is a high-performance, S3 compatible object store. It is built for large scale AI/ML, data lake and database workloads. It runs on-prem and on any cloud (public or private) and from the data center to the edge. MinIO is software-defined and open source under GNU AGPL v3.

https://min.io/


### Usage

Create the connection info in the same manner as you create the [Amazon connection info](https://docwiki.embarcadero.com/Libraries/Alexandria/en/Data.Cloud.AmazonAPI.TAmazonConnectionInfo):

```
var
  oConnInfo: TMinIOConnectionInfo;
...
  oConnInfo := TMinIOConnectionInfo.Create(nil);
  oConnInfo.AccountKey := 'your_private_key';
  oConnInfo.AccountName := 'your_public_key';
  oConnInfo.StorageEndPoint := 'your_endpoint';
  oConnInfo.UseDefaultEndpoints := false;
```

Create the storage service in the same manner as you create the [Amazon storage service](https://docwiki.embarcadero.com/Libraries/Alexandria/en/Data.Cloud.AmazonAPI.TAmazonStorageService):

```
var
  oService: TMinIOStorageService;
...
  oService := TMinIOStorageService.Create(oConnInfo);
```

Use it in the conventional way plus this implementation abstractions:

```
...
  oService.UploadFile('your_bucket_name', 'local_file_path', 'remote_file_name');
  oService.DeleteObject('your_bucket_name', 'remote_file_name');
...
```
