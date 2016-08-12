///	
// Written in the D programming language.
/**
This is a build tool,compile *.d to exe or lib,and help to build dgui,dfl2 gui (or other you like).
now default DC is dmd ,default platform is windows.

If your DC is dmd, dco can start only 'dco.ini' config file. 

Compiler dco.d :dmd dco.d -release,and dco ↓,

Usage:
Config some info to 'dco.ini' file,';' or '#' means you can do as it.Then copy dco.ini to your PATH: such as dmd's config file:sc.ini.
And dco.exe can auto copy itsself to EnvPath,that also is  dmd.exe 's path: dmd2\window\bin.
After that,you can run the 'dco.exe'  anywhere.
If not found 'dco.ini',run: dco -ini,please.

For example:
to get the debug version( -release to get another)

build some *.d to lib or exe 			 : dco ↓
build some *.d to lib or exe for 64 bit	 : dco -m64 ↓
build  one app.d in many *.d    		 : dco app or  dco app.d
build for libs 	such as dfl,dgui         : dco  -lib
build for app.d use dgui,dfl2			 : dco  -gui
build app.d use dfl2 for console		 : dco  -con
build lib and copy to libs				 : dco -lib -copy
build by custom	and copy to libs         : dco -arg -addlib -lib -copy

if your exe's file works on console,you should add '-con' or '-console'. 

Copyright: Copyright FrankLIKE 2014-.

License:   $(LGPL-3.0).

Authors:   FrankLIKE

Source: $(dco.d)

Created Time:2014-10-27
Modify Time:2014-10-31~2016-08-12
*/
module dco.operateFile;
/// dco 
import	std.stdio;
import	std.datetime;
import	std.process; 
import	std.string;
import	std.file;
import	std.path;
import	std.exception;
import  std.json;
import std.typetuple;
import std.algorithm;

import dco.globalInfo;
import dco.helpInfo;




//targetTypes
enum targetTypes {exe,lib,staticLib,dynamicLib,sourceLib,none};
string[] targetExt = ["exe","lib","dll","a"];

 


void copyFile()
{
	string strcopy;
	if(!exists(strTargetFileName)) 
	{
	 	writeln(strTargetFileName," is not exists,stop copy.");
		return;
	}

	if(strTargetFileName.indexOf("exe") != -1)
	{
		//copy(strTargetFileName,strDCEnv); //
		strcopy = "copy " ~ strTargetFileName~" " ~ strDCEnv;
	}
	else
	{ 
		string strDCLibPath = strDCEnv[0..(strDCEnv.length - "bin".length)].idup ~ "lib" ~ compileType; 
		//copy(strDCEnv,strDCLibPath);
		strcopy = "copy " ~ strTargetFileName ~ " " ~ strDCLibPath;
	}
	if(bDisplayCopyInfo)
	{
		writeln(strcopy);
	}

	auto pid =  enforce(spawnShell(strcopy.dup()),"copyFile() error");
	if (wait(pid) != 0)
	{
		writeln("Copy failed.");
	}
}

bool findFiles()
{ 
	int i = 0;
	bool bPackage = false; 
	auto packages = dirEntries(".","{package.d,all.d}",SpanMode.depth);
	foreach(p; packages){i++;}
	bPackage = (i > 0);

	auto dFiles = dirEntries(".","*.{d,di}",SpanMode.depth);
	int icount =0;
    SysTime fileTime;
    DirEntry rootDE ;

	foreach(d; dFiles)
	{	 
	    if(!bAssignTarget)
	    {
			if(icount == 0)
			{
				strTargetName = d.name[(d.name.lastIndexOf(separator)+1) .. d.name.lastIndexOf(".")];
				strTargetName ~= "." ~ strTargetType; 
			}
		}
		if(icount == 0 )
		{
			ReadDFile(d,bPackage);
		}

		if(d.toLower().indexOf("ignore") != -1) continue;

		strDFile ~= " ";
		strDFile ~= d.name[2 ..$].idup;

		//sourceLastUpdateTime 
		rootDE = DirEntry(d);
        if(rootDE.timeLastModified > fileTime)
        {
        	fileTime = rootDE.timeLastModified;
        } 
        icount++;
	}
    sourceLastUpdateTime = fileTime;

	strDFile = strDFile.stripRight().idup;

	if(icount <= 0)  
	{
		writeln("Not found any *.d files in current folder.If there is a 'source' or 'src' folder,dco will find the '*.d' from there.");
		return false;
	}
	bCopy = (strDFile.indexOf("dco.d") != -1) ? true : false;
	return true;
}

void getTargetInfo()
{ 
	string root_path = getcwd();
    string strPath;
	auto dFiles = dirEntries(root_path,strTargetName ~ ".{lib,exe,dll,a}",SpanMode.shallow);
	int i =0;
	foreach(d;dFiles)
	{
		i++;
		strTargetFileName =d;
		strTargetType = d.name[d.name.lastIndexOf(".")+1..$];
		break;

	}
	if(i == 0)
	{
		if(strTargetName.indexOf("." ~ strTargetType) == -1)
		{
			strTargetName = strTargetName ~ "." ~ strTargetType;
		}
		strTargetFileName = root_path ~ separator ~ strTargetName;
	}
	if(!findStr(strTargetFileName,targetExt))
	{
		writeln("don't known the targetType ",strTargetFileName);
	}
	return;
}

bool findStr(string strIn,string[] strFind)
{ 
   return strFind.canFind!(a => strIn.canFind(a) != false);
}


void ReadDFile(string dFile,bool bPackage)
{ 
    if(bGetLocal) return;
	auto file = File(dFile); 
	scope(exit)  file.close();
	auto range = file.byLine();
	int icount = 0;
    foreach (line; range)
    {
        if (!line.init && line.indexOf("import") != -1)
        { 
        	if(line.indexOf("dfl") != -1)
        	{
        		bBuildSpecialLib = bPackage;
        		SpecialLib = "dfl";
        		bUseSpecialLib = !bPackage;

				if(bUseSpecialLib) 
					strTargetLflags = strWindows;
				else
					strTargetLflags = strConsole;
				break;
			}
			else if(line.indexOf("dgui") != -1)
			{
				strArgs = strAddArgsdfl = " -g -de -w -X ";
				SpecialLib = "dgui";
				bBuildSpecialLib = bPackage;
				break;
			}
        }
        else if(line.indexOf("WinMain") != -1)
        {
			strTargetLflags = strWindows;
			break;
        }
        icount++;
        if(icount >100) break;
    }
}


void readInJson()
{
	if(!exists("dub.json") && !exists("package.json") ) return;
}
