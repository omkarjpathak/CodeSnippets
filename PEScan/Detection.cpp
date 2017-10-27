#include "PEScan.h"

DWORD
GetFileExecutionStart(
	int iFd
	)
{
	int i,iRead;
	PE_FILE_HEADER PeFileHeader;
	PE_SECTION_HEADER PeSectionHeader;
	PE_OPTIONAL_HEADER PeOptionalHeader;
	DWORD dwOffset,dwPEHeaderOffset,dwPhyAddr,dwVirAddr;

	dwOffset = _lseek(iFd, 0x3c, SEEK_SET);
	iRead = _read(iFd, &dwPEHeaderOffset, sizeof(dwPEHeaderOffset));
	if (iRead != sizeof(dwPEHeaderOffset))
	{
		perror("Error reading file:");
		return 0;
	}

	dwOffset = _lseek(iFd, dwPEHeaderOffset + sizeof(dwOffset), SEEK_SET);
	if (-1 == dwOffset)
	{
		perror("Error moving file pointer:");
		return 0;
	}

	iRead = _read(iFd, &PeFileHeader, sizeof(PE_FILE_HEADER));
	if (iRead != sizeof(PE_FILE_HEADER))
	{
		perror("Error reading file:");
		return 0;
	}

	iRead = _read(iFd, &PeOptionalHeader, sizeof(PE_OPTIONAL_HEADER));
	if (iRead != sizeof(PE_OPTIONAL_HEADER))
	{
		perror("Error reading file:");
		return 0;
	}

	for (i = 0; i < PeFileHeader.NumberOfSections; i++)
	{
		iRead = _read(iFd, &PeSectionHeader, sizeof(PE_SECTION_HEADER));
		if (iRead != sizeof(PE_SECTION_HEADER))
		{
			perror("Error reading file");
			return 0;
		}

		dwVirAddr = PeOptionalHeader.AddressOfEntryPoint;
		if (dwVirAddr >= PeSectionHeader.VirtualAddress &&
			dwVirAddr < (PeSectionHeader.VirtualAddress + PeSectionHeader.SizeOfRawData))
		{
			dwPhyAddr = dwVirAddr - PeSectionHeader.VirtualAddress;
			dwPhyAddr += PeSectionHeader.PointerToRawData;
		}
	}

	return dwPhyAddr;
}

int
DetectAgentBsv(
	int iFd,
	DWORD dwAddressOfEntryPoint
	)
{
	DWORD dwOffset;
	BYTE byBuffer[20];
	int iRead,iFlag,i,j;
	DWORD dwPEHeaderOffset;
	PE_FILE_HEADER PeFileHeader;
	PE_SECTION_HEADER PeSectionHeader;
	PE_OPTIONAL_HEADER PeOptionalHeader;
	
	BYTE bySignature[] = {	0x55, 0x8B, 0xEC, 0x83, 0xC4,
									0xD0, 0x53, 0x56, 0x57, 0x8D,
									0x75, 0xFC, 0x8B, 0x44, 0x24,
									0x30, 0x25, 0x00, 0x00, 0xFF
								};

	dwOffset = _lseek(iFd, dwAddressOfEntryPoint, SEEK_SET);
	if (dwOffset != dwAddressOfEntryPoint)
	{
		perror("Error moving file pointer:");
		return 0;
	}

	iRead = _read(iFd, byBuffer, sizeof(byBuffer));
	if (iRead != sizeof(byBuffer))
	{
		perror("Error reading file:");
		return 0;
	}

	for (i = 0; i < sizeof(byBuffer); i++)
	{
		if (bySignature[0] == byBuffer[i])
		{
			for (j = 1; j <= (sizeof(bySignature)-1); j++,i++)
			{
				if (bySignature[j] == byBuffer[i+1])
				{
					continue;
				}
				else
				{
					break;
				}
			}

			if (sizeof(bySignature) == j)
			{
				iFlag = 1;
				break;
			}
		}
	}

	if (1 == iFlag)
	{
		dwOffset = _lseek(iFd, 0x3c, SEEK_SET);
		iRead = _read(iFd, &dwPEHeaderOffset, sizeof(dwPEHeaderOffset));
		if (iRead != sizeof(dwPEHeaderOffset))
		{
			perror("Error reading file:");
			return 0;
		}

		dwOffset = _lseek(iFd, dwPEHeaderOffset + sizeof(dwOffset), SEEK_SET);
		if (-1 == dwOffset)
		{
			perror("Error moving file pointer:");
			return 0;
		}

		iRead = _read(iFd, &PeFileHeader, sizeof(PE_FILE_HEADER));
		if (iRead != sizeof(PE_FILE_HEADER))
		{
			perror("Error reading file:");
			return 0;
		}

		iRead = _read(iFd, &PeOptionalHeader, sizeof(PE_OPTIONAL_HEADER));
		if (iRead != sizeof(PE_OPTIONAL_HEADER))
		{
			perror("Error reading file:");
			return 0;
		}

		for (i = 0; i < PeFileHeader.NumberOfSections; i++)
		{
			iRead = _read(iFd, &PeSectionHeader, sizeof(PE_SECTION_HEADER));
			if (iRead != sizeof(PE_SECTION_HEADER))
			{
				perror("Error reading file");
				return 0;
			}
		}
		
		if (0 == strcmp((char *)PeSectionHeader.Name,".lea"))
		{
			return 1;
		}
	}
	else
	{
		return 0;
	}
	
	return 0;
}

