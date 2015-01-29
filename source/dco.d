///	
// Written in the D programming language.
/**
This is a build tool,compile *.d to exe or lib,and help to build dfl2 gui (or other you like).
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
build for app.d use dfl2				 : dco  -gui
build app.d use dfl2 for console		 : dco  -con
build lib and copy to libs				 : dco -lib -copy
build by custom	and copy to libs         : dco -arg -addlib -lib -copy

if your exe's file works on console,you should add '-con' or '-console'. 

Copyright: Copyright FrankLIKE 2014-.

License:   $(LGPL-3.0).

Authors:   FrankLIKE

Source: $(dco.d)

Created Time:2014-10-27
Modify Time:2014-10-31~2015-1-27
*/
module dco;
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

string strVersion ="v0.1.1";

string	strAddArgs,strAddArgsdfl = " -de -w -property ";
string	buildMode,strDebugDefault=" -debug";
string	strTargetLflags,strConsole=" -L-su:console:4 ",strWindows = " -L-Subsystem:Windows ",strWindows64 = " -L-Subsystem:Windows -L-ENTRY:mainCRTStartup ";
string	strTargetLib,SpecialLib = "dfl",strWinLibs=" ole32.lib oleAut32.lib gdi32.lib Comctl32.lib Comdlg32.lib advapi32.lib uuid.lib ws2_32.lib kernel32.lib ",strWinLibs64 =" user32.lib "; 
string	strDFile;
string	strAddLib;
string	strOtherArgs;
string	strImportDefault = " -I$(DMDInstallDir)windows/import ";
string	strTargetPath,strTargetFileName,strTargetTypeSwitch,targetTypeDefault = "lib",targetTypeShared = "shared";
string	strDCEnv,strDCEnvFile;
SysTime sourceLastUpdateTime,targetTime;
string	compileType; 

bool	bUseSpecialLib =false,bDebug =true,bBuildSpecialLib =false;
bool	bCopy =false ,bDisplayBuildStr=false,bDisplayCopyInfo =true;
bool	bForce = false,bInitINI =false,bHelp =false;
bool 	bAssignTarget =false;

//ini
string configFile ="dco.ini",configFileLocal = "local.ini";
string[string] configKeyValue;
bool bGetLocal = false;
//ini args
string strPackageName,strArgs,strTargetName,strTargetType ="exe",strDC ="dmd",strDCStandardEnvBin ="dmd2\\windows\\bin",strLibs ,strImport,strLflags,strDflags;
//targetTypes
enum targetTypes {exe,lib,staticLib,dynamicLib,sourceLib,none};
string[] targetExt = ["exe","lib","dll","a"];
string separator = "\\";
void main(string[] args)
{
	if(!findDCEnv()) return;
	// readInJson();
	
	if(!checkArgs(args))
	{
		if(bHelp)
		{
			ShowUsage();
			return;
		}

		if(bInitINI)
		{
			initNewConfigFile();
			return;
		}

		if(!findFiles())
		{
			ShowUsage();
			return;
		}
	}
	if(args.length ==1)
	{
		if(!CheckBinFolderAndCopy()) return;
    }
 
	if(strPackageName =="")
	{
		strPackageName = strTargetName;
	}

	buildExe(args);
}
 
bool findDCEnv()
{
	if(!readConfig(configFile)) return false;
	bool bLocal = readConfig(configFileLocal);
	string strNoDC = "Not found '"~strDC~"' in your computer,please setup it.",strTemp,strTempFile;
	string strDCExe = separator ~ strDC.stripRight() ~ ".exe";
	string strFireWall = " Maybe FirWall stop checking the " ~ strDCExe ~ ",please stop it.";

	auto len = strDCStandardEnvBin.length;

	auto path = environment["PATH"];
	string[] strDCs = path.split(";");
	foreach(s;strDCs)
	{
		ptrdiff_t i = s.indexOf(strDCStandardEnvBin);
		if(i != -1)
		{
			if(checkDC(s,strDCExe)) break;
		}
	}

	if(strDCEnvFile =="")
	{
		writeln(strNoDC);
		return false;
	}
	else
	{
		//writeln(strDC ~ " is " ~ strDCEnvFile);
		return true;
	}
}

