#include "PEScan.h"

int
main(
	int iArgc,
	char * pchArgv[]
	)
{
	int iRes,iFd;
	int iExe,iPe,iDetect;
	DWORD dwAddressOfEntryPoint;

	iRes = IsDir(pchArgv[1]);
	if (1 == iRes)
	{
		ScanDirectory(pchArgv[1]);
	}
	else if (0 == iRes)
	{
		iFd = _open(pchArgv[1], _O_RDONLY | _O_BINARY);
		if (-1 == iFd)
		{
			perror("Error opening file");
		}
		
		iExe = IsExeFile(iFd);
		if (1 != iExe)
		{
			printf("%s:",pchArgv[1]);
			printf("The file is not .EXE file. \n");
			_close(iFd);
		}

		iPe = IsPeFile(iFd);
		if (0 == iPe)
		{
			printf("%s:",pchArgv[1]);
			printf("The file is not P E File. \n");
			_close(iFd);
		}

		printf("%s:",pchArgv[1]);
		dwAddressOfEntryPoint = GetFileExecutionStart(iFd);
		iDetect = DetectMumawowB(iFd, dwAddressOfEntryPoint);
		
		if (1 == iDetect)
		{
			printf("File is infected.\n");
		}
		else
		{
			printf("File is clean.\n");
		}
	}

	return 0;
}

int
IsDir(
	char *pchFileName
	)
{
	int iResult;
	struct _stat Buffer;

	iResult = _stat(pchFileName, &Buffer);
	if (-1 == iResult)
	{
		perror("Error obtaining file information.");
		return -1;
	}
	else
	{
		if (Buffer.st_mode & _S_IFDIR)
		{
			return 1;
		}
		else if (Buffer.st_mode & _S_IFREG)
		{
			return 0;
		}
	}

	return -1;
}



int
IsExeFile(
	int iFd
	)
{
	WORD wMagicNo;
	int iRead = 0;

	iRead = _read(iFd, &wMagicNo, sizeof(wMagicNo));
	if (iRead != sizeof(wMagicNo))
	{
		perror("Error reading file");
		return 0;
	}

	if (wMagicNo == 0x5a4d)
	{
		return 1;
	}

	return 0;
}

int
IsPeFile(
	int iFd
	)
{
	DWORD dwPEid;
	long lOffset;
	int iRead = 0;
	DWORD dwPEHeaderOffset;

	lOffset = _lseek(iFd, 0x3c, SEEK_SET);
	if (0x3c != lOffset)
	{
		perror("Error moving file pointer");
		return 0;
	}

	iRead = _read(iFd, &dwPEHeaderOffset, sizeof(dwPEHeaderOffset));
	if (iRead != sizeof(dwPEHeaderOffset))
	{
		perror("Error reading file");
		return 0;
	}

	lOffset = _lseek(iFd, dwPEHeaderOffset, SEEK_SET);
	if (lOffset != (long)dwPEHeaderOffset)
	{
		perror("Error moving file pointer");
		return 0;
	}

	iRead = _read(iFd, &dwPEid, sizeof(dwPEid));
	if (iRead != sizeof(dwPEid))
	{
		perror("Error reading file");
		return 0;
	}

	if (dwPEid == 0x00004550)
	{
		return 1;
	}

	return 0;
}

void
ScanDirectory(
	char pchFileName[200]
	)
{
	char pchTempName[200];
	long lHandle,lStart = 0;
	struct _finddata_t file;
	DWORD dwAddressOfEntryPoint;
	int iRes,iFd,iExe,iPe,iDetect;

	if (0 == IsDir(pchFileName))
	{
		iFd = _open(pchFileName, _O_RDONLY | _O_BINARY);
		if (-1 == iFd)
		{
			perror("Error opening file");
			return;
		}

		iExe = IsExeFile(iFd);
		if (1 != iExe)
		{
			printf("The file is not .EXE file. \n");
			_close(iFd);
		}

		iPe = IsPeFile(iFd);
		if (0 == iPe)
		{
			printf("The file is not P E File. \n");
			_close(iFd);
		}

		_close(iFd);
	}
	else
	{
		strcpy(pchTempName, pchFileName);
		strcat(pchTempName, "\\*.*");
		
		lHandle = _findfirst(pchTempName, &file);
		if (-1 == lHandle)
		{
			printf("No files found.\n");
		}
		else
		{
			char string[200];
			strcpy(string, pchFileName);

			do
			{
				strcpy(pchFileName, string);
				
				if (file.name[0] == '.')
				{
					continue;
				}

				strcat(pchFileName, "\\");
				strcat(pchFileName, file.name);
				iRes = IsDir(pchFileName);
				if (1 == iRes)
				{
					ScanDirectory(pchFileName);
				}
				else if (0 == iRes)
				{
					iFd = _open(pchFileName, _O_RDWR | _O_BINARY);
					if (-1 == iFd)
					{
						perror("Error opening file");
					}

					iExe = IsExeFile(iFd);
					if (1 != iExe)
					{
						printf("%s:",pchFileName);
						printf("The file is not .EXE file. \n");
						_close(iFd);
						continue;
					}

					iPe = IsPeFile(iFd);
					if (0 == iPe)
					{
						printf("%s:",pchFileName);
						printf("The file is not P E File. \n");
						_close(iFd);
						continue;
					}

					printf("%s:",pchFileName);
					dwAddressOfEntryPoint = GetFileExecutionStart(iFd);
					iDetect = DetectAgentBsv(iFd, dwAddressOfEntryPoint);
//					iDetect = DetectMumawowB(iFd, dwAddressOfEntryPoint);

					if (1 == iDetect)
					{
						printf("Infected: W32.Agent.Bsv\n");
//						printf("Infected: W32.Mumawow.B\n");

						RepairAgentBsv(iFd);
//						RepairMumawowB(iFd);
					}
					else
					{
						printf("File is clean.\n");
					}
				}

			}while (0 == _findnext(lHandle, &file));
			
		}
	}
}