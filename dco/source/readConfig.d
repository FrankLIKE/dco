module dco.readConfigs;

import	std.string;
import std.exception;
import std.file;
import std.stdio;
import std.process:spawnProcess,tryWait;

import dco.globalInfo;

//ini
string configFile ="dco.ini",configFileLocal = "local.ini";
string[string] configKeyValue;

bool readConfig(string _configFile)
{ 
	try
	{ 
		string strConfigPath = "",targetType = "",targetName = "";
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
			if(!bGetLocal) return true;//not exists,but can work.
			//{
			//	initNewConfigFile();
			//	return false;
			//} 
		}
		auto file = File(strConfigPath); 
		scope(failure) file.close();
		auto range = file.byLine();
		foreach (line; range)
		{
			if (!line.init && line[0] != '#' && line[0] != ';' && line.indexOf("=") != -1)
			{ 
				ptrdiff_t i = line.indexOf("=");
				ptrdiff_t j = line.indexOf(";");
				if(j == -1)
				{
					configKeyValue[line.strip()[0..i].idup] = line.strip()[i+1..$].idup;
				}
				else
				{
					configKeyValue[line.strip()[0..i].idup] = line.strip()[i+1..j].idup;
				}
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
        strTargetPath = configKeyValue.get("targetPath","");
        strObjPath = configKeyValue.get("objPath","");

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
				default:
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
				strOtherArgs ~= " -of" ~ strTargetPath ~ separator ~ strTargetName;
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
    if(strImportDefault == "")
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
	ini.writeln("targetPath=Debug;// bin\\Debug");
	ini.writeln("objPath=Debug;// bin\\Debug");

	ini.close();

	auto pid = spawnProcess(["notepad.exe",strConfig]);
    auto dmd = tryWait(pid);
	if (dmd.terminated)
	{
		if (dmd.status == 0) 
		{
			writeln("open "~ strConfig ~" succeeded!");
		}
		else 
		{
			writeln("open "~ strConfig ~" failed");
		}
	}
	else 
	{
		writeln("Please add your Args...");
	}
}