bool checkDC(string DCPath,string strDCExe)
{ 
	if(exists(DCPath ~ strDCExe))
	{ 
		strDCEnv = DCPath;
		strDCEnvFile =  DCPath ~ strDCExe;

		string strTempFile = DCPath ~ separator ~"dco.exe";
		if(exists(strTempFile)) return true;
	}
	return false;
}

bool readConfig(string _configFile)
{ 
	try
	{ 
		string strConfigPath ="",targetType ="",targetName ="";
		bool isLocal = (_configFile != configFile);
 
		if(!isLocal)
		{
			strConfigPath = thisExePath();
			strConfigPath = strConfigPath[0..strConfigPath.lastIndexOf(separator)].idup;
			strConfigPath ~= separator ~ _configFile;

			if(!enforce(exists(strConfigPath),"'FireWall' stop to access the '" ~ _configFile ~ "',please stop it."))
			{
				writeln("dco not found " ~ _configFile ~ ", it will help you to  create a init " ~ _configFile ~ " file ,but you should input something in it.");
				initNewConfigFile();
				return false;
			}  
		}
		else
		{
			if("SpecialLib" in configKeyValue) 
				configKeyValue["SpecialLib"] = "";
			if("importPath" in configKeyValue) 
				configKeyValue["importPath"] = "";
 
			strConfigPath = getcwd() ~ separator ~ _configFile;
			bGetLocal = exists(strConfigPath);
			if(!bGetLocal) return true;  //not find ,but can work.
		}
		auto file = File(strConfigPath); 
		scope(failure) file.close();
		auto range = file.byLine();
		foreach (line; range)
		{
			if (!line.init && line[0] != '#' && line[0] != ';' && line.indexOf("=") != -1)
			{ 
				ptrdiff_t i =line.indexOf("=");
				configKeyValue[line.strip()[0..i].idup] = line.strip()[i+1..$].idup;
			}
		}

		file.close();

		strDC = configKeyValue.get("DC",strDC); 

		strDCStandardEnvBin = configKeyValue.get("DCStandardEnvBin",strDCStandardEnvBin); 
		SpecialLib = configKeyValue.get("SpecialLib","");
		strImport = configKeyValue.get("importPath","");
		strLflags = configKeyValue.get("lflags",strConsole); 
		strDflags = configKeyValue.get("dflags",""); 
		strLibs = configKeyValue.get("libs",""); 
          
		if(isLocal)
		{
			switch(strLflags)
			{
				case "console":
					strLflags = strConsole;
					break;
				case "win32":
					strLflags = strWindows;
						break;
				case "win64":
					strLflags = strWindows64;
						break;
				default:
					break;
			}
			strTargetLflags = " " ~ strLflags;

			if(SpecialLib == "dfl" || SpecialLib == "dgui") bUseSpecialLib = true;

			targetType = configKeyValue.get("targetType","default"); 
			targetName = configKeyValue.get("targetName",""); 

			switch(targetType)
			{//targetTypes {exe,lib,staticLib,dynamicLib,sourceLib,none};
				case "sourceLib":
				case "none":
					return false;

				case "exe":
					strTargetType ="exe";
					break;
				case "lib":
				case "staticLib":
					strTargetTypeSwitch =" -lib";
					if(strDC.toLower().indexOf("dmd") != -1)
					{
						strTargetType = "lib";
					}
					else if(strDC.toLower().indexOf("ldc") != -1)
					{
						strTargetType = "a";
					}
					break;
				case  "dynamicLib":
					strTargetTypeSwitch =" -shared";
					if(strDC.toLower().indexOf("dmd") != -1)
					{
						strTargetType = "dll";
					}
					else if(strDC.toLower().indexOf("ldc") != -1)
					{
						strTargetType = "so";
					}
					break;
				default://default
					strTargetType ="exe";
					break;
			}
			if(targetName !="")
			{
				strTargetFileName = getcwd() ~ separator ~ targetName;
				strTargetName = targetName;
				if(targetName.indexOf(".") == -1)
				{
					strTargetName ~= "." ~ strTargetType; 
				}
				strOtherArgs ~= " -of" ~ strTargetName;
				bAssignTarget = true;
			}
			compileType = configKeyValue.get("compileType",""); 
			if(compileType !="" )
			{
				strOtherArgs ~= " -m" ~ compileType;
			}

			buildMode = configKeyValue.get("buildMode",strDebugDefault); 
			if(buildMode.indexOf("-") == -1)
			{
				buildMode = " -" ~ buildMode;
			}
		}
		return true;
	}
	catch(Exception e) 
	{
		writeln(" Read ini file err,you should input something in ini file.",e.msg);
		return false;
	}
}

