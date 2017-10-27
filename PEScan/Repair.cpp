#include "PEScan.h"

void
RepairAgentBsv(
	int iFd
	)
{
	WORD wNoOfSections;
	DWORD dwJumpOffset;
	int i,iRead,iError,iWrite;
	PE_FILE_HEADER PeFileHeader;
	PE_SECTION_HEADER PeSectionHeader,PeSectionHeaderZero;
	DWORD dwOffset,dwOriginalAddressOfEntryPoint,dwSectionOffset;

	memset(&PeSectionHeaderZero, 0, sizeof(PeSectionHeaderZero));

	dwOffset = _lseek(iFd, 0x3c, SEEK_SET);
	if (dwOffset != 0x3c)
	{
		perror("Error moving file pointer1:");
		return;
	}

	iRead = _read(iFd, &dwJumpOffset, sizeof(dwJumpOffset));
	if (iRead != sizeof(dwJumpOffset))
	{
		perror("Error reading file:");
		return;
	}

	dwOffset = _lseek(iFd, dwJumpOffset + 4, SEEK_SET);
	if (dwOffset != (dwJumpOffset + 4))
	{
		perror("Error moving file pointer2:");
		return;
	}

	iRead = _read(iFd, &PeFileHeader, sizeof(PE_FILE_HEADER));
	if (iRead != sizeof(PE_FILE_HEADER))
	{
		perror("Error reading file:");
		return;
	}

	dwOffset = _lseek(iFd,
							dwJumpOffset + 24 + PeFileHeader.SizeOfOptionalHeader,
							SEEK_SET
							);
	if (-1 == dwOffset)
	{
		perror("Error moving file pointer2:");
		return;
	}

	for (i = 0; i < PeFileHeader.NumberOfSections; i++)
	{
		iRead = _read(iFd, &PeSectionHeader, sizeof(PE_SECTION_HEADER));
		if (iRead != sizeof(PE_SECTION_HEADER))
		{
			perror("Error reading file:");
			return;
		}
	}

	dwSectionOffset = _tell(iFd);
	dwOffset = _lseek(iFd, PeSectionHeader.PointerToRawData + 0x6766, SEEK_SET);
	if (dwOffset != (PeSectionHeader.PointerToRawData + 0x6766))
	{
		perror("Error moving file pointer0:");
		return;
	}

	iRead = _read(
					iFd,
					&dwOriginalAddressOfEntryPoint,
					sizeof(dwOriginalAddressOfEntryPoint)
					);
	if (iRead != sizeof(dwOriginalAddressOfEntryPoint))
	{
		perror("Error reading file:");
		return;
	}

	dwOffset = _lseek(iFd, dwSectionOffset - 40,	SEEK_SET);
	if (dwOffset != (dwSectionOffset - 40))
	{
		perror("Error moving file pointer0:");
		return;
	}

	iWrite = _write(iFd, &PeSectionHeaderZero, sizeof(PE_SECTION_HEADER));
	if (iWrite != sizeof(PE_SECTION_HEADER))
	{
		perror("Error writing file:");
		return;
	}

	dwOffset = _lseek(iFd, dwJumpOffset + 40, SEEK_SET);
	if (dwOffset != (dwJumpOffset + 40))
	{
		perror("Error moving file pointer3:");
		return;
	}

	iWrite = _write(iFd,
						&dwOriginalAddressOfEntryPoint,
						sizeof(dwOriginalAddressOfEntryPoint)
						);
	if (iWrite != sizeof(dwOriginalAddressOfEntryPoint))
	{
		perror("Error writing file:");
		return;
	}

	dwOffset = _lseek(iFd, dwJumpOffset + 6, SEEK_SET);
	if (dwOffset != (dwJumpOffset + 6))
	{
		perror("Error moving file pointer2:");
		return;
	}
	
	wNoOfSections = PeFileHeader.NumberOfSections - 1;
	iWrite = _write(iFd, &wNoOfSections, sizeof(wNoOfSections));
	if (iWrite != sizeof(wNoOfSections))
	{
		perror("Error writing file:");
		return;
	}

	iError = _chsize(iFd, PeSectionHeader.PointerToRawData);
	if (0 == iError)
	{
		printf("File is repaired.\n");
		return;
	}
}

void
RepairMumawowB(
	int iFd
	)
{
	WORD wNoOfSections;
	int i,iRead,iError,iWrite;
	PE_FILE_HEADER PeFileHeader;
	DWORD dwJumpOffset,dwSectionOffset;
	DWORD dwOffset,dwOriginalAddressOfEntryPoint;
	PE_SECTION_HEADER PeSectionHeader,PeSectionHeaderZero;
	
	memset(&PeSectionHeaderZero, 0, sizeof(PeSectionHeaderZero));
	
	dwOffset = _lseek(iFd, 0x3c, SEEK_SET);
	if (dwOffset != 0x3c)
	{
		perror("Error moving file pointer1:");
		return;
	}

	iRead = _read(iFd, &dwJumpOffset, sizeof(dwJumpOffset));
	if (iRead != sizeof(dwJumpOffset))
	{
		perror("Error reading file:");
		return;
	}

	dwOffset = _lseek(iFd, dwJumpOffset + 4, SEEK_SET);
	if (dwOffset != (dwJumpOffset + 4))
	{
		perror("Error moving file pointer2:");
		return;
	}

	iRead = _read(iFd, &PeFileHeader, sizeof(PE_FILE_HEADER));
	if (iRead != sizeof(PE_FILE_HEADER))
	{
		perror("Error reading file:");
		return;
	}

	dwOffset = _lseek(iFd, dwJumpOffset + 6, SEEK_SET);
	if (dwOffset != (dwJumpOffset + 6))
	{
		perror("Error moving file pointer2:");
		return;
	}

	wNoOfSections = PeFileHeader.NumberOfSections - 1;
	iWrite = _write(iFd, &wNoOfSections, sizeof(wNoOfSections));
	if (iWrite != sizeof(wNoOfSections))
	{
		perror("Error writing file:");
		return;
	}

	dwOffset = _lseek(iFd,
							dwJumpOffset + 24 + PeFileHeader.SizeOfOptionalHeader,
							SEEK_SET
							);
	if (-1 == dwOffset)
	{
		perror("Error moving file pointer2:");
		return;
	}

	for (i = 0; i < PeFileHeader.NumberOfSections; i++)
	{
		iRead = _read(iFd, &PeSectionHeader, sizeof(PE_SECTION_HEADER));
		if (iRead != sizeof(PE_SECTION_HEADER))
		{
			perror("Error reading file:");
			return;
		}
	}

	dwSectionOffset = _tell(iFd);
	
	dwOffset = _lseek(iFd, PeSectionHeader.PointerToRawData + 4, SEEK_SET);
	if (dwOffset != (PeSectionHeader.PointerToRawData + 4))
	{
		perror("Error moving file pointer2:");
		return;
	}
	
	iRead = _read(
					iFd,
					&dwOriginalAddressOfEntryPoint,
					sizeof(dwOriginalAddressOfEntryPoint)
					);
	if (iRead != sizeof(dwOriginalAddressOfEntryPoint))
	{
		perror("Error reading file:");
		return;
	}
	
	dwOffset = _lseek(iFd, dwSectionOffset - 40,	SEEK_SET);
	if (dwOffset != (dwSectionOffset - 40))
	{
		perror("Error moving file pointer0:");
		return;
	}
	
	iWrite = _write(iFd, &PeSectionHeaderZero, sizeof(PE_SECTION_HEADER));
	if (iWrite != sizeof(PE_SECTION_HEADER))
	{
		perror("Error writing file:");
		return;
	}

	dwOffset = _lseek(iFd, dwJumpOffset + 40, SEEK_SET);
	if (dwOffset != (dwJumpOffset + 40))
	{
		perror("Error moving file pointer3:");
		return;
	}

	iWrite = _write(iFd,
						&dwOriginalAddressOfEntryPoint,
						sizeof(dwOriginalAddressOfEntryPoint)
						);
	if (iWrite != sizeof(dwOriginalAddressOfEntryPoint))
	{
		perror("Error writing file:");
		return;
	}

	iError = _chsize(iFd, PeSectionHeader.PointerToRawData);
	if (0 == iError)
	{
		printf("File is repaired.\n");
		return;
	}
}

