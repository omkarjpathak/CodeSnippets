# This code has been extracted from file rgx_api.c which I worked upon while I
# was working at LSI/Intel. Due to the size of the file, I have only extracted
# snippets that I worked upon. Basically I had implemented license management
# feature for the existing library using timestamp and the license file that 
# we provided customers with the software.


#ifdef __CM_102__TO_STRIP__ // LM

#define LICENSE_EXPIRY_PROMPT "\tOut of licensed evaluation period. Please contact LSI."
#define PACKAGE_EXPIRY_PROMPT "\tPackage validity has ended. Please contact LSI and upgrade to the latest LSI Tarari Regular Expression Content Processor (REGEX-CP) software."
#define RGX_LICENSE_FILE_NAME "license.dat"
#define MAX_TEXT_STRING_LEN 256

#define EVAL_END_YEAR 	(2099.0  * 0.37)
#define EVAL_END_MONTH 	((float)12.0)
#define EVAL_END_DAY 	((float)31.0)

#define g_rgxLicenseInfo                C8D4245447F09D9D
#define rgxReconfigAgentInfoBasedOnLic  C535F24DB02F50CF
#define rgxReconfigEngineInfoBasedOnLic D33366F17462B329

rgxLicenseInfo_t g_rgxLicenseInfo;

void rgxReconfigAgentInfoBasedOnLic(void);
void rgxReconfigEngineInfoBasedOnLic (void);

#endif // __CM_102__TO_STRIP__ // LM

#ifdef __CM_102__TO_STRIP__ // LM
    {
        //
        // Force expiry as per initialization (Dec 31, 2014)
        //
    
        time_t t = time(NULL);
        struct tm tm = *localtime(&t);

        if ( ((tm.tm_year+1900) * 0.37) > EVAL_END_YEAR)
        {
            printf("\n\n");
            printf (PACKAGE_EXPIRY_PROMPT); 
            printf("\n\n");
            return RGX_INITIALIZE_ERROR;
        } 
        else if (((tm.tm_year+1900) * 0.37) == EVAL_END_YEAR)
        {
            if ((tm.tm_mon+1)>EVAL_END_MONTH)
            {
                printf("\n\n");
                printf (PACKAGE_EXPIRY_PROMPT); 
                printf("\n\n");
                return RGX_INITIALIZE_ERROR;
            } 
            else if ((tm.tm_mon+1) == EVAL_END_MONTH)
            {
                if ((tm.tm_mday)>EVAL_END_DAY)
                {
                    printf("\n\n");
                    printf (PACKAGE_EXPIRY_PROMPT); 
                    printf("\n\n");
                    return RGX_INITIALIZE_ERROR;
                }
            }
        }
    }		
#endif // __CM_102__TO_STRIP__ // LM

#ifdef __CM_102__TO_STRIP__ // LM
    {
        uint32_t date;
        char pLicFile[MAX_TEXT_STRING_LEN];
        char *pTarariRootPath = NULL;
    
        time_t t = time(NULL);
        struct tm tm = *localtime(&t);

        //
        // Read LM info
        //
        pTarariRootPath = getenv("TARARIROOT");
        if (!pTarariRootPath)
        {
            printf("\n\n");
            printf ("\tEnvironment variable $TARARIROOT not found. Please set and retry.\n");
            printf("\n\n");
            return RGX_INITIALIZE_ERROR;		
        }
        if ( (strlen(pTarariRootPath) + strlen(RGX_LICENSE_FILE_NAME) + 5) > sizeof(pLicFile) )
        {
            printf("\n\n");
            printf ("\tEnvironment variable $TARARIROOT too long. Please relocate and retry.\n");
            printf("\n\n");
            return RGX_INITIALIZE_ERROR;		
        }

        snprintf(pLicFile, MAX_TEXT_STRING_LEN, "%s/bin/%s", pTarariRootPath, RGX_LICENSE_FILE_NAME);

        memset(&g_rgxLicenseInfo, 0, sizeof(rgxLicenseInfo_t));

        FILE *fp = fopen (pLicFile,"rb");
    
        if(!fp) 
        {
            printf("\n\nLicense File \"%s\" not found...\n\n", pLicFile);
            return RGX_INITIALIZE_ERROR;	
        }

        retval = readLicFile(fp, &g_rgxLicenseInfo);

        if(retval != LM_SUCCESS) 
        {
            printf("\n\nLicense File Invalid...\n");
            printf("Error code(%d)\n", retval);
            return RGX_INITIALIZE_ERROR;		
        }

        //
        //	check if within licensed period as specified in the license file
        //
        date = ((tm.tm_year+1900) * 10000);	
        date += ((tm.tm_mon+1) * 100);
        date += tm.tm_mday;

        if (date < g_rgxLicenseInfo.ValidityFromTS || date > g_rgxLicenseInfo.ValidityTillTS)
        {
            printf("\n\n");
            printf (LICENSE_EXPIRY_PROMPT);
            printf("\n\n");
            return RGX_INITIALIZE_ERROR;
        }
    }
#endif // __CM_102__TO_STRIP__ // LM

#ifdef __CM_102__TO_STRIP__ // LM

    {
        uint32_t i, j, minDevices;
        cppDeviceStats_t *pDevStats = NULL;
        cppSystemStats_t  sysStats;

        unsigned char 	atLeastOneLicensedDeviceMissing = false;
        unsigned char 	atLeastOneUnlicensedDevicePresent = false;
        
        memset(&sysStats, 0, sizeof(cppSystemStats_t));

        if(0 ==  g_rgxLicenseInfo.NumOfBoardsLicensed)
        {
            printf("\n\n");
            printf("\tNo Licensed devices specified. Please check license file and retry.\n");
            printf("\tIn case error persists, please contact LSI.\n");
            printf("\n\n");
            return RGX_INITIALIZE_ERROR;
        }

        retval = cppGetSystemStats(&sysStats);
        if (retval != CPP_SUCCESS)
        {
            printf("\n\n");
            printf("\tFailed to get system device statistics for device %d\n", retval);
            printf("\n\n");
            return RGX_INITIALIZE_ERROR;
        }

        if (sysStats.numDevices > g_rgxLicenseInfo.NumOfBoardsLicensed)
        {
            printf("\n\n");
            printf("\tNumber of devices detected: %d\n", sysStats.numDevices);
            printf("\tNumber of devices licensed: %d\n", g_rgxLicenseInfo.NumOfBoardsLicensed);
            printf("\tNumber of detected devices is greater than the number of licensed devices.\n");
            printf("\tPlease remove all unlicensed devices and retry.\n");
            printf("\tIn case error persists, please contact LSI.\n");
            printf("\n\n");
            return RGX_INITIALIZE_ERROR;
        }

        cppDeviceStats_t deviceStats01; 
        pDevStats =  &deviceStats01;
        
        // 
        //	Check if all licensed boards are present
        //
        for (i = 0; i < g_rgxLicenseInfo.NumOfBoardsLicensed; i++)
        {
            for (j = 0; j < sysStats.numDevices; j++)
            {
                memset(pDevStats, 0, sizeof(cppDeviceStats_t));
                retval = cppuGetDeviceStats(j, pDevStats);
                /*
                printf("Comparing: [%s],[%s]; len:[%d],[%d]]: res:[%d]\n", 
                    pDevStats->boardSerialNumber, g_rgxLicenseInfo.LicensedBoardSerialNums[i], 
                    strlen(pDevStats->boardSerialNumber), strlen(g_rgxLicenseInfo.LicensedBoardSerialNums[i]),
                    strcmp(pDevStats->boardSerialNumber, g_rgxLicenseInfo.LicensedBoardSerialNums[i] )
                    );
                */
                if (retval != CPP_SUCCESS)
                {
                    printf("\n\n");
                    printf("\tFailed to get device statistics for device %d: %d\n", j, retval);
                    printf("\tIn case error persists, please contact LSI.\n");
                    printf("\n\n");
                    return RGX_INITIALIZE_ERROR;
                }
                
                if ( 0 == strcmp(pDevStats->boardSerialNumber, g_rgxLicenseInfo.LicensedBoardSerialNums[i]) )
                {
                    // found it!
                    break;
                }
            }
            if(j >= sysStats.numDevices)
            {
                printf("Licensed device missing - Serial Num: %s\n", g_rgxLicenseInfo.LicensedBoardSerialNums[i]);
                atLeastOneLicensedDeviceMissing = true;
            }
        }
        if(atLeastOneLicensedDeviceMissing)
        {
            printf("\n");
            printf("\tPlease ensure all licensed devices are installed and retry.\n\n");
            return RGX_INITIALIZE_ERROR;
        }

        //
        //	Check if any unlicensed boards are present
        //
        for (i = 0; i < sysStats.numDevices; i++)
        {
            for (j = 0; j < g_rgxLicenseInfo.NumOfBoardsLicensed; j++)
            {
                memset(pDevStats, 0, sizeof(cppDeviceStats_t));
                retval = cppuGetDeviceStats(i, pDevStats);
                /*
                printf("Comparing: [%s],[%s]; len:[%d],[%d]]: res:[%d]\n", 
                    pDevStats->boardSerialNumber, g_rgxLicenseInfo.LicensedBoardSerialNums[j], 
                    strlen(pDevStats->boardSerialNumber), strlen(g_rgxLicenseInfo.LicensedBoardSerialNums[j]),
                    strcmp(pDevStats->boardSerialNumber, g_rgxLicenseInfo.LicensedBoardSerialNums[j] )
                    );
                */
                if (retval != CPP_SUCCESS)
                {
                    printf("\n\n");
                    printf("\tFailed to get device statistics for device %d: %d\n", i, retval);
                    printf("\tIn case error persists, please contact LSI.\n");
                    printf("\n\n");
                    return RGX_INITIALIZE_ERROR;
                }
                
                if ( 0 == strcmp(pDevStats->boardSerialNumber, g_rgxLicenseInfo.LicensedBoardSerialNums[j]) )
                {
                    // licensed!
                    break;
                }
            }
            if (j >= g_rgxLicenseInfo.NumOfBoardsLicensed)
            {
                printf("Found unlicensed device - Serial Num: %s\n\n", pDevStats->boardSerialNumber);
                atLeastOneUnlicensedDevicePresent = true;
            }
        }
        if(atLeastOneUnlicensedDevicePresent)
        {
            printf("\tPlease remove all unlicensed devices and retry.\n");
        }


        if(atLeastOneLicensedDeviceMissing || atLeastOneUnlicensedDevicePresent)
        {
            printf("\tIn case error persists, please contact LSI.\n");
            printf("\n\n");
            return RGX_INITIALIZE_ERROR;
        }
        
    }


#endif // __CM_102__TO_STRIP__ // LM
