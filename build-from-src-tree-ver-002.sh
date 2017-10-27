# Build script that I contributed to while working for LSI/Intel.
# This was used to create, test and deliver the release to customers.

#!/bin/sh



# FIXME: keep old PATH,LD_LIBRARY_PATH in setup; reset to this in teardown

#
#handle_error() {
#    echo "FAILED: line $1, exit code $2"
#    exit 1
#}
#
#trap 'handle_error $LINENO $?' ERR
#


# create-dist distName destDirForCreatedDist TararirootToCreateDistFrom
function create_dist
{
	local distName=$1
	local destDirForCreatedDist=$2
	local TararirootToCreateDistFrom=$3
	local dontStrip=$4
	
	if [ "$dontStrip" == "1" ]
	then
		echo "skipping stripDirectory $TararirootToCreateDistFrom"
	else
		stripDirectory	$TararirootToCreateDistFrom
	fi

	pushd "$TararirootToCreateDistFrom"
		rm -f "$destDirForCreatedDist/$distName"
		mkdir -p "$destDirForCreatedDist"
		tar cf - * | tr "\000-\0377" "\001-\0377\000" | gzip > "$destDirForCreatedDist/$distName"
	popd
}

#create_package_tgz packageTgzName destDirForCreatedPackageTgz dirNameToCreatePackageTgzFrom
function create_package_tgz
{
	packageTgzName=$1
	destDirForCreatedPackageTgz=$2
	dirNameToCreatePackageTgzFrom=$3

	mkdir -p "$destDirForCreatedPackageTgz"
	pushd `dirname $dirNameToCreatePackageTgzFrom`
		tar zcf $destDirForCreatedPackageTgz/$packageTgzName `basename $dirNameToCreatePackageTgzFrom`
	popd
}

#addCommonComponentInfo destDirName fileName componentName toolChain hashTag timeStamp mode[a]
function addCommonComponentInfo
{
	local destDirName=$1
	local fileName=$2
	local componentName=$3
	local toolChain=$4
	local hashTag=$5
	local timeStamp=$6
	local appendMode=$7

	local fullFileName="$destDirName/$fileName"

	if [ "$appendMode" != "a" ]
	then
		rm -rf $fullFileName
	fi

	mkdir -p "$destDirName"

	echo >> $fullFileName
	echo $componentName  >> $fullFileName
	echo $toolChain  >> $fullFileName
	echo >> $fullFileName

	printf "Internal References\n" >> $fullFileName
	echo $hashTag  >> $fullFileName
	echo $timeStamp  >> $fullFileName
	gcc -v 2>&1 | tail -n 1 >> $fullFileName
	date >> $fullFileName
	hostname >> $fullFileName
	uname -r >> $fullFileName

}

function printUsage
{
	echo
	echo Following Env variables must be set
	echo "     WRKROOT: This is used as the working area"
	echo "     PACKAGEDESTDIR: This is directory where the final packages should be copied"
	echo "     MYCODEROOT: This points to the \"CODE_ROOT\" in the src tree"
	echo "     KERNELSOURCE: (optional) This points to kernel source directory; usually KERNELSOURCE=/lib/modules/i\`uname -ri\`/build"
	echo "     BUILD_LABEL: This is the build label e.g. 51 in 6.5.1.51"
	echo "  The WRKROOT and PACKAGEDESTDIR are not created; these are expected to exist and writable"
	echo "  The TARARIROOT will be overwritten, and all its contents lost (if any)"
#	echo "     PATCHTARARIROOT: (optional) This points to Tarari root which has the patch files in the correect structure."
#	echo "            The complete structure will be used and will overwrite any existing, installed versions of the file."
#	echo "	           This is applied at the end. "
	echo
}

function checkRequriedSettings
{
	if [ -z "$WRKROOT" ]; then
		printUsage
		exit 0
	fi
	if [ -z "$PACKAGEDESTDIR" ]; then
		printUsage
		exit 0
	fi
	if [ -z "$MYCODEROOT" ]; then
		printUsage
		exit 0
	fi
	if [ -z "$BUILD_LABEL" ]; then
		printUsage
		exit 0
	fi
}

function setupVersionLabel
{
	# FIXME - version should be read from an ENV Var
	#GA-src
	export VERSION_LABEL="6.5.1.52"
}

function setupTargetPackageLabel
{
	CSP_TARGET_AGENT="swarm"
	CSP_TARGET_AGENT="all"
	# FIXME - target type should be read from an ENV Var
	#GA-src
	export TARGET_PACKAGE_LABEL="csp_regex_$VERSION_LABEL.$CSP_TARGET_AGENT.$CM_TARGET.r"
}

function setupTargetDistLabel
{
	# FIXME - arch should be read from an ENV Var
	# FIXME - gcc, blib details should be read from an ENV Var
	export TARGET_DIST_LABEL="csp_regex_""$VERSION_LABEL""_x86_64-linux-4.3.2"
}


function setupVariables
{
	export TARARIROOT="$WRKROOT/TARARIROOT"
	export DISTROOT="$WRKROOT/DISTs"
	export INTERMEDIATE_TARARIROOT="$WRKROOT/INTERMEDIATE_TARARIROOT"
	export PATH="$TARARIROOT/bin:/usr/lib64/qt-3.3/bin:/usr/kerberos/bin:/usr/local/bin:/bin:/usr/bin:$PATH"
	export LD_LIBRARY_PATH="$TARARIROOT/lib:$LD_LIBRARY_PATH"
	export MYCPPCOREROOT=$MYCODEROOT/release/cpp_base/6.3/current/
	export MYREGEXCPROOT=$MYCODEROOT/release/regex/6.5.1/Linux/current/SW/agents/regex_abraxas/
	if [ -z "$KERNELSOURCE" ]; then
		KERNELSOURCE=/lib/modules/`uname -r`/build
	fi
	export KERNELSOURCE
	export BUILD_LABEL

	# FIXME - target type flags should be set based on target type (read from an ENV Var)
	#export TARGET_TYPE_FLAGS="-D __INTERNAL__TO_STRIP__"
	export TARGET_TYPE_FLAGS="-D __CM_500__TO_STRIP__"

	setupVersionLabel
	setupTargetDistLabel
	setupTargetPackageLabel
	echo
	echo
#	echo PATCHTARARIROOT:$PATCHTARARIROOT
	echo
	echo TARARIROOT:$TARARIROOT
	echo DISTROOT:$DISTROOT
	echo INTERMEDIATE_TARARIROOT:$INTERMEDIATE_TARARIROOT
	echo PACKAGEDESTDIR:$PACKAGEDESTDIR
	echo PATH:$PATH
	echo LD_LIBRARY_PATH:$LD_LIBRARY_PATH
	echo
	echo VERSION_LABEL:$VERSION_LABEL
	echo TARGET_DIST_LABEL:$CM_TARGET_DIST_LABEL
	echo TARGET_PACKAGE_LABEL:$CM_TARGET_PACKAGE_LABEL
	echo BUILD_LABEL:$BUILD_LABEL
	echo
	echo Using Default TARGET_TYPE_FLAGS:$CM_TARGET_TYPE_FLAGS
	echo
}

