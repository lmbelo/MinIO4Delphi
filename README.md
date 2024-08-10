# MinIO4Delphi - Based on Delphi's Amazon Cloud API

## High Performance Object Storage for AI

#### MinIO is a high-performance, S3 compatible object store. It is built for large scale AI/ML, data lake and database workloads. It runs on-prem and on any cloud (public or private) and from the data center to the edge. MinIO is software-defined and open source under GNU AGPL v3.

https://min.io/


### Usage

Create the MinIO connection info in the same manner as you create the [Amazon connection info](https://docwiki.embarcadero.com/Libraries/Alexandria/en/Data.Cloud.AmazonAPI.TAmazonConnectionInfo):

```
var
  LConnInfo: TMinIOConnectionInfo;
...
  LConnInfo := TMinIOConnectionInfo.Create(nil);
  LConnInfo.AccountKey := 'your_private_key';
  LConnInfo.AccountName := 'your_public_key';
  LConnInfo.StorageEndPoint := 'your_endpoint';
  LConnInfo.UseDefaultEndpoints := false;
```

Create the MinIO storage service in the same manner as you create the [Amazon storage service](https://docwiki.embarcadero.com/Libraries/Alexandria/en/Data.Cloud.AmazonAPI.TAmazonStorageService):

```
var
  LService: TMinIOStorageService;
...
  LService := TMinIOStorageService.Create(LConnInfo);
```

Use it in the conventional way plus this implementation abstractions:

```
...
  LService.UploadFile('your_bucket_name', 'local_file_path', 'remote_file_name');
  LService.DeleteObject('your_bucket_name', 'remote_file_name');
...
```

### Sample 1

![image](https://github.com/user-attachments/assets/22ce3ca9-8dd3-403f-abf8-c51d4a26be25)
