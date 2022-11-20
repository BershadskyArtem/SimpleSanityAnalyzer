unit Unit1;

interface

uses
    Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
    System.Classes, Vcl.Graphics,
    Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Actions, Vcl.ActnList,
    Vcl.StdCtrls, System.Character, System.Generics.Collections,
    System.StrUtils;
type

    TTokenKind = (num, minus, plus, separator, unknown);

    TToken = class
        Start: integer;
        Length: integer;
        Content: string;
        TokenKind: TTokenKind;
    end;

    TForm1 = class(TForm)
        input_edt: TEdit;
        Button1: TButton;
    mainAcList: TActionList;
        StupidOrNotAc: TAction;
        procedure StupidOrNotAcExecute(Sender: TObject);
        function CheckStupid(input: string; var value: double): boolean;
        function PeekNext(position: integer; tokens: TList<TToken>): TToken;
    private
        { Private declarations }
    public
        { Public declarations }
    end;

var
    Form1: TForm1;

implementation

{$R *.dfm}
// Valid Arguments
// 0.5
// 0.05
// -1.03
// -0.65
// 0.5
// .5
// -.5
// 0.

// Invalid Arguments
// 00.5
// 00.50
// 1.0
// -00
// -

// This cases needs to be valid because of IEE 754 that allows computers to have -0 but fuck that for now
// -0.
// -0

// This should contain AST but fuck that too for now
function TForm1.CheckStupid(input: string; var value: double): boolean;
var
    tokens: TList<TToken>;
    isCurrentCharDigit: boolean;
    i, j, tokenLength, tokenStart, minusCounter, plusCounter, separatorCounter,
      numTokenCounter, starterIndex: integer;
    tokenContent: string;
    currentToken, supToken: TToken;