# installCompilerLibrariesToDir wrkTarariroot
function installCompilerLibrariesToDir
{
	wrkTarariroot=$1
	# common for all

	mkdir -p "$wrkTarariroot"
	mkdir -p "$wrkTarariroot/lib"

	toolchain=$2
	echo $toolchain

	mkdir -p $MYCODEROOT/../otherAssets/compilerComponents/extracted
	pushd $MYCODEROOT/../otherAssets/compilerComponents/extracted
		tar xzf "$MYCODEROOT/../otherAssets/compilerComponents/"$toolchain".binaries.tgz"
		install -m  766 lib/*.so "$wrkTarariroot/lib/"
		install -m  766 lib/*.a "$wrkTarariroot/lib/"
	popd

}

# buildAndInstallCppuLibToDir wrkTarariroot
function buildAndInstallCppuLibToDir
{
	local wrkTarariroot=$1

	# buildCppuLib
	# from function buildCppuLib
	mkdir -p "$wrkTarariroot/config"

	if [ "$CM_TARGET" = "bin" ]; then
		makeFileName=Makefile.linux.internal.to-build-from-coderoot
	else
		makeFileName=Makefile.linux
	fi

	pushd $MYCPPCOREROOT/lib
		make -f $makeFileName clean
		make -f $makeFileName
	popd

	local SAVEDTARARIROOT=$TARARIROOT
    export TARARIROOT=$wrkTarariroot

		pushd $MYCPPCOREROOT/lib
			make -f $makeFileName install
		popd

	cp -f "$MYCODEROOT/release/cpp_base/6.3/current/installer/linux/cpp_core.config" "$TARARIROOT/config/"
	cp -f "$MYCODEROOT/release/cpp_base/6.3/current/installer/linux/cpp_numa_config.ms" "$TARARIROOT/config/"
	export TARARIROOT=$SAVEDTARARIROOT
	unset SAVEDTARARIROOT

}

# cleanupCppuLibIntermediateFilesFromDir wrkTarariroot
function cleanupCppuLibIntermediateFilesFromDir
{
	pushd $MYCPPCOREROOT/lib
		make -f $makeFileName clean
	popd
}


# installRgxLibSourceToDir	wrkTarariroot
function installRgxLibSourceToDir
{
	local wrkTarariroot=$1

    mkdir -p "$wrkTarariroot"
    mkdir -p "$wrkTarariroot/include"
    mkdir -p "$wrkTarariroot/src/lib"
    mkdir -p "$wrkTarariroot/src/lib/deps"
    mkdir -p "$wrkTarariroot/lib"
    mkdir -p "$wrkTarariroot/config"

	cp -f $MYCODEROOT/release/common/Makefile.top $wrkTarariroot/src

	# Installing cpp_base includes - dependencies for building rgxlib
	pushd $MYCPPCOREROOT
		install -m 644 include/*.h $wrkTarariroot/include
	popd

	install -m 644 $MYREGEXCPROOT/../common/platform/platform_common.h $wrkTarariroot/include
	install -m 644 $MYREGEXCPROOT/../common/linux/utillib/memlib/xplatform_mem.h $wrkTarariroot/include
	install -m 644 $MYREGEXCPROOT/common/rgxutil/xplatform_mem.h $wrkTarariroot/include
	install -m 644 $MYREGEXCPROOT/common/rgxutil/rgx_includes.h $wrkTarariroot/include
	install -m 644 $MYREGEXCPROOT/common/rgxutil/rgx_ruleset.h $wrkTarariroot/include
	install -m 644 $MYREGEXCPROOT/common/rgxutil/rgx_xlation.h $wrkTarariroot/include
	install -m 644 $MYREGEXCPROOT/common/rgxutil/rgx_warmupdate.h $wrkTarariroot/include
	install -m 644 $MYREGEXCPROOT/common/rgxutil/rgx_capabilities.h $wrkTarariroot/include
	install -m 644 $MYREGEXCPROOT/common/rgxutil/rgxcommon_misc.h $wrkTarariroot/include
	install -m 644 $MYREGEXCPROOT/compilers/posix/librex.h $wrkTarariroot/include
# FIXME:To delete	install -m 644 $MYREGEXCPROOT/compilers/rgx_ruleset_comp.h $wrkTarariroot/include
	install -m 644 $MYREGEXCPROOT/common/rgxutil/tarari_version.h $wrkTarariroot/include
	install -m 644 $MYREGEXCPROOT/common/rgxutil/rgx_ruleset_platform.h $wrkTarariroot/include
	install -m 644 $MYREGEXCPROOT/common/rgxutil/rgx_byteorder.h $wrkTarariroot/include
	install -m 644 $MYREGEXCPROOT/compilers/common/rgx_bitvec.h $wrkTarariroot/include
    install -m 644 $MYREGEXCPROOT/compilers/rgx_ruleset_comp.h $wrkTarariroot/src/lib/deps/

    # from function buildAndInstallRegexLib

	pushd $MYCODEROOT/release/regex/6.5.1/Linux/current/SW/agents/regex_abraxas/regexcp/libraries/src
		install -m 644 *.[ch] $wrkTarariroot/src/lib
		install -m 644 Makefile.dist $wrkTarariroot/src/lib/Makefile

		rm -f $wrkTarariroot/src/lib/rgx_pcre*
		rm -f $wrkTarariroot/src/lib/rgx_swit.h
		rm -f $wrkTarariroot/src/lib/rgx_api_kernel.c
	popd

    chmod 0644 $wrkTarariroot/src/lib/rgx_api.c
    chmod 0644 $wrkTarariroot/src/lib/rgx_pri.h

    cp -f "$MYCODEROOT/release/regex/6.5.1/Linux/current/SW/agents/regex_abraxas/installer/linux/regexcp.config" "$wrkTarariroot/config/"

	stripDirectory	$wrkTarariroot
}

# buildAndInstallRgxLibToDir destTarariroot wrkTarariroot
function buildAndInstallRgxLibToDir
{
    local destTarariroot=$1
    local wrkTarariroot=$2

    local SAVEDTARARIROOT=$TARARIROOT
    export TARARIROOT=$wrkTarariroot

	stripDirectory	$wrkTarariroot

    pushd $wrkTarariroot/src/lib
        make clean
        make
    popd

    export TARARIROOT=$destTarariroot
	mkdir -p $destTarariroot/src
	cp -f $MYCODEROOT/release/common/Makefile.top $destTarariroot/src
	pushd $wrkTarariroot/src/lib
		make install
	popd

    export TARARIROOT=$wrkTarariroot
    pushd $wrkTarariroot/src/lib
        make clean
    popd

    if [ "$destTarariroot" != "$wrkTarariroot" ]
	then
		rm -f $destTarariroot/src/Makefile.top
	fi

    export TARARIROOT=$SAVEDTARARIROOT
    unset SAVEDTARARIROOT
}

# cleanupRgxLibIntermediateFilesFromDir wrkTarariroot
function cleanupRgxLibIntermediateFilesFromDir
{
	local wrkTarariroot=$1
	# dummy
}


# create_dist_rgxlib_002_binaries componentName distName destDirForCreatedDist wrkTarariroot toolChain timeStamp hashTag 
function create_dist_rgxlib_002_binaries
{
	local componentName=$1
    local distName=$2
    local destDirForCreatedDist=$3
    local wrkTarariroot=$4
	local toolChain=$5
	local timeStamp=$6
	local hashTag=$7
	# common for all

	local fileName=""
	
    installCompilerLibrariesToDir "$wrkTarariroot" "$toolChain"

	fileName="$componentName-info.txt"
	addCommonComponentInfo $wrkTarariroot $fileName $componentName $toolChain $hashTag $timeStamp "c"

	create_dist $distName $destDirForCreatedDist $wrkTarariroot 0
}

#create_dist_cppulib_001_binaries componentName distName destDirForCreatedDist wrkTarariroot toolChain timeStamp hashTag 
function create_dist_cppulib_001_binaries
{
	local componentName=$1
    local distName=$2
    local destDirForCreatedDist=$3
    local wrkTarariroot=$4
	local toolChain=$5
	local timeStamp=$6
	local hashTag=$7
	
	local fileName=""

	# common for all targets
	
	mkdir -p "$wrkTarariroot"
	mkdir -p "$wrkTarariroot/lib"

	buildAndInstallCppuLibToDir $wrkTarariroot

	cleanupCppuLibIntermediateFilesFromDir $wrkTarariroot

	fileName="$componentName-info.txt"
	addCommonComponentInfo $wrkTarariroot $fileName $componentName $toolChain $hashTag $timeStamp "c"
	
	create_dist $distName $destDirForCreatedDist $wrkTarariroot 0
}

#create_dist_driver_001_src componentName distName destDirForCreatedDist wrkTarariroot toolChain timeStamp hashTag
function create_dist_driver_001_src
{
	local componentName=$1
    local distName=$2
    local destDirForCreatedDist=$3
    local wrkTarariroot=$4
	local toolChain=$5
	local timeStamp=$6
	local hashTag=$7
	
	local fileName=""

	# common for all targets

	mkdir -p "$wrkTarariroot"
	mkdir -p "$wrkTarariroot/src/drivers"
	mkdir -p "$wrkTarariroot/src/common"
	mkdir -p "$wrkTarariroot/src/drivers/include"
    mkdir -p "$wrkTarariroot/config"

	# from function installCorePackages

	if [ "$CM_TARGET" = "bin" ]; then
		makeFileName=Makefile.linux.internal.to-build-from-coderoot
	else
		makeFileName=Makefile.linux.internal
	fi

	pushd $MYCPPCOREROOT/drivers
		make -f $makeFileName clean
	popd

	local SAVEDTARARIROOT=$TARARIROOT
    export TARARIROOT=$wrkTarariroot

		pushd $MYCPPCOREROOT/drivers
			make -f $makeFileName install_src
		popd

	cp -f "$MYCPPCOREROOT/common/cpp_chip_types.c" "$wrkTarariroot/src/common/"
    cp -f "$MYCODEROOT/release/cpp_base/6.3/current/installer/linux/cpp_core.config" "$TARARIROOT/config/"
    cp -f "$MYCODEROOT/release/cpp_base/6.3/current/installer/linux/cpp_driver_options.csv" "$TARARIROOT/config/"
    cp -f "$MYCODEROOT/release/cpp_base/6.3/current/installer/linux/cpp_numa_config.ms" "$TARARIROOT/config/"

	stripDirectory	$wrkTarariroot

	export TARARIROOT=$SAVEDTARARIROOT
	unset SAVEDTARARIROOT

	pushd $MYCPPCOREROOT/drivers
		make -f $makeFileName clean
	popd

	create_dist $distName $destDirForCreatedDist $wrkTarariroot 0
}


#create_dist_driver_001_binaries distName destDirForCreatedDist wrkTarariroot
function create_dist_driver_001_binaries
{
	local componentName=$1
    local distName=$2
    local destDirForCreatedDist=$3
    local wrkTarariroot=$4
	local toolChain=$5
	local timeStamp=$6
	local hashTag=$7
	
	local fileName=""


	mkdir -p "$wrkTarariroot"
	mkdir -p "$wrkTarariroot/drivers"
    mkdir -p "$wrkTarariroot/config"

	# from function buildDrivers

	if [ "$CM_TARGET" = "cm500" ]; then
		makeFileName=Makefile.external.cisco
	else
		makeFileName=Makefile.external
	fi

	pushd $MYCPPCOREROOT/drivers
		make -f $makeFileName clean
		make -f $makeFileName
	popd

	local SAVEDTARARIROOT=$TARARIROOT
    export TARARIROOT=$wrkTarariroot

		pushd $MYCPPCOREROOT/drivers
			make -f $makeFileName install
		popd

    cp -f "$MYCODEROOT/release/cpp_base/6.3/current/installer/linux/cpp_core.config" "$TARARIROOT/config/"
    cp -f "$MYCODEROOT/release/cpp_base/6.3/current/installer/linux/cpp_driver_options.csv" "$TARARIROOT/config/"
    cp -f "$MYCODEROOT/release/cpp_base/6.3/current/installer/linux/cpp_numa_config.ms" "$TARARIROOT/config/"
	export TARARIROOT=$SAVEDTARARIROOT
	unset SAVEDTARARIROOT

	pushd $MYCPPCOREROOT/drivers
		make -f $makeFileName clean
	popd

	fileName="$componentName-info.txt"
	addCommonComponentInfo $wrkTarariroot $fileName $componentName $toolChain $hashTag $timeStamp "c"
	
	create_dist $distName $destDirForCreatedDist $wrkTarariroot 0
}

#create_dist_rgxlib_001_src componentName distName destDirForCreatedDist wrkTarariroot toolChain timeStamp hashTag
function create_dist_rgxlib_001_src
{
	local componentName=$1
    local distName=$2
    local destDirForCreatedDist=$3
    local wrkTarariroot=$4
	local toolChain=$5
	local timeStamp=$6
	local hashTag=$7
	
	local fileName=""

    # common for all targets

    installRgxLibSourceToDir "$wrkTarariroot"

	fileName="$componentName-info.txt"
	addCommonComponentInfo $wrkTarariroot $fileName $componentName $toolChain $hashTag $timeStamp "c"
	
    create_dist $distName $destDirForCreatedDist $wrkTarariroot 0
}



#create_dist_rgxlib_001_binaries componentName distName destDirForCreatedDist wrkTarariroot toolChain timeStamp hashTag 
function create_dist_rgxlib_001_binaries
{
	local componentName=$1
    local distName=$2
    local destDirForCreatedDist=$3
    local wrkTarariroot=$4
	local toolChain=$5
	local timeStamp=$6
	local hashTag=$7

	local fileName=""
	
    mkdir -p "$wrkTarariroot/lib"

	intermediateTarariroot="$wrkTarariroot-intermediate"

    # common for all targets
    installRgxLibSourceToDir "$intermediateTarariroot"
	buildAndInstallRgxLibToDir "$wrkTarariroot" "$intermediateTarariroot"

	cleanupRgxLibIntermediateFilesFromDir "$intermediateTarariroot"

    rm -rf $intermediateTarariroot

	addCommonComponentInfo $wrkTarariroot $fileName $componentName $toolChain $hashTag $timeStamp "c"

    create_dist $distName $destDirForCreatedDist $wrkTarariroot 0
}

#create_dist_tools_001_binaries componentName distName destDirForCreatedDist wrkTarariroot toolChain timeStamp hashTag
function create_dist_tools_001_binaries
{
	local componentName=$1
    local distName=$2
    local destDirForCreatedDist=$3
    local wrkTarariroot=$4
	local toolChain=$5
	local timeStamp=$6
	local hashTag=$7
	
	local fileName=""

    mkdir -p "$wrkTarariroot"
    mkdir -p "$wrkTarariroot/bin"
    mkdir -p "$wrkTarariroot/lib"
    mkdir -p "$wrkTarariroot/include"
    mkdir -p "$wrkTarariroot/src/lib"
    mkdir -p "$wrkTarariroot/src/samples/regexcp"

    installCompilerLibrariesToDir "$wrkTarariroot" "$toolChain"

	buildAndInstallCppuLibToDir $wrkTarariroot

    pushd $MYCPPCOREROOT/tools
        make -f $makeFileName clean
        make -f $makeFileName
    popd

    local SAVEDTARARIROOT=$TARARIROOT
    export TARARIROOT=$wrkTarariroot

	# copy scripts to load/unload drivers in the bin directory
	install -m 766 $MYREGEXCPROOT/regexcp/init/linux/load_regexcp.swarm $TARARIROOT/bin/load_regexcp
	install -m 766 $MYREGEXCPROOT/regexcp/init/linux/unload_regexcp $TARARIROOT/bin/

        pushd $MYCPPCOREROOT/tools
            make -f $makeFileName install
        popd

	pushd $MYCODEROOT/release/regex/6.5.1/Linux/current/SW/agents/common/linux/utillib/filelist/
		make -f Makefile.internal.to-build-from-coderoot clean
		make -f Makefile.internal.to-build-from-coderoot
		make -f Makefile.internal.to-build-from-coderoot install
#		make -f Makefile.internal.to-build-from-coderoot clean
	popd

	installRgxLibSourceToDir "$wrkTarariroot"
	buildAndInstallRgxLibToDir "$wrkTarariroot" "$wrkTarariroot"

	cleanupRgxLibIntermediateFilesFromDir "$wrkTarariroot"

	pushd $MYCODEROOT/release/regex/6.5.1/Linux/current/SW/agents/regex_abraxas/tools/rextest/common
		make -f Makefile.internal.to-build-from-coderoot clean
		make -f Makefile.internal.to-build-from-coderoot gen

		install -m 644 Makefile.rextest2 $TARARIROOT/src/samples/regexcp/Makefile
		install -m 644 rextest2.c $TARARIROOT/src/samples/regexcp/rextest2.c
		install -m 644 xpiconfig.l $TARARIROOT/src/samples/regexcp/xpiconfig.l
		install -m 644 sysstat_defs.h $TARARIROOT/include

		install -m 644 Makefile.with_trex.hw $TARARIROOT/src/samples/regexcp/Makefile
		install -m 644 ../../trextest/trextest.c $TARARIROOT/src/samples/regexcp/
		install -m 644 ../../trextest/platform.h $TARARIROOT/src/samples/regexcp/
		make -f Makefile.internal.to-build-from-coderoot build_from_installed_dir
		make -f Makefile.internal.to-build-from-coderoot install
		make -f Makefile.internal.to-build-from-coderoot clean_installed_dir
	popd

	pushd $MYREGEXCPROOT/tools/samples/common
	make install
	popd

	pushd $MYCODEROOT/release/regex/6.5.1/Linux/current/SW/agents/regex_abraxas/compilers/apps
	make -f Makefile.treat clean
	make -f Makefile.treat
	make -f Makefile.treat install
	make -f Makefile.treat clean
	popd

	chmod +x $TARARIROOT/bin/*
	export TARARIROOT=$SAVEDTARARIROOT
    unset SAVEDTARARIROOT

    pushd $MYCPPCOREROOT/tools
        make -f $makeFileName clean
    popd

	cleanupCppuLibIntermediateFilesFromDir $TARARIROOT

	fileName="$componentName-info.txt"
	addCommonComponentInfo $wrkTarariroot $fileName $componentName $toolChain $hashTag $timeStamp "c"

    create_dist $distName $destDirForCreatedDist $wrkTarariroot 0
}

#create_dist_firmware_001 componentName distName destDirForCreatedDist wrkTarariroot toolChain timeStamp hashTag
function create_dist_firmware_001
{
	local componentName=$1
    local distName=$2
    local destDirForCreatedDist=$3
    local wrkTarariroot=$4
	local toolChain=$5
	local timeStamp=$6
	local hashTag=$7
	
	local fileName=""

	mkdir -p "$wrkTarariroot"

    local SAVEDTARARIROOT=$TARARIROOT
    export TARARIROOT=$wrkTarariroot

    pushd $MYCPPCOREROOT
    make -f Makefile.firmware CPX85xx CPX8200 CPX6230 PIMLICO CPX8700 ATHENA
    make -f Makefile.firmware YORICK DINI ZIPPITY PREAKNESS_LITE PREAKNESS INGRID
    make -f Makefile.firmware HUMPHREY INGRID_AM3
    make -f Makefile.firmware LANAI
    #make -f Makefile.firmware LANAI_EMULATION
    popd

	pushd $MYREGEXCPROOT
	make -f Makefile.firmware CPX85xx CPX8200 PIMLICO CPX8700
	make -f Makefile.firmware ATHENA YORICK ZIPPITY PREAKNESS
	make -f Makefile.firmware INGRID HUMPHREY SWARM
	popd

	export TARARIROOT=$SAVEDTARARIROOT
    unset SAVEDTARARIROOT

	fileName="$componentName-info.txt"
	addCommonComponentInfo $wrkTarariroot $fileName $componentName $toolChain $hashTag $timeStamp "c"
	
	create_dist $distName $destDirForCreatedDist $wrkTarariroot 1
}

#create_dist_extlib_001_binaries componentName distName destDirForCreatedDist wrkTarariroot toolChain timeStamp hashTag
function create_dist_extlib_001_binaries
{
	local componentName=$1
    local distName=$2
    local destDirForCreatedDist=$3
    local wrkTarariroot=$4
	local toolChain=$5
	local timeStamp=$6
	local hashTag=$7
	
	local fileName=""

    mkdir -p "$wrkTarariroot/lib"

    intermediateTarariroot="$wrkTarariroot-intermediate"

    # common for all targets
    installIncludesToDir "$intermediateTarariroot"
    buildAndInstallExtLibToDir "$wrkTarariroot" "$intermediateTarariroot"

    rm -rf $intermediateTarariroot
	
	fileName="$componentName-info.txt"
	addCommonComponentInfo $wrkTarariroot $fileName $componentName $toolChain $hashTag $timeStamp "c"
	
    create_dist $distName $destDirForCreatedDist $wrkTarariroot 0
}

# buildAndInstallExtLibToDir destTarariroot wrkTarariroot
function buildAndInstallExtLibToDir
{
    local destTarariroot=$1
    local wrkTarariroot=$2

    local SAVEDTARARIROOT=$TARARIROOT
    export TARARIROOT=$wrkTarariroot

    stripDirectory  $wrkTarariroot


    mkdir -p "$wrkTarariroot/src/ext"
	cp -f $MYREGEXCPROOT/regexcp/libraries/ext/* "$wrkTarariroot/src/ext"
    pushd $wrkTarariroot/src/ext
    make clean
    make
    popd

    export TARARIROOT=$destTarariroot
    mkdir -p $destTarariroot/lib
    mkdir -p $destTarariroot/src

    pushd $wrkTarariroot/src/ext
	cp -f $MYCODEROOT/release/common/Makefile.top "$destTarariroot/src/"
        make install
	rm -rf "$destTarariroot/src"
    popd

    export TARARIROOT=$SAVEDTARARIROOT
    unset SAVEDTARARIROOT
}

#installIncludesToDir wrkTarariroot
function installIncludesToDir
{
    local wrkTarariroot=$1
    mkdir -p "$wrkTarariroot/include"
    mkdir -p "$wrkTarariroot/src/lib/deps"
    pushd $MYCPPCOREROOT
        install -m 644 include/*.h $wrkTarariroot/include
    popd

    install -m 644 $MYREGEXCPROOT/../common/platform/platform_common.h $wrkTarariroot/include
    install -m 644 $MYREGEXCPROOT/../common/linux/utillib/memlib/xplatform_mem.h $wrkTarariroot/include
    install -m 644 $MYREGEXCPROOT/common/rgxutil/xplatform_mem.h $wrkTarariroot/include
    install -m 644 $MYREGEXCPROOT/common/rgxutil/rgx_includes.h $wrkTarariroot/include
    install -m 644 $MYREGEXCPROOT/common/rgxutil/rgx_ruleset.h $wrkTarariroot/include
    install -m 644 $MYREGEXCPROOT/common/rgxutil/rgx_xlation.h $wrkTarariroot/include
    install -m 644 $MYREGEXCPROOT/common/rgxutil/rgx_warmupdate.h $wrkTarariroot/include
    install -m 644 $MYREGEXCPROOT/common/rgxutil/rgx_capabilities.h $wrkTarariroot/include
    install -m 644 $MYREGEXCPROOT/common/rgxutil/rgxcommon_misc.h $wrkTarariroot/include
    install -m 644 $MYREGEXCPROOT/compilers/posix/librex.h $wrkTarariroot/include
# FIXME:To delete   install -m 644 $MYREGEXCPROOT/compilers/rgx_ruleset_comp.h $wrkTarariroot/include
    install -m 644 $MYREGEXCPROOT/common/rgxutil/tarari_version.h $wrkTarariroot/include
    install -m 644 $MYREGEXCPROOT/common/rgxutil/rgx_ruleset_platform.h $wrkTarariroot/include
    install -m 644 $MYREGEXCPROOT/common/rgxutil/rgx_byteorder.h $wrkTarariroot/include
    install -m 644 $MYREGEXCPROOT/compilers/common/rgx_bitvec.h $wrkTarariroot/include
    install -m 644 $MYREGEXCPROOT/compilers/rgx_ruleset_comp.h $wrkTarariroot/src/lib/deps/

	cp -f $MYCODEROOT/release/common/Makefile.top $wrkTarariroot/src
    pushd $MYCODEROOT/release/regex/6.5.1/Linux/current/SW/agents/regex_abraxas/regexcp/libraries/src
        install -m 644 *.[h] $wrkTarariroot/include

        rm -f $wrkTarariroot/src/lib/rgx_pcre*
        rm -f $wrkTarariroot/src/lib/rgx_swit.h
    popd
}

#create_dist_docs_001 componentName distName destDirForCreatedDist wrkTarariroot toolChain timeStamp hashTag
function create_dist_docs_001
{
	local componentName=$1
    local distName=$2
    local destDirForCreatedDist=$3
    local wrkTarariroot=$4
	local toolChain=$5
	local timeStamp=$6
	local hashTag=$7
	
	local fileName=""

    mkdir -p "$wrkTarariroot"
    mkdir -p "$wrkTarariroot/docs"

    SAVEDTARARIROOT=$TARARIROOT
	export TARARIROOT=$wrkTarariroot

	cp -f $MYCODEROOT/assetsTobeIntegratedIntoSrcTree/common/README.flex $TARARIROOT/docs/

	cp -f $MYCODEROOT/release/regex/6.5.1/Linux/current/SW/Documentation/README.rextest2	$TARARIROOT/docs/
	cp -f $MYCODEROOT/release/regex/6.5.1/Linux/current/SW/Documentation/README.treat       $TARARIROOT/docs/
	cp -f $MYCODEROOT/release/regex/6.5.1/Linux/current/SW/Documentation/README.trextest 	$TARARIROOT/docs

	# README.regexcp same as 45-lr
	cp -f $MYCODEROOT/release/regex/6.5.1/Linux/current/SW/Documentation/README.regexcp.nonslm $TARARIROOT/docs/README.regexcp

	cp -f $MYCODEROOT/release/regex/6.5.1/Linux/current/SW/Documentation/README.GA 	$TARARIROOT/docs/README

	# build the api user guide
	pushd $MYCODEROOT/release/regex/6.5.1/Linux/current/SW/agents/regex_abraxas/docs/
	make clean
	make
	make install
	make clean
	popd

	# remove unwanted doc files
	rm -f $TARARIROOT/docs/api_user_guides/regex_t10_api/html/tab_b.gif
	rm -f $TARARIROOT/docs/api_user_guides/regex_t10_api/html/tab_l.gif
	rm -f $TARARIROOT/docs/api_user_guides/regex_t10_api/html/tab_r.gif
	rm -f $TARARIROOT/docs/api_user_guides/regex_t10_api/html/tabs.css

    export TARARIROOT=$SAVEDTARARIROOT
    unset SAVEDTARARIROOT
	
	fileName="$componentName-info.txt"
	addCommonComponentInfo $wrkTarariroot $fileName $componentName $toolChain $hashTag $timeStamp "c"

    create_dist $distName $destDirForCreatedDist $wrkTarariroot 0
}

#create_dist_samples_001 componentName distName destDirForCreatedDist wrkTarariroot toolChain timeStamp hashTag
function create_dist_samples_001
{
	local componentName=$1
    local distName=$2
    local destDirForCreatedDist=$3
    local wrkTarariroot=$4
	local toolChain=$5
	local timeStamp=$6
	local hashTag=$7
	
	local fileName=""

    mkdir -p "$wrkTarariroot"
    mkdir -p "$wrkTarariroot/src/samples"

    SAVEDTARARIROOT=$TARARIROOT
    export TARARIROOT=$wrkTarariroot

	install -m 644 $MYCODEROOT/release/common/Makefile.top $TARARIROOT/src/

    #following installs : simplergx simplescan simplexpiscan compilerulesetwithcallback resultoverflow incremental loadbyseg regexcp

    pushd $MYCODEROOT/release/regex/6.5.1/Linux/current/SW/agents/regex_abraxas/tools/rextest/common
    make -f Makefile.internal.to-build-from-coderoot install_src
    popd

	rm -rf  $TARARIROOT/src/samples/incremental
	rm -rf  $TARARIROOT/src/samples/loadbyseg
	rm -rf  $TARARIROOT/src/samples/regexcp

    # install multirgx
    mkdir -p $TARARIROOT/src/samples/multirgx
    install -m 644 $MYREGEXCPROOT/tools/multi-thread/multi_thread_rgx_maia.c $TARARIROOT/src/samples/multirgx/multi_thread_rgx.c
    install -m 644 $MYREGEXCPROOT/tools/multi-thread/Makefile $TARARIROOT/src/samples/multirgx
    install -m 644 $MYREGEXCPROOT/tools/multi-thread/rules.l $TARARIROOT/src/samples/multirgx
    install -m 644 $MYREGEXCPROOT/tools/multi-thread/input1024 $TARARIROOT/src/samples/multirgx

    # install sc_chain
    mkdir -p $TARARIROOT/src/samples/scchain
    install -m 644 $MYREGEXCPROOT/tools/samples/common/scchain/scchain.c $TARARIROOT/src/samples/scchain/scchain.c
    install -m 644 $MYREGEXCPROOT/tools/samples/common/scchain/Makefile $TARARIROOT/src/samples/scchain/Makefile
    install -m 644 $MYREGEXCPROOT/tools/samples/common/scchain/rule.l $TARARIROOT/src/samples/scchain/rule.l
    install -m 644 $MYREGEXCPROOT/tools/samples/common/scchain/input.txt $TARARIROOT/src/samples/scchain/input.txt

    # install compilerstats
    mkdir -p $TARARIROOT/src/samples/compilerstats
    install -m 644 $MYREGEXCPROOT/tools/samples/common/compilerstats/compilerstats.c $TARARIROOT/src/samples/compilerstats/compilerstats.c
    install -m 644 $MYREGEXCPROOT/tools/samples/common/compilerstats/Makefile $TARARIROOT/src/samples/compilerstats/Makefile
    install -m 644 $MYREGEXCPROOT/tools/samples/common/compilerstats/rules.l $TARARIROOT/src/samples/compilerstats/rules.l

    # do not install : SG multirgx_pcap expected_output.log Makefile samples.sh

    export TARARIROOT=$SAVEDTARARIROOT
    unset SAVEDTARARIROOT

	fileName="$componentName-info.txt"
	addCommonComponentInfo $wrkTarariroot $fileName $componentName $toolChain $hashTag $timeStamp "c"

    create_dist $distName $destDirForCreatedDist $wrkTarariroot 0
}

# addOtherAssetsToTgzDir dirNameToCreatePackageTgzFrom
function addOtherAssetsToTgzDir
{
	local dirNameToCreatePackageTgzFrom=$1

	addReadmeFileToTgzDir $dirNameToCreatePackageTgzFrom
	addInstallationScriptToTgzDir $dirNameToCreatePackageTgzFrom
}

# addReadmeFileToTgzDir dirNameToCreatePackageTgzFrom
function addReadmeFileToTgzDir
{
	local dirNameToCreatePackageTgzFrom=$1

	cp -f "$MYCODEROOT/release/regex/6.5.1/Linux/current/SW/Documentation/README.GA" "$dirNameToCreatePackageTgzFrom/README"
	chmod 0755 "$dirNameToCreatePackageTgzFrom/README"
}

# addInstallationScriptToTgzDir dirNameToCreatePackageTgzFrom
function addInstallationScriptToTgzDir
{
	local dirNameToCreatePackageTgzFrom=$1

	cp -f "$MYREGEXCPROOT/installer/linux/regexcp_install.sh.external" "$dirNameToCreatePackageTgzFrom/regexcp_install.sh"
	chmod 0755 "$dirNameToCreatePackageTgzFrom/regexcp_install.sh"
}

#create_version_specific_files_dist componentName distName destDirForCreatedDist wrkTarariroot toolChain timeStamp hashTag
function create_version_specific_files_dist
{
	local componentName=$1
    local distName=$2
    local destDirForCreatedDist=$3
    local wrkTarariroot=$4
	local toolChain=$5
	local timeStamp=$6
	local hashTag=$7

	local fileName=""
	
	mkdir -p "$wrkTarariroot"

	local versionFileName="$wrkTarariroot/version.txt"
	cat "$MYCODEROOT/release/regex/6.5.1/Linux/current/SW/agents/regex_abraxas/installer/linux/regexcp.config" > $versionFileName
	cat "$MYCODEROOT/release/cpp_base/6.3/current/installer/linux/cpp_core.config"	>> $versionFileName
	echo "" >> $versionFileName
	echo $CM_TARGET >> $versionFileName

	#addCommonComponentInfo destDirName fileName componentName toolChain hashTag timeStamp mode[a]
	addCommonComponentInfo $wrkTarariroot "buildinfo.txt" $componentName $toolChain $hashTag $timeStamp c

	create_dist $distName $destDirForCreatedDist $wrkTarariroot 0
}

#create_dist_TEMPLATE componentName distName destDirForCreatedDist wrkTarariroot toolChain timeStamp hashTag
function create_dist_TEMPLATE
{
	local distName=$1
	local destDirForCreatedDist=$2
	local wrkTarariroot=$3
	# common for all

	mkdir -p "$wrkTarariroot"

	# assemble files

	create_dist $distName $destDirForCreatedDist $wrkTarariroot 0
}

#stripDirectory wrkTarariroot
function stripDirectory
{
    local wrkTarariroot=$1
	local fileList=`find $wrkTarariroot -type f` ; echo fileList=$fileList
	local stripLabelsListFile=common-strip.csv

	for f in $fileList; do $MYCODEROOT/build-sys/c-filter/absorb-c-macro.sh $f $stripLabelsListFile; done

	stripLabelsListFile=cm500.csv

	for f in $fileList; do $MYCODEROOT/build-sys/c-filter/absorb-c-macro.sh $f $stripLabelsListFile; done
}


# createPackageForToolchain pkgTgzDestDir pkgTgzName hashTag timeStamp customLabel toolChain toolChainLabel distDestDir componentRootDir 
function createPackageForToolchain
{
	local pkgTgzDestDir=$1
	local pkgTgzName=$2
	local hashTag=$3
	local timeStamp=$4
	local customLabel=$5
	local toolChain=$6
	local toolChainLabel=$7
	local distDestDir=$8
	local componentRootDir=$9

	local distName=""
	local wrkTarariRoot=""

	if [ "$CM_TARGET" = "bin" ]; then
		#tested OK#
		componentName="csp_rgxlib_001_bin_all_linux_all"
		distName=$componentName"_"$toolChainLabel"_"$customLabel"_"$hashTag"_"$timeStamp".dist"
		wrkTarariRoot=$componentRootDir"/tarariroot-$componentName"
		mkdir -p $wrkTarariRoot
		#create_dist_rgxlib_001_binaries componentName distName destDirForCreatedDist wrkTarariroot toolChain timeStamp hashTag 
		create_dist_rgxlib_001_binaries $componentName $distName $distDestDir $wrkTarariRoot $toolChain $timeStamp $hashTag 

		#tested OK#
		componentName="csp_driver_001_bin_all"
		distName=$componentName"_"$toolChainLabel"_"$customLabel"_"$hashTag"_"$timeStamp".dist"
		wrkTarariRoot=$componentRootDir"/tarariroot-$componentName"
		mkdir -p $wrkTarariRoot
		create_dist_driver_001_binaries $componentName $distName $distDestDir $wrkTarariRoot $toolChain $timeStamp $hashTag 
	else
		#tested OK#
		componentName="csp_rgxlib_001_src_ga_all_all_linux_all_all_001"
		distName=$componentName"_"$toolChainLabel"_"$customLabel"_"$hashTag"_"$timeStamp".dist"
		wrkTarariRoot=$componentRootDir"/tarariroot-$componentName"
		mkdir -p $wrkTarariRoot
		create_dist_rgxlib_001_src $componentName $distName $distDestDir $wrkTarariRoot $toolChain $timeStamp $hashTag 

		#tested OK#
		componentName="csp_driver_001_src_ga_all_all_linux_all_all_001"
		distName=$componentName"_"$toolChainLabel"_"$customLabel"_"$hashTag"_"$timeStamp".dist"
		wrkTarariRoot=$componentRootDir"/tarariroot-$componentName"
		mkdir -p $wrkTarariRoot
		create_dist_driver_001_src $componentName $distName $distDestDir $wrkTarariRoot $toolChain $timeStamp $hashTag 
	fi

	#tested OK#
	componentName="csp_rgxlib_002_bin_ga_all_linux_all"
	distName=$componentName"_"$toolChainLabel"_"$customLabel"_"$hashTag"_"$timeStamp".dist"
	wrkTarariRoot=$componentRootDir"/tarariroot-$componentName"
	mkdir -p $wrkTarariRoot
	create_dist_rgxlib_002_binaries $componentName $distName $distDestDir $wrkTarariRoot $toolChain $timeStamp $hashTag

	#tested OK#
	componentName="csp_rgx_cpp_tools_ga_all_linux_all"
	distName=$componentName"_"$toolChainLabel"_"$customLabel"_"$hashTag"_"$timeStamp".dist"
	wrkTarariRoot=$componentRootDir"/tarariroot-$componentName"
	mkdir -p $wrkTarariRoot
	create_dist_tools_001_binaries $componentName $distName $distDestDir $wrkTarariRoot $toolChain $timeStamp $hashTag

	#tested OK#
	componentName="csp_cppulib_bin_ga_all_linux_all"
	distName=$componentName"_"$toolChainLabel"_"$customLabel"_"$hashTag"_"$timeStamp".dist"
	wrkTarariRoot=$componentRootDir"/tarariroot-$componentName"
	mkdir -p $wrkTarariRoot
	create_dist_cppulib_001_binaries $componentName $distName $distDestDir $wrkTarariRoot $toolChain $timeStamp $hashTag 

	#tested OK#
	componentName="csp_firmware_001_comb_all_all_all_linux_all_all_001"
	distName=$componentName"_"$toolChainLabel"_"$customLabel"_"$hashTag"_"$timeStamp".dist"
	wrkTarariRoot=$componentRootDir"/tarariroot-$componentName"
	mkdir -p $wrkTarariRoot
	create_dist_firmware_001 $componentName $distName $distDestDir $wrkTarariRoot $toolChain $timeStamp $hashTag 

	#tested OK#
	componentName="csp_rgxlib_003_bin_ga_all_linux_all"
	distName=$componentName"_"$toolChainLabel"_"$customLabel"_"$hashTag"_"$timeStamp".dist"
	wrkTarariRoot=$componentRootDir"/tarariroot-$componentName"
	mkdir -p $wrkTarariRoot
	create_dist_extlib_001_binaries $componentName $distName $distDestDir $wrkTarariRoot $toolChain $timeStamp $hashTag 

	#tested OK#
	componentName="csp_auxDocs_001_docs_ga_all_all_linux_all_all_001"
	distName=$componentName"_"$toolChainLabel"_"$customLabel"_"$hashTag"_"$timeStamp".dist"
	wrkTarariRoot=$componentRootDir"/tarariroot-$componentName"
	mkdir -p $wrkTarariRoot
	create_dist_docs_001 $componentName $distName $distDestDir $wrkTarariRoot $toolChain $timeStamp $hashTag 

	#tested OK#
	componentName="csp_auxsamplePack_001_src_all_all_all_linux_all_all"
	distName=$componentName"_"$customLabel"_"$hashTag"_"$timeStamp".dist"
	wrkTarariRoot=$componentRootDir"/tarariroot-$componentName"
	mkdir -p $wrkTarariRoot
	create_dist_samples_001 $componentName $distName $distDestDir $wrkTarariRoot $toolChain $timeStamp $hashTag 

	#tested OK#
	componentName="csp_cspaux_version_files-001"
	distName=$componentName"_"$customLabel"_"$hashTag"_"$timeStamp".dist"
	wrkTarariRoot=$componentRootDir"/tarariroot-restr_version_files_001"
	mkdir -p $wrkTarariRoot
	create_version_specific_files_dist $componentName $distName $distDestDir $wrkTarariRoot $toolChain $timeStamp $hashTag 

	#tested OK#
	addOtherAssetsToTgzDir "$distDestDir"
	#tested OK#
	create_package_tgz $pkgTgzName $pkgTgzDestDir "$distDestDir"

}


function main
{
	local toolchains_file=$1

	if [ ! -e $toolchains_file ]; then
		echo "Failure: unable to locate toolchain file $toolchains_file"
		exit 1
	fi

	echo
	echo -n "Starting at:"
	date '+%Y%m%d%H%M%S'
	echo
	echo
	echo checkRequriedSettings...
	checkRequriedSettings

	echo Setting up Environment variables...
	setupVariables

	local timeStamp=`date '+%Y%m%d%H%M%S'`
	echo timeStamp:$timeStamp

	pushd $MYCODEROOT
		local hashTag=`git log --format="%h" -n 1`
	popd
	echo hashTag:$hashTag

	local toolChains=`cat $toolchains_file | grep -v "^#"`
	local toolChain=""
	local toolChainLabel=""
	local targetPackageRootDir=$WRKROOT/tgzRoot
	local distRootDir=$WRKROOT/DistRoot
	local wrkRootDir=$WRKROOT/TarariRoot
	local distDir=""
	local wrkDir=""
	local pkgName=""
	local tgzCommonLabel=""
	
	local customLabel="001"
	
	export TOOLROOT="$MYCODEROOT/release/toolchain/chains/"

	mkdir -p $targetPackageRootDir
	mkdir -p $PACKAGEDESTDIR

	for toolChain in $toolChains
	do
		toolChainLabel=`echo $toolChain | cut -d\- -f3,4,5,6`
		tgzCommonLabel="csp_regex_6.5.1.52_ga_all_$toolChainLabel.r"
		distDir=$distRootDir/$tgzCommonLabel
		wrkDir=$wrkRootDir/tc-$toolChain"_"
		pkgName="$tgzCommonLabel-$hashTag-$timeStamp.tgz"

		rm -rf $wrkRootDir
		rm -rf $distRootDir
		mkdir -p $wrkDir
		mkdir -p $distDir

		source $TOOLROOT/$toolChain/toolchain_setup.sh
		# createPackageForToolchain pkgTgzDestDir pkgTgzName hashTag timeStamp customLabel toolChain toolChainLabel distDestDir componentRootDir 
		createPackageForToolchain $PACKAGEDESTDIR $pkgName $hashTag $timeStamp $customLabel $toolChain $toolChainLabel $distDir $wrkDir 
		toolchain-reset-env
	done
}

main $1
