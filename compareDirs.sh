# Simple shell script used for comparing files present in one directory with the other.
# Was used for testing purposes to check if the changes made to the software has caused
# changes in the existing files.

currDir=$PWD
echo currDir=$currDir

leftDir=$1
echo leftDir=$leftDir

rightDir=$2
echo rightDir=$rightDir

leftLstFileName=`basename $leftDir`.lst
rightLstFileName=`basename $rightDir`.lst
echo leftLstFileName=$leftLstFileName
echo rightLstFileName=$rightLstFileName

pushd $leftDir
	find -type f | sort > $currDir/$leftLstFileName
popd
pushd $rightDir
	find -type f | sort > $currDir/$rightLstFileName
popd

echo diff $leftLstFileName $rightLstFileName > $leftLstFileName-$rightLstFileName.diff
diff $leftLstFileName $rightLstFileName > $leftLstFileName-$rightLstFileName.diff



leftMd5FileName=`basename $leftDir`.md5
rightMd5FileName=`basename $rightDir`.md5
echo leftMd5FileName=$leftMd5FileName
echo rightMd5FileName=$rightMd5FileName

pushd $leftDir
	md5sum `find -type f | sort` > $currDir/$leftMd5FileName
popd
pushd $rightDir
	md5sum `find -type f | sort` > $currDir/$rightMd5FileName
popd

echo diff $leftMd5FileName $rightMd5FileName > $leftMd5FileName-$rightMd5FileName.diff
diff $leftMd5FileName $rightMd5FileName > $leftMd5FileName-$rightMd5FileName.diff


exit 