begin
    FormatSettings.DecimalSeparator := '.';
    // Always start with this assumption
    Result := true;
    i := 0;
    j := 0;
    tokenLength := 0;
    tokenStart := 0;
    minusCounter := 0;
    plusCounter := 0;
    separatorCounter := 0;
    numTokenCounter := 0;

    // if we got empty string then we are fucked by definition
    if (string.isNullOrWhiteSpace(input)) then
    begin
        Exit(true);
    end;

    // initialize token list
    tokens := TList<TToken>.Create;
    i := 1;
    isCurrentCharDigit := false;
    while i <= input.Length do
    begin
        j := i;
        tokenStart := i;
        tokenContent := '';
        tokenLength := 0;
        // if we encountered number and the next symbol is number as well
        // then we continue until next symbol is not number
        repeat
            tokenContent := tokenContent + input[j];
            isCurrentCharDigit := input[j].IsDigit();
            inc(j);
        until ((j > input.Length) or (not input[j].IsDigit()) or
          (not isCurrentCharDigit));

        tokenLength := j - tokenStart;
        // Creating token that represents our word with its index, length and string content
        currentToken := TToken.Create();
        currentToken.Start := tokenStart;
        currentToken.Length := tokenLength;
        currentToken.Content := tokenContent;

        // Mark token based on their content
        if (tokenContent = '-') then
            currentToken.TokenKind := TTokenKind.minus
        else if (tokenContent = '+') then
            currentToken.TokenKind := TTokenKind.plus
        else if (tokenContent = '.') then
            currentToken.TokenKind := TTokenKind.separator
        else if (tokenContent[1].IsDigit()) then
            currentToken.TokenKind := TTokenKind.num
        else
            currentToken.TokenKind := TTokenKind.unknown;
        // Go Ahead
        i := j;
        tokens.Add(currentToken);
    end;

    // If we've got only one word
    if (tokens.Count = 1) and (tokens[0].TokenKind = TTokenKind.num) then
    begin
        // if our word is number and starts with 0 but the length of it is greater than one
        // then it means that the word is 01 or 02 etc.
        if (tokens[0].Content.StartsWith('0')) and (tokens[0].Content.Length > 1)
        then
            Exit(true);
        // Just to make sure that i did not fucked up
        if (not double.TryParse(input, value)) then
        begin
            ShowMessage
              (Format('It seems like my logic just fucked. Report this shit to me Input = %s',
              [input]));
            Exit(true);
        end;
        // We are done. You are not stupid.
        Exit(false);
    end;

    // if we've got 2 word
    // Input for that can be 0. -. -+ +- -0 -01 -05 etc
    if (tokens.Count = 2) then
    begin
        // get all of our words
        currentToken := tokens[0];
        supToken := tokens[1];
        // if first word is + or - or . or number then we are good
        case currentToken.TokenKind of
            num:
                // if out 2nd word after number is . then we are done
                if (supToken.TokenKind = TTokenKind.separator) then
                begin
                    if (not double.TryParse(currentToken.Content, value)) then
                    begin
                        ShowMessage
                          (Format('It seems like my logic just fucked. Report this shit to me Input = %s',
                          [input]));
                        Exit(true);
                    end;
                    Exit(false);
                end;
            // otherwise continue
            minus:
                ;
            plus:
                ;
            separator:
                ;
            // if we've encountered unkown word then you are stupid
            unknown:
                Exit(true);
        end;

        // check second word
        // if our first word is not number but + - . then we need to check second word
        case supToken.TokenKind of
            // if second word is number then we are done otherwise STUPID
            num:
                if (supToken.Content.EndsWith('0')) then
                    Exit(true)
                else if (not double.TryParse(input, value)) then
                begin
                    ShowMessage
                      (Format('It seems like my logic just fucked. Report this shit to me. Input = %s',
                      [input]));
                    Exit(true);
                end
                else
                    Exit(false);
            minus:
                Exit(true);
            plus:
                Exit(true);
            separator:
                Exit(true);
            unknown:
                Exit(true);
        end;

    end;

    // if we've got more than 2 words then the hard way
    // DONT TOUCH IT
    starterIndex := 2;
    // Check our first token
    currentToken := tokens[0];

    // if our number starts with minus or plus
    if (currentToken.TokenKind = TTokenKind.minus) or
      (currentToken.TokenKind = TTokenKind.plus) then
    begin
        // increase minus Counter
        if (currentToken.TokenKind = TTokenKind.minus) then
            inc(minusCounter)
        else
            // increase plus Counter
            inc(plusCounter);
        supToken := PeekNext(0, tokens);
        // if after first token there is nothing then it mean that we are fucked
        if (supToken = nil) then
            Exit(true);
        case supToken.TokenKind of
            // if after minus or plus there is number or separator then it is good
            // otherwise you are stupid
            num:
                inc(numTokenCounter);
            minus:
                Exit(true);
            plus:
                Exit(true);
            separator:
                inc(separatorCounter);
            unknown:
                Exit(true);
        end;

    end
    // if our first word is separator then we can accept only numbers after that
    else if currentToken.TokenKind = TTokenKind.separator then
    begin
        inc(separatorCounter);
        supToken := PeekNext(0, tokens);
        if (supToken = nil) then
            Exit(true);
        // if not numbers then get out
        if (supToken.TokenKind <> TTokenKind.num) then
            Exit(true);

    end
    // Dont know what you entered -> RUN
    else if (currentToken.TokenKind = TTokenKind.unknown) then
        Exit(true)
        // if first word is number then we check if it starts with 00
    else if (currentToken.TokenKind = TTokenKind.num) then
    begin
        inc(numTokenCounter);
        // this needs to be here
        starterIndex := 1;
        if (currentToken.Content.StartsWith('00')) then
            Exit(true);
    end;

    // started index tells us from what word to start
    // It is needed beacuse above in some cases
    // We already checked second token but in case of first word is number
    // We did not check second word so we need to tell from what word to start
    for i := starterIndex to tokens.Count - 1 do
    begin
        currentToken := tokens[i];
        // Count words
        case currentToken.TokenKind of
            num:
                inc(numTokenCounter);
            minus:
                inc(minusCounter);
            plus:
                inc(plusCounter);
            separator:
                inc(separatorCounter);
            unknown:
                Exit(true);
        end;
        // in input there can be only one minus or only one plus
        // if we have one or greater plus and one or greater minus then we
        // are fucked.
        if ((plusCounter + minusCounter) > 1) then
            Exit(true);
        // If we have more than 1 . in input
        if (separatorCounter > 1) then
            Exit(true);
    end;

    // check last word
    currentToken := tokens.Last;
    // Our Last Word can only be number so if it is not then we exit
    if (currentToken.TokenKind <> TTokenKind.num) then
        Exit(true);
    // If we did not exit then we need to check if out last digit is not 0
    // All cases where we had input such as 10 or .0 we already checked in
    // 2 words and 1 word sections
    if (currentToken.Content.EndsWith('0')) then
        Exit(true);

    // If we did not find any numbers then Exit
    if (numTokenCounter <= 0) then
        Exit(true);

    // All checks done. Final check using TryParse if it fails i am stupid
    if (not double.TryParse(input, value)) then
    begin
        ShowMessage
          (Format('It seems like my logic just fucked. Report this shit to me Input = %s',
          [input]));
        Exit(true);
    end;
    // Congratulations stupid = false
    Exit(false);
end;

//Utility function to get next word
function TForm1.PeekNext(position: integer; tokens: TList<TToken>): TToken;
begin
    if (position + 1 < 0) or (position + 1 > tokens.Count - 1) then
        Exit(nil);
    Exit(tokens[position + 1]);
end;

procedure TForm1.StupidOrNotAcExecute(Sender: TObject);
var
    input: string;
    output: double;
begin
    // How to use
    // CheckStupid checks stupid inputs.
    // If CheckStupid(input , output) returns true then there
    // was stupid inputs
    // If there was not then it puts number in variable "output"

    input := input_edt.Text;
    if (CheckStupid(input, output)) then
    begin
        ShowMessage('Stupid');
        Exit;
    end;
    ShowMessage(Format('You are not stupid. Value is: %n', [output]));
end;

end.
