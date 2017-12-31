module dco.buildExes;

import core.time;

import std.file;
import std.string;
import std.process;
import std.stdio;
import std.datetime;
import std.datetime.stopwatch;
import std.exception;
import dco.readConfigs;
import dco.globalInfo;
import dco.checkInfo;
import dco.operateFile;

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
					strLibs =strWinLibs;
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
					//strImport = strImportDefault;
					//strTargetLflags = strConsole;
					break;
				case "arg":
					strAddArgs = strAddArgsdfl;
					break;
				case "lib":
					strTargetTypeSwitch = " -" ~ targetTypeDefault;
					break;
				case "dfl","dfllib":
					SpecialLib = "dfl";
					bBuildSpecialLib = true;
					strTargetTypeSwitch = " -" ~ targetTypeDefault;
					break;
				case "dgui","dguilib":
					SpecialLib = "dgui";
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
		strOtherArgs ~= " -of" ~ strTargetPath ~ separator ~ strTargetLib;
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

	if(buildMode.toLower().indexOf("debug") != -1)
	{
		strOtherArgs ~= " -g";
	}

	if(strDflags != "")
    {
    	strOtherArgs ~= " ";
    	strOtherArgs ~= strDflags;
    }

	if(strObjPath != "")
	{
		strOtherArgs ~= " -od";
    	strOtherArgs ~= strObjPath;
	}

	if(bUseSpecialLib)
	{
		writeln("dco.ini's SpecialLib is ",SpecialLib);
		if(SpecialLib == "dfl" || SpecialLib == "dgui")
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

		    strTargetLflags = strWindows64;
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

	std.datetime.stopwatch.StopWatch sw;
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
		writeln("\nCompile time :" , sw.peek().total!"seconds","secs");

		if(bCopy)
		{
			copyFile();
		}
	}

	writeln("End.");
}