bool checkArgs(string[] args)
{
	string c;
	size_t p;
	bool bDFile =false;
	foreach(int i,arg;args)
	{
		if(i == 0) continue;
		c = toLower(arg);
		p = c.indexOf('-');
		if(p == -1 || c.indexOf(".d") != -1)
		{

			strTargetName = c[0..$-1].idup;
 			strDFile ~= " ";
			strDFile ~= c;
			bDFile = true;
		}
		else
		{
			c = c[p+1 .. $];
		}
 
		if(c == "h" || c == "help")//toLower(args[1])
		{
			bHelp = true;
		}
		else if(c == "force")
		{
			bForce = true;
		}
		else if(c.indexOf("of") != -1)
		{
			bAssignTarget = true;
			strTargetName = c[(c.indexOf("of")+1)..$];
		}
		else if(strPackageName !="")
		{
			if(c == strPackageName || c == strPackageName ~ "lib")
			{ 
				bAssignTarget = true;
				bBuildSpecialLib = true;
				strTargetTypeSwitch = " -" ~ targetTypeDefault;
				strTargetName = c ~ ".lib";
			}
	    }
		else if(c == "ini" || c == "init")
		{
			bInitINI = true;
		}
	} 
	return bDFile;
}
 
bool CheckBinFolderAndCopy() 
{
	if(checkIsUpToDate())
	{
		writeln(strTargetName ~" file is up to date.");
		return false;
	}
	return true;
}

bool checkIsUpToDate()
{
	getTargetInfo();
	if(exists(strTargetFileName))
	{
		targetTime = getTargetTime(strTargetFileName);

        if(strTargetFileName.indexOf("dco.exe") != -1)
        {
			if(!checkIsUpToDate(strDCEnvFile ,targetTime))
			{
				auto files = dirEntries(".","dco.{exe,ini}",SpanMode.shallow);
				foreach(d;files)
				{
					string strcopy ="copy " ~ d ~" " ~ strDCEnv;
					writeln(strcopy);
					auto pid = enforce(spawnShell(strcopy.dup()),"spawnShell(strcopy.dup()) is err!");
					if (wait(pid) != 0)
					{
						writeln("copy failed.");
					}
				}
				//copy(strTargetFileName,strDCEnvFile);
			}
 	    }

		bool bUpToDate = (targetTime >= sourceLastUpdateTime);

		if(!bUpToDate || bForce)
		{
			removeExe(strTargetFileName);
		}
 		return bUpToDate;
    }

    return false;
}

SysTime getTargetTime(string strPathFile)
{
	return DirEntry(strPathFile).timeLastModified;
}