int
DetectMumawowB(
	int iFd,
	DWORD dwAddressOfEntryPoint
	)
{
	DWORD dwOffset;
	BYTE byBuffer[20];
	int iRead,iFlag,i,j;
	DWORD dwPEHeaderOffset;
	PE_FILE_HEADER PeFileHeader;
	PE_SECTION_HEADER PeSectionHeader;
	PE_OPTIONAL_HEADER PeOptionalHeader;
	
	BYTE bySignature[] = {	0x55, 0x8B, 0xEC, 0x83, 0xC4,
									0xD0, 0x53, 0x56, 0x57, 0x8D,
									0x75, 0xFC, 0x8B, 0x44, 0x24,
									0x30, 0x25, 0x00, 0x00, 0xFF
								};

	dwOffset = _lseek(iFd, dwAddressOfEntryPoint, SEEK_SET);
	if (dwOffset != dwAddressOfEntryPoint)
	{
		perror("Error moving file pointer:");
		return 0;
	}

	iRead = _read(iFd, byBuffer, sizeof(byBuffer));
	if (iRead != sizeof(byBuffer))
	{
		perror("Error reading file:");
		return 0;
	}

	for (i = 0; i < sizeof(byBuffer); i++)
	{
		if (bySignature[0] == byBuffer[i])
		{
			for (j = 1; j <= (sizeof(bySignature)-1); j++,i++)
			{
				if (bySignature[j] == byBuffer[i+1])
				{
					continue;
				}
				else
				{
					break;
				}
			}

			if (sizeof(bySignature) == j)
			{
				iFlag = 1;
				break;
			}
		}
	}

	if (1 == iFlag)
	{
		dwOffset = _lseek(iFd, 0x3c, SEEK_SET);
		iRead = _read(iFd, &dwPEHeaderOffset, sizeof(dwPEHeaderOffset));
		if (iRead != sizeof(dwPEHeaderOffset))
		{
			perror("Error reading file:");
			return 0;
		}

		dwOffset = _lseek(iFd, dwPEHeaderOffset + sizeof(dwOffset), SEEK_SET);
		if (-1 == dwOffset)
		{
			perror("Error moving file pointer:");
			return 0;
		}

		iRead = _read(iFd, &PeFileHeader, sizeof(PE_FILE_HEADER));
		if (iRead != sizeof(PE_FILE_HEADER))
		{
			perror("Error reading file:");
			return 0;
		}

		iRead = _read(iFd, &PeOptionalHeader, sizeof(PE_OPTIONAL_HEADER));
		if (iRead != sizeof(PE_OPTIONAL_HEADER))
		{
			perror("Error reading file:");
			return 0;
		}

		for (i = 0; i < PeFileHeader.NumberOfSections; i++)
		{
			iRead = _read(iFd, &PeSectionHeader, sizeof(PE_SECTION_HEADER));
			if (iRead != sizeof(PE_SECTION_HEADER))
			{
				perror("Error reading file");
				return 0;
			}
		}
		
		if (0 == strcmp((char *)PeSectionHeader.Name,".ani"))
		{
			return 1;
		}
	}
	else
	{
		return 0;
	}
	
	return 0;
}