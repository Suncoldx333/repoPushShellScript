#!/bin/bash

#--------------------------
#
#	该脚本应放置在与 *.podspec 文件同一目录
#	文件夹名称应与要生成的私有库的名称一致
#	
#	比如建立一个叫  BLFamilyModule 的私有库，则文件路径如下所示
#	BLFamilyModule
#		|----BLFamilyModule（私有库代码所在位置）
#		|----BLFamilyModule.podspec 
#		|----Example (示例代码)
#		|----该脚本.sh
#	运行前先执行  chmod +x ./脚本.sh 获取脚本执行权限
#
#--------------------------

#-------------------------   
#
#	获取版本号及依赖库

echo -e "\n获取基础信息...\n"

basepath=$(cd `dirname $0`; pwd)
filename=`basename $basepath`
podfilePath="${basepath}/Example/Podfile"
podspecPath=${filename}".podspec"
specPaths=""
#初始版本号默认0.1.0
version="0.1.0"

search="`pod search "${filename}"`"
result=$search

if [[ "$result" != "" ]]; then

    result=${result#*\(}
    result=${result%%\)*}
    version=$result
fi


if [ -e $podspecPath ]; then

	specPaths=""
else

	echo "ERROR: ${podspecPath} 文件不存在"
	exit 1 
fi



if [ -e $podfilePath ]; then
	
	while read -r line; do

		if [[ "$line" =~ ^source.*git\'$ ]]; then
					
			path=${line#source* *\'}
			path=${path%\'}
			specPaths=${specPaths}${path}","
		fi		
	done < $podfilePath
else

	echo "ERROR: ${podfilePath} 文件不存在"
	exit 1
fi

specPaths=${specPaths%\,}

showspecs=${specPaths//\,/\\\n}
echo -e "当前的版本号：${version} \n依赖的源路径：\n${showspecs}\n"

#--------------------------


#------------------------
#
#	git 提交


echo -n "要上传的版本号：" 
read specifiVersion

if [[ "$specifiVersion" =~ [0-9]+\.[0-9]+\.[0-9]+ ]]; then
	
	if [[ "$specifiVersion" != "$version" ]]; then
	
		echo $specifiVersion
		echo $version

		#echo -e -n "与podspec文件内的版本号不一致，是否修改podspec文件内的版本号(\033[4myes\033[0m/no)：" 
		#echo "与podspec文件内的版本号不一致"
		#exit 1 

		#read shouldChange
		#shouldChange=${shouldChange:-"yes"}
		#if [[ "$shouldChange" == "yes" ]]; then
		
			#version=$specifiVersion
			#echo "修改"
			#修改文件
		#else

			#echo "当前提交的版本号：${version}"
		#fi
	fi
else

	echo "版本格式不正确"
	exit 1
fi

git add .
echo -n "提交的版本修改的内容："
read content
git commit -m "${content}"
git tag $specifiVersion
git push origin master --tags
#------------------------

#------------------------
#
#	检查并推送仓库

repoPath="/Users/"
if [[ -d /Users ]]; then

    for file in /Users/*; do

        filename=`basename $file`
        if [[ $basepath =~ $filename ]]; then

            repoPath=${repoPath}${filename}"/.cocoapods/repos"
            echo $repoPath
        fi
    done
fi

sepcSource=""
specs=""

if [[ -d $repoPath ]]; then

    for file1 in $repoPath/*; do

        filename1=`basename ${file1}`
        specs=${specs}"/"${filename1}

    done
else

	echo "请检查 ~/.cocoapods/repos 文件夹是否存在"
	exit 1
fi

specs=${specs#/}

echo -e -n "~/.cocoapods/repos文件夹内所有的specs("${specs}")，选择你的私有源"
read sepcSource

echo -e "开始提交到私有仓库...\n"
lintCommnad="pod spec lint "${podspecPath}" --allow-warnings --use-libraries"
pushCommand="pod repo push "${sepcSource}" --allow-warnings --use-libraries"

if [[ "$specPaths" == "" ]]; then
	
	${lintCommnad}
else

	lintCommnad=${lintCommnad}" --sources="${specPaths}
	${lintCommnad}
fi

if [[ "$specPaths" == "" ]]; then
	
	${pushCommand}
else

	pushCommand=${pushCommand}" --sources="${specPaths}
	${pushCommand}
fi
#------------------------

exit 0