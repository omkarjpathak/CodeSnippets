#include <io.h>
#include <stdio.h>
#include <fcntl.h>
#include <malloc.h>
#include <string.h>
#include <windows.h>
#include <sys/stat.h>
#include <sys/types.h>

#pragma pack(1)
typedef struct PeFileHeader
{
	WORD Machine;
	WORD NumberOfSections;
	DWORD TimeDateStamp;
	DWORD PointerToSymbolTable;
	DWORD NumberOfSymbols;
	WORD SizeOfOptionalHeader;
	WORD Characteristics;
}PE_FILE_HEADER;
#pragma pack()

#pragma pack(1)
typedef struct DataDirectory
{
    DWORD   VirtualAddress;
    DWORD   Size;
}DATA_DIRECTORY;
#pragma pack()

#pragma pack(1)
typedef struct PeOptionalHeader
{
	WORD Magic;
	BYTE MajorLinkerVersion;
	BYTE MinorLinkerVersion;
	DWORD SizeOfCode;
	DWORD SizeOfInitializedData;
	DWORD SizeOfUninitializedData;
	DWORD AddressOfEntryPoint;
	DWORD BaseOfCode;
	DWORD BaseOfData;
	DWORD ImageBase;
	DWORD SectionAlignment;
	DWORD FileAlignment;
	WORD MajorOperatingSystemVersion;
	WORD MinorOperatingSystemVersion;
	WORD MajorImageVersion;
	WORD MinorImageVersion;
	WORD MajorSubsystemVersion;
	WORD MinorSubsystemVersion;
	DWORD Win32VersionValue;
	DWORD SizeOfImage;
	DWORD SizeOfHeaders;
	DWORD CheckSum;
	WORD Subsystem;
	WORD DllCharacteristics;
	DWORD SizeOfStackReserve;
	DWORD SizeOfStackCommit;
	DWORD SizeOfHeapReserve;
	DWORD SizeOfHeapCommit;
	DWORD LoaderFlags;
	DWORD NumberOfRvaAndSizes;
	DATA_DIRECTORY DataDirectory[16];
}PE_OPTIONAL_HEADER;
#pragma pack()

#pragma pack(1)
typedef struct PeSectionHeader
{
	BYTE Name[IMAGE_SIZEOF_SHORT_NAME];

	union
	{
		DWORD PhysicalAddress;
		DWORD VirtualSize;
	}Misc;

	DWORD VirtualAddress;
	DWORD SizeOfRawData;
	DWORD PointerToRawData;
	DWORD PointerToRelocations;
	DWORD PointerToLinenumbers;
	WORD NumberOfRelocations;
	WORD NumberOfLinenumbers;
	DWORD Characteristics;
}PE_SECTION_HEADER;
#pragma pack()

void
ScanDirectory(
	char pchFileName[200]
	);

int
IsDir(
	char *pchFileName
	);

int
IsExeFile(
	int iFd
	);

int
IsPeFile(
	int iFd
	);

DWORD
GetFileExecutionStart(
	int iFd
	);

int
DetectMumawowB(
	int iFd,
	DWORD dwAddressOfEntryPoint
	);

void
RepairMumawowB(
	int iFd
	);

int
DetectAgentBsv(
	int iFd,
	DWORD dwAddressOfEntryPoint
	);

void
RepairAgentBsv(
	int iFd
	);
