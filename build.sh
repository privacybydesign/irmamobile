set -x

flutter clean
rm -rf build
rm -rf ios
git checkout -- ios

rm -rf .vendor-new vendor
dep ensure -v
gomobile bind -target ios -o ios/Runner/Irmagobridge.framework github.com/privacybydesign/irmamobile/irmagobridge

flutter build ios -t lib/main_gemeente.dart

cd ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -sdk iphoneos -configuration Release archive -archivePath $PWD/build/Runner.xcarchive

xcodebuild -exportArchive -archivePath $PWD/build/Runner.xcarchive -exportOptionsPlist AppStoreExportOptions.plist -exportPath $PWD/build/AppStore
xcodebuild -exportArchive -archivePath $PWD/build/Runner.xcarchive -exportOptionsPlist AdHocExportOptions.plist -exportPath $PWD/build/AdHoc
