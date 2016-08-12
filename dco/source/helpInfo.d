module dco.helpInfo;

import std.stdio;

string strVersion = "v0.1.5";

void ShowUsage()
{
	writeln("
dco build tool " ~ strVersion ~ "
written by FrankLIKE.
Usage:
dco [<switches...>] <files...>

for example:     
	dco 
or: dco app.d 

(if you build a bigger project ,you can config a local.ini(get by 'dco -ini'),
then enter 'dco',ok.)

build for dfl2:	 
    
    dco  
or: dco -gui
or: dco *.d -gui
			
build for other: 

    dco -lib
or: dco *.d -lib
or: dco *.d -release
or: dco *.d -arg -addlib

Switches:
-h	   Print help(usage: -h,or -help).
-ini       Create the local.ini file for config. 
-init      the same to -ini.
-copy      Copy new exe or lib to 'windows/bin' or 'lib' Folder. 
-release   Build files's Release version(Default version is 'debug').
-gui       Make a Windows GUI exe without a console(For Dgui or DFL).
-use       Use the Sepetail Lib to create exe with console.
-win       Make a Windows GUI exe without a console
           (For any other: the same to -winexe,-windows).
-lib       Build lib files.
-all       Build files by args,libs(Default no dfl_debug.lib) in Console.
-arg       Build files by args(-de -w -property -X).
-addlib    Build files by add libs(user32.lib ole32.lib oleAut32.lib gdi32.lib 
	    Comctl32.lib Comdlg32.lib advapi32.lib uuid.lib ws2_32.lib).
-m64       Generate 64bit lib or exe.
-m32mscoff Generate x86 ms coff lib or exe,and please set some info in sc.ini. 
-version	Current version.

IgnoreFiles:If you have some files to ignore,please put them in Folder 'ignoreFiles'.
  ");
} 

void ShowVersion()
{
	writeln("dco Current version is " ~ strVersion ~ ", written by FrankLIKE.");
}