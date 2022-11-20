object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  TextHeight = 15
  object input_edt: TEdit
    Left = 24
    Top = 80
    Width = 121
    Height = 25
    TabOrder = 0
    Text = '0'
  end
  object Button1: TButton
    Left = 24
    Top = 152
    Width = 121
    Height = 25
    Action = StupidOrNotAc
    TabOrder = 1
  end
  object mainAcList: TActionList
    Left = 568
    Top = 384
    object StupidOrNotAc: TAction
      Caption = #1055#1088#1086#1074#1077#1088#1080#1090#1100
      OnExecute = StupidOrNotAcExecute
    end
  end
end
