module dco.checkInfo;

import std.file;
import std.string;
import std.process;
import std.stdio;
import	std.datetime;
import std.exception;

import dco.readConfigs;
import dco.globalInfo;
import dco.operateFile;


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
		else if(c == "version")
		{
			bVersion = true;
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
		writeln(strTargetName ~ " file is up to date.");
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
					string strcopy ="copy " ~ d ~ " " ~ strDCEnv;
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