void removeExe(string strPathExe)
{
	if(!findStr(strPathExe,targetExt)) return;
    if(exists(strPathExe))
	{
		auto pid = enforce(spawnShell("del " ~ strPathExe.dup()),"del " ~ strPathExe.dup() ~ " Err");
		if (wait(pid) != 0)
        {
			writeln(strPathExe ~ ", remove  failed!");
			return;
		}
		else
		{
			writeln(strPathExe ~ ", remove  ok!");
		}
	}
}

bool checkIsUpToDate(string strPathFile,SysTime targettime)
{
	if(!exists(strPathFile)) return false;
    auto testFile = DirEntry(strPathFile);
    auto createTime = testFile.timeLastModified;

    return (targettime <= createTime);
}

void buildExe(string[] args)
{
	string c;
	size_t p;

	if(bGetLocal) goto build;

	foreach(int i,arg;args)
	{
		if(i ==0) continue;
		c = toLower(arg);
		p = c.indexOf('-');
		if(p != -1)
		{
			c = c[p+1 .. c.length];

			switch(c)
			{
				case "h","help":
					ShowUsage();
					break;
				case "gui":
					strTargetLflags = strWindows;
					bUseSpecialLib = true;
					strAddArgs = strAddArgsdfl;
					break;
				case "use":
					bUseSpecialLib = true;
					strAddArgs = strAddArgsdfl;
					break;
				case "win","windows","winexe":
					strTargetLflags = strWindows;
					break;
				case "debug":
					bDebug = true;
					break;
				case "release":
					bDebug = false;
					buildMode = " -" ~ c.idup;
					break;

				case "console","con","exe":
					strTargetLflags = strConsole;
					break;
				case "all":
					bUseSpecialLib = false;
					strAddLib = strLibs;
					strAddArgs = strAddArgsdfl;
					strImport = strImportDefault;
					strTargetLflags = strConsole;
					break;
				case "addlib":
					strAddLib = strLibs~" ";
					strImport = strImportDefault;
					strTargetLflags = strConsole;
					break;
				case "arg":
					strAddArgs = strAddArgsdfl;
					break;
				case "lib":
					strTargetTypeSwitch = " -" ~ targetTypeDefault;
					break;
				case "dfl","dfllib":
					bBuildSpecialLib = true;
					strTargetTypeSwitch = " -" ~ targetTypeDefault;
					break;
				case "copy":
					bCopy = true;
					break;
				case "force":
					bForce = true;
					break;
				case "shared":
					strTargetTypeSwitch = " -" ~ targetTypeShared;
					strTargetType = "dll";
					break;
				default:
					if(c == "m64" || c == "m32mscoff")
					{ 
						compileType =c[1..$];
					}
					strOtherArgs ~= " ";
					strOtherArgs ~= arg;
					break;
    		}
    	}
	}

	strTargetLib = bDebug ? SpecialLib ~ "_debug" ~ compileType ~ ".lib" : SpecialLib ~ compileType ~ ".lib" ;

	if(bBuildSpecialLib)
	{
		strOtherArgs ~= " -of" ~ strTargetLib;
		strAddLib = strLibs;
		strTargetFileName = getcwd() ~ separator ~ strTargetLib;
	}
	else
	{
		strTargetFileName = getcwd() ~ separator ~ strTargetName;
	}

   
    if(strTargetLflags == "" && strLflags !="")
	{
		strTargetLflags = strLflags;
	}
	
	if(strTargetLflags == "" && strLflags =="")
	{
		if(bUseSpecialLib) 
			strTargetLflags = strWindows;
		else
			strTargetLflags = strConsole;
	}

build: 
	
	if(strDflags !="")
    {
    	strOtherArgs ~= " ";
    	strOtherArgs ~= strDflags;
    }
 
	if(bUseSpecialLib)
	{
		if(SpecialLib == "dfl")
		{
			strTargetLib = bDebug ? SpecialLib ~ "_debug" ~ compileType ~ ".lib" : SpecialLib ~ compileType ~ ".lib" ;
			strLibs =strWinLibs;
		}
		if(SpecialLib !="")
		{
			strAddLib = strLibs ~" " ~ strTargetLib ;
		}
	}
	else
	{
		strAddLib = strLibs;
	}

	if(compileType == "64")
	{
		if(strip(strTargetLflags) !=strip(strConsole))
		{
			if(strAddLib.indexOf(strip(strWinLibs64)) == -1)
			{
				strAddLib ~= strWinLibs64;
			}
 
		    strTargetLflags = bUseSpecialLib ? strWindows64 : strWindows;
		}
		else //console x64 not set
		{
			strTargetLflags= "";
		}
	} 

	buildExe();
}

