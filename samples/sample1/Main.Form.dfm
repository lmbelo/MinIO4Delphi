object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'MinIO'
  ClientHeight = 676
  ClientWidth = 1013
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  OnCreate = FormCreate
  TextHeight = 15
  object pnlConnInfo: TPanel
    Left = 0
    Top = 0
    Width = 1013
    Height = 140
    Align = alTop
    TabOrder = 0
    ExplicitWidth = 1049
    object Label3: TLabel
      Left = 10
      Top = 44
      Width = 61
      Height = 15
      Caption = 'Access Key:'
    end
    object Label4: TLabel
      Left = 14
      Top = 76
      Width = 57
      Height = 15
      Caption = 'Secret Key:'
    end
    object Label2: TLabel
      Left = 20
      Top = 15
      Width = 51
      Height = 15
      Caption = 'Endpoint:'
    end
    object btnConnect: TButton
      Left = 327
      Top = 105
      Width = 75
      Height = 26
      Caption = 'Connect'
      TabOrder = 3
      OnClick = btnConnectClick
    end
    object editAccessKey: TEdit
      Left = 74
      Top = 44
      Width = 328
      Height = 26
      TabOrder = 1
      Text = 'minioadmin'
    end
    object editSecretKey: TEdit
      Left = 74
      Top = 76
      Width = 328
      Height = 26
      TabOrder = 2
      Text = 'minioadmin'
    end
    object editEndereco: TEdit
      Left = 74
      Top = 12
      Width = 328
      Height = 26
      TabOrder = 0
      Text = '192.168.0.13:9000'
    end
  end
  object pnlStorageService: TPanel
    Left = 0
    Top = 140
    Width = 1013
    Height = 518
    Align = alClient
    TabOrder = 1
    ExplicitTop = 137
    ExplicitHeight = 538
    DesignSize = (
      1013
      518)
    object lbPrefix: TLabel
      Left = 160
      Top = 17
      Width = 33
      Height = 15
      Caption = 'Prefix:'
    end
    object lbMax: TLabel
      Left = 367
      Top = 17
      Width = 26
      Height = 15
      Caption = 'Max:'
    end
    object btnClear: TButton
      Left = 869
      Top = 159
      Width = 135
      Height = 26
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Caption = 'Clear'
      TabOrder = 0
      OnClick = btnClearClick
    end
    object btnCreateBucket: TButton
      Left = 0
      Top = 453
      Width = 155
      Height = 26
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Anchors = [akTop, akRight]
      Caption = 'Create Bucket'
      TabOrder = 1
      OnClick = btnCreateBucketClick
    end
    object btnDelete: TButton
      Left = 869
      Top = 129
      Width = 135
      Height = 26
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Caption = 'Delete'
      TabOrder = 2
      OnClick = btnDeleteClick
    end
    object btnDeleteBucket: TButton
      Left = 0
      Top = 483
      Width = 155
      Height = 26
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Anchors = [akTop, akRight]
      Caption = 'Delete Bucket'
      TabOrder = 3
      OnClick = btnDeleteBucketClick
    end
    object btnDownload: TButton
      Left = 869
      Top = 99
      Width = 135
      Height = 26
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Caption = 'Download'
      TabOrder = 4
      OnClick = btnDownloadClick
    end
    object btnListBuckets: TButton
      Left = 0
      Top = 10
      Width = 155
      Height = 26
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Caption = 'Buckets'
      TabOrder = 5
      OnClick = btnListBucketsClick
    end
    object btnListFiles: TButton
      Left = 869
      Top = 39
      Width = 133
      Height = 26
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Caption = 'Files'
      TabOrder = 6
      OnClick = btnListFilesClick
    end
    object btnUpload: TButton
      Left = 869
      Top = 69
      Width = 135
      Height = 26
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Caption = 'Upload'
      TabOrder = 7
      OnClick = btnUploadClick
    end
    object edMax: TEdit
      Left = 399
      Top = 14
      Width = 58
      Height = 26
      TabOrder = 8
      Text = '1000'
    end
    object edPrefix: TEdit
      Left = 199
      Top = 14
      Width = 146
      Height = 26
      TabOrder = 9
    end
    object lbBuckets: TListBox
      Left = 0
      Top = 38
      Width = 156
      Height = 411
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      ItemHeight = 15
      TabOrder = 10
      OnClick = lbBucketsClick
    end
    object lvBucketFiles: TListView
      Left = 160
      Top = 38
      Width = 704
      Height = 470
      Columns = <
        item
          Caption = 'Name'
          Width = 400
        end
        item
          Caption = 'Size'
          Width = 100
        end
        item
          Caption = 'Date'
          Width = 200
        end>
      TabOrder = 11
      ViewStyle = vsReport
    end
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 658
    Width = 1013
    Height = 18
    Panels = <
      item
        Text = 'Waiting for connection...'
        Width = 50
      end>
    ExplicitTop = 653
    ExplicitWidth = 1049
  end
  object OpenDialog1: TOpenDialog
    Left = 568
    Top = 31
  end
  object SaveDialog1: TSaveDialog
    Options = [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist, ofEnableSizing]
    Left = 648
    Top = 32
  end
end
