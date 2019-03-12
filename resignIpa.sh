#!/bin/sh

#  resignIpa.sh
#
#  version 1.0.1
#
#  Created by xeonwell on 12/01/2017.
#
#  功能：
#       自动重新签名所有符合条件的包，输出到配置的目录中
#       建议操作前，先更新证书，保证证书及密钥本机正常安装, 将mobileprovision放置到本脚本目录
#
#  参考:
#       http://blog.csdn.net/xiaobai20131118/article/details/46713163
#
#  注意：如果不能执行， 请修改后缀为.command或者在命令行执行如下命令：
#
#       chmod +x resignIpa.sh
#


################################################################################
#
# 编译成功前提条件
#
# 1. 必须安装有xcode（需要使用到command line tools）
# 2. 必须安装有证书（在有证书的电脑上使用xcode导出，然后在需要安装的电脑上双击导入）
#
################################################################################

################################################################################
#
#                       ***********参数配置开始***********
#
#   注意
#       1. 目录不要包含空格
#       2. =号前后不能包含空格
#
#-------------------------------------------------------------------------------

# resource dir
# resDir="~/Library/Developer/Xcode/Archives"
resDir="~/Desktop/Archives"
# output dir
outputDir="~/Desktop/Output"

identifiers=(com.xxx.entdistribute.aaa com.xxx.entdistribute.bbb)

resignCer="iPhone Distribution: xxxx Co., LTD."
resignPrivisioning="embedded.mobileprovision"
resignIdentifier="com.xxx.entdistribute.xxx"
password="123456"
#-------------------------------------------------------------------------------
#
#                       ***********参数配置结束***********
#
################################################################################


################################################################################
#
#

dCount=0
function displayInfo(){
    dCount=$((${dCount} + 1))
    echo " ${dCount}.\t$1"
}
function errorInfo(){
    displayInfo "\033[31m $1\033[0m"
    exit 1
}

xcArchive=".xcarchive"
appDir="Products/Applications"
infoPlist="Info.plist"

#######################################
#
# 变量初始化
#
#######################################
curPath=`pwd`
resDir=`eval echo ${resDir}`
outputDir=`eval echo ${outputDir}`


mkdir -p ${outputDir}


# createEntitlement
displayInfo "创建重签环境plist"
security unlock-keychain -p "${password}" ~/Library/Keychains/login.keychain
/usr/libexec/PlistBuddy -x -c "print :Entitlements " /dev/stdin <<< $(security cms -D -i ${resignPrivisioning}) > entitlements.plist
sncode=$(/usr/libexec/PlistBuddy -c "Print :com.apple.developer.team-identifier" entitlements.plist)
  

# 遍历资源目录，为日期格式的字符串
for ipaDir in `ls "${resDir}"`
do
    ipaDir="${resDir}/${ipaDir}"
    for archive in `ls "${ipaDir}" | tr " " "?"`
    do
        if [[ ${archive} == *${xcArchive} ]] && ([[ ${archive} == "PAD"* ]] || [[ ${archive} == "LBT"* ]]); then
            archive=${archive//'?'/' '}

            appPath="${ipaDir}/${archive}/${appDir}"

            for app in `ls "${appPath}"`
            do
                app="${appPath}/${app}"

                ipaIdentifier=`/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "${app}/${infoPlist}"`
                displayInfo "签名：${ipaIdentifier}"
                if [[ ${ipaIdentifier} == ${identifiers[0]} ]] || [[ ${ipaIdentifier} == ${identifiers[1]} ]]; then
                    ipaVersion=`/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${app}/${infoPlist}"`
                    ipaName=`/usr/libexec/PlistBuddy -c "Print CFBundleName" "${app}/${infoPlist}"`
                    outputName="${ipaName}_${ipaVersion}"

                    displayInfo "修改entitlements.plist的idntifier"
                    /usr/libexec/PlistBuddy -c "Set :application-identifier ${sncode}.${ipaIdentifier}" entitlements.plist


                    #重置BundleID
                    # /usr/libexec/PlistBuddy -c "set :CFBundleIdentifier ${resignIdentifier}" "${app}/${infoPlist}"

                    displayInfo "移除_CodeSignature文件夹"
                    rm -rf "${app}/_CodeSignature/"

                    displayInfo "用新的provisioning文件覆盖原有文件"
                    cp ${resignPrivisioning} "${app}/embedded.mobileprovision"
                    
                    # displayInfo "重签Frameworks和dylib"
                    # find  −name "∗.app" −o−name "∗.appex" −o−name "∗.framework" −o−name "∗.dylib" > directories.txt
                    # while IFS='' read -r line || [[ -n "$line" ]]; do
                    # /usr/bin/codesign --continue -f -s "${resignCer}" --no-strict "t_entitlements.plist"  "$line"
                    # done < directories.txt
                    
                    displayInfo "重签app"
                    codesign -f -s "${resignCer}" --entitlements entitlements.plist "${app}"
                    # codesign -f -s "iOS Distribution: xxx Co., LTD." "${app}"

                    # 2019-03-12
                    # 如果报下面的错误（xcode9+），则需要在对应目录增加可执行脚本，命名为PackageApplication
                    # xcrun: error: unable to find utility "PackageApplication", not a developer tool or in PATH
                    # cd /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin && sudo touch PackageApplication && vim PackageApplication
                    # add following codes
                    # https://gist.github.com/anonymous/48f3e4c5ae25313dc0fe10d9ec50c3fc
                    # and then: sudo chmod +x PackageApplication
                    
                    # xcrun  -sdk iphoneos PackageApplication -v "${app}" -o "${outputDir}/${outputName}.ipa" --sign "${resignCer}" --embed ${resignPrivisioning##*/} > /dev/null
                    xcrun -sdk iphoneos PackageApplication -v "${app}" -o "${outputDir}/${outputName}.ipa" --embed ${resignPrivisioning##*/} > /dev/null

                    if [[ "$?" == "0" ]]; then
                        displayInfo "打包成功, ${outputName}"
                    else
                        displayInfo "打包失败, ${outputName}"
                    fi

                else
                    displayInfo "${app}不能打包，签名不符合要求"
                fi
            done
        fi
    done
done
