﻿[Setup]
AppName=Houhou SRS
AppVersion=1.3.1
DefaultDirName={pf}\Houhou SRS
DefaultGroupName=Houhou SRS
UninstallDisplayIcon={app}\Houhou.exe
Compression=lzma2
SolidCompression=yes

[Files]
Source: "dotnet-4.5.1-web.exe"; DestDir: {tmp}; Flags: deleteafterinstall; Check: not IsRequiredDotNetDetected
Source: "..\Kanji.Interface\bin\Release\Data\*"; DestDir: "{app}\Data"; Flags: ignoreversion recursesubdirs
Source: "..\Kanji.Interface\bin\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Kanji.Interface\bin\Release\Houhou.exe"; DestDir: "{app}"; DestName: "Houhou SRS.exe"; Flags: ignoreversion
Source: "..\Kanji.Interface\bin\Release\Houhou.exe.config"; DestDir: "{app}"; DestName: "Houhou SRS.exe.config"; AfterInstall: ChangeEndpointAddress; Flags: ignoreversion
Source: "..\Kanji.Interface\bin\Release\x64\*.dll"; DestDir: "{app}\x64"; Flags: ignoreversion
Source: "..\Kanji.Interface\bin\Release\x86\*.dll"; DestDir: "{app}\x86"; Flags: ignoreversion                     

[Icons]
Name: "{group}\Houhou SRS"; Filename: "{app}\Houhou SRS.exe"
Name: "{commondesktop}\Houhou SRS"; Filename: "{app}\Houhou SRS.exe"

[Run]
Filename: "{tmp}\dotnet-4.5.1-web.exe"; Check: not IsRequiredDotNetDetected; StatusMsg: Please follow the directions of the Microsoft .NET Framework 4.5 installer to continue.

[Code]
// Some of the code below was written by Christoph Nahr.
// http://www.kynosarges.de/DotNetVersion.html
// That code has been placed under public domain.
function IsDotNetDetected(version: string; service: cardinal): boolean;
// Indicates whether the specified version and service pack of the .NET Framework is installed.
//
// version -- Specify one of these strings for the required .NET Framework version:
//    'v1.1.4322'     .NET Framework 1.1
//    'v2.0.50727'    .NET Framework 2.0
//    'v3.0'          .NET Framework 3.0
//    'v3.5'          .NET Framework 3.5
//    'v4\Client'     .NET Framework 4.0 Client Profile
//    'v4\Full'       .NET Framework 4.0 Full Installation
//    'v4.5'          .NET Framework 4.5
//
// service -- Specify any non-negative integer for the required service pack level:
//    0               No service packs required
//    1, 2, etc.      Service pack 1, 2, etc. required
var
    key: string;
    install, release, serviceCount: cardinal;
    check45, success: boolean;
begin
    // .NET 4.5 installs as update to .NET 4.0 Full
    if version = 'v4.5' then begin
        version := 'v4\Full';
        check45 := true;
    end else
        check45 := false;

    // installation key group for all .NET versions
    key := 'SOFTWARE\Microsoft\NET Framework Setup\NDP\' + version;

    // .NET 3.0 uses value InstallSuccess in subkey Setup
    if Pos('v3.0', version) = 1 then begin
        success := RegQueryDWordValue(HKLM, key + '\Setup', 'InstallSuccess', install);
    end else begin
        success := RegQueryDWordValue(HKLM, key, 'Install', install);
    end;

    // .NET 4.0/4.5 uses value Servicing instead of SP
    if Pos('v4', version) = 1 then begin
        success := success and RegQueryDWordValue(HKLM, key, 'Servicing', serviceCount);
    end else begin
        success := success and RegQueryDWordValue(HKLM, key, 'SP', serviceCount);
    end;

    // .NET 4.5 uses additional value Release
    if check45 then begin
        success := success and RegQueryDWordValue(HKLM, key, 'Release', release);
        success := success and (release >= 378389);
    end;

    result := success and (install = 1) and (serviceCount >= service);
end;

function IsRequiredDotNetDetected(): Boolean;  
begin
    result := IsDotNetDetected('v4.5', 0);
end;

var
  LibPage: TInputDirWizardPage;

procedure InitializeWizard();
begin
  LibPage := CreateInputDirPage(wpSelectDir, 'Select User Directory Location',
    'Where should the user files be stored?',
    'To continue, click Next. If you would like to select a different folder, ' +
    'click Browse.', False, 'User Directory');
  LibPage.Add('');
  LibPage.Values[0] := ExpandConstant('{userdocs}\Houhou');
end;

procedure UpdateUserPath;
var
C: AnsiString;
CU: String;
begin
        LoadStringFromFile(WizardDirValue + '\Houhou SRS.exe.config', C);
        CU := C;
        StringChangeEx(CU, '[userdir]', LibPage.Values[0], True);
        C := CU;
        SaveStringToFile(WizardDirValue + '\Houhou SRS.exe.config', C, False);
end;

const
  ConfigEndpointPath = '//configuration/userSettings/Kanji.Interface.Properties.Settings/setting[@name="UserDirectoryPath"]/value';

procedure ChangeEndpointAddress;
var
  XMLNode: Variant;
  TextNode: Variant;
  XMLDocument: Variant;  
begin
  XMLDocument := CreateOleObject('Msxml2.DOMDocument.6.0');
  try
    XMLDocument.async := False;
    XMLDocument.preserveWhiteSpace := True;
    XMLDocument.load(WizardDirValue + '\Houhou SRS.exe.config');    
    if (XMLDocument.parseError.errorCode <> 0) then
      RaiseException(XMLDocument.parseError.reason)
    else
    begin
      XMLDocument.setProperty('SelectionLanguage', 'XPath');
      XMLNode := XMLDocument.selectSingleNode(ConfigEndpointPath);
      TextNode := XMLDocument.createTextNode(LibPage.Values[0]);
      XMLNode.removeChild(XMLNode.childNodes.item(0));
      XMLNode.appendChild(TextNode);
      XMLDocument.save(WizardDirValue + '\Houhou SRS.exe.config');
    end;
  except
    MsgBox('An error occured during processing application ' +
      'config file!' + #13#10 + GetExceptionMessage, mbError, MB_OK);
  end;
end;

function InitializeSetup(): Boolean;
begin
    if not IsRequiredDotNetDetected() then begin
        MsgBox('Houhou SRS requires the Microsoft .NET Framework 4.5.'#13#13
            'At the end of the installation process, the Microsoft .NET Framework 4.5 web installer will be started.'#13
            'Please check your internet connection before proceeding.', mbInformation, MB_OK);
    end;

    result := true;
end;

