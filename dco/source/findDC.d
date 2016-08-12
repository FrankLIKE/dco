module dco.findDC;

import std.file;
import std.string;
import std.process;
import std.stdio;

import dco.readConfigs;
import dco.globalInfo;

bool findDCEnv()
{
	if(!readConfig(configFile)) return false;
	bool bLocal = readConfig(configFileLocal);

	string strNoDC = "Not found '" ~ strDC ~ "' in your computer,please setup it.",strTemp,strTempFile;
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

	if(strDCEnvFile == "")
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

		string strTempFile = DCPath ~ separator ~ "dco.exe";
		if(exists(strTempFile)) return true;
	}
	return false;
}

