# resignIpa
re-codesign outdated ios apps
企业版内发ipa，一年后会过期导致无法使用， 需要重新打包使用，本脚本批量将原有包重新签名

## features
- 自动重新签名所有符合条件的archive包，输出到配置的目录中
- 建议操作前，先更新证书，保证证书及密钥本机正常安装, 将mobileprovision放置到本脚本目录

## tips
- 如果不能执行， 请修改后缀为.command或者在命令行执行如下命令 `chmod +x resignIpa.sh`
- 将 `~/Library/Developer/Xcode/Archives` 的包复制一份出来测试，打包会替换其中的部分文件
- 重签Frameworks和dylib未经测试
- 如果报错"xcrun: error: unable to find utility "PackageApplication", not a developer tool or in PATH", 请参考代码里的方式处理