void buildExe()
{
	if(bForce)
	{
		removeExe(strTargetFileName);
	}
	strDC ~= " ";
	strDC ~= strTargetTypeSwitch;
	string strCommon = strOtherArgs ~" " ~ strImportDefault ~ strImport ~ " " ~ strAddLib ~ strTargetLflags ~ strDFile ~ buildMode;
    string buildstr = strDC ~ strAddArgsdfl ~ strCommon ~ "\r\n";
	buildstr = bUseSpecialLib ? buildstr : strDC ~ strCommon;

	StopWatch sw;
	sw.start();
	auto pid =  enforce(spawnShell(buildstr.dup()),"build function is error! ");

	if (wait(pid) != 0)
	{
		writeln("\n"~ buildstr);
		writeln("\nCompilation failed:\n", pid);
		
		auto err = File("ErrBuild.txt","w"); 
		scope(failure) err.close();
		err.writeln(buildstr);
		err.close();
	}
	else
	{
		sw.stop();

		writeln(buildstr);
		writeln("\nCompile time :" , sw.peek().msecs/1000.0,"secs");

		if(bCopy)
		{
			copyFile();
		}
	}

	writeln("End.");
}

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
	if(i ==0)
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
-gui       Make a Windows GUI exe without a console(For DFL or Dgui).
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

IgnoreFiles:If you have some files to ignore,please put them in Folder 'ignoreFiles'.
  ");
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
				strArgs = strAddArgsdfl = " -g -de -w -property -X ";
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

void initNewConfigFile()
{
	string strConfig = configFileLocal;
	auto ini = File(strConfig,"w"); 
	scope(failure) ini.close();
	ini.writeln("DC=" ~ strDC);
	ini.writeln("DCStandardEnvBin=" ~ strDCStandardEnvBin);
 
	if(SpecialLib =="")
	{
		ini.writeln(";SpecialLib=" ~ SpecialLib);
		ini.writeln("SpecialLib=");
	}
	else
	{
		ini.writeln("SpecialLib=" ~ SpecialLib);
	}
    if(strImportDefault =="")
	{
		ini.writeln(";importPath=" );
		ini.writeln("importPath=");
	}
	else
	{
		ini.writeln("importPath=" ~ strImportDefault);
	}
	ini.writeln(";lflags=console");
	ini.writeln("lflags=win32");
	ini.writeln(";lflags=win64");

	ini.writeln(";dflags=");
	ini.writeln(";libs=");

	ini.writeln(";targetType=exe//lib//staticLib//dynamicLib//sourceLib//none");
	ini.writeln("targetType=exe");
	ini.writeln(";targetName=;//    ;'null is auto'");
	ini.writeln("targetName=");
	ini.writeln(";compileType=;//64//32mscoff");
	ini.writeln("compileType=");
	ini.writeln(";buildMode=debug;//release");
	ini.writeln("buildMode=debug");

	ini.close();

	auto pid = spawnProcess(["notepad.exe",strConfig]);
    auto dmd = tryWait(pid);
	if (dmd.terminated)
	{
		if (dmd.status == 0) writeln("open "~ strConfig ~" succeeded!");
		else writeln("open "~ strConfig ~" failed");
	}
	else writeln("Please add your Args...");

}

void readInJson()
{
	if(!exists("dub.json") && !exists("package.json") ) return;
}
