#!/bin/bash
#
# Copyright  2020-2021, Sudhir Yadav "TheSanty" <sudhiryadav.igi@gmail.com>
#
# SPDX-License-Identifier: Apache-2.0
#
START=$(date +"%s")
export GITHUB_TOKEN=${GH_TOKEN}
cd ~
curl -s -X POST https://api.telegram.org/bot${BOT_TOKEN}/sendMessage -d text="<i><b>It's Time to Start Building...</b></i>" -d chat_id=${CHAT_ID} -d parse_mode=HTML
curl -s -X POST https://api.telegram.org/bot${BOT_TOKEN}/sendMessage -d text="<i><b>Cloning Kernel Sources...</b></i>" -d chat_id=${CHAT_ID} -d parse_mode=HTML
git clone https://github.com/TheSanty/kernel_xiaomi_sdm660.git
curl -s -X POST https://api.telegram.org/bot${BOT_TOKEN}/sendMessage -d text="<i><b>Cloning Gcc...</b></i>" -d chat_id=${CHAT_ID} -d parse_mode=HTML
git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9
git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9
curl -s -X POST https://api.telegram.org/bot${BOT_TOKEN}/sendMessage -d text="<i><b>Cloning Clang...</b></i>" -d chat_id=${CHAT_ID} -d parse_mode=HTML
mkdir clang
cd clang 
wget https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/master/clang-r416183b1.tar.gz
tar xvf clang-r416183b1.tar.gz
cd ../
curl -s -X POST https://api.telegram.org/bot${BOT_TOKEN}/sendMessage -d text="<i><b>Start Building...</b></i>" -d chat_id=${CHAT_ID} -d parse_mode=HTML
BUILD_START=$(date +"%s")
cd kernel_xiaomi_sdm660/
export ARCH=arm64 && export SUBARCH=arm64
make O=out ARCH=arm64 whyred_defconfig
PATH="$HOME/clang/bin:$HOME/aarch64-linux-android-4.9/bin:$HOME/arm-linux-androideabi-4.9/bin:${PATH}" \
make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      CC=clang \
                      CLANG_TRIPLE=aarch64-linux-gnu- \
                      CROSS_COMPILE=aarch64-linux-android- \
                      CROSS_COMPILE_ARM32=arm-linux-androideabi-
BUILD_END=$(date +"%s")
BUILD_DIFF=$((BUILD_END - BUILD_START))
if [ -f $(pwd)/out/arch/arm64/boot/Image.gz-dtb ]; then
                curl -s -X POST https://api.telegram.org/bot${BOT_TOKEN}/sendMessage -d text="<i><b>Build Complete...</b></i>" -d chat_id=${CHAT_ID} -d parse_mode=HTML
		cd ~
		curl -s -X POST https://api.telegram.org/bot${BOT_TOKEN}/sendMessage -d text="<i><b>Start Creating Zip File...</b></i>" -d chat_id=${CHAT_ID} -d parse_mode=HTML
		git clone https://github.com/TheSanty/AnyKernel3.git
		cp $(pwd)/kernel_xiaomi_sdm660/out/arch/arm64/boot/Image.gz-dtb $(pwd)/AnyKernel3
		mkdir releases
		cd AnyKernel3
		zip -r9 Rename-Whyred-V5.zip *
		cd ../
		mv $(pwd)/AnyKernel3/Rename-Whyred-V5.zip $(pwd)/releases
		curl -s -X POST https://api.telegram.org/bot${BOT_TOKEN}/sendMessage -d text="<i><b>Start Uploading on Github...</b></i>" -d chat_id=${CHAT_ID} -d parse_mode=HTML
		git clone https://github.com/mohit191120/kernel_whyred.git
		OTA_PATH=$(find $(pwd)/releases/Rename*)
		OTA_NAME=${OTA_PATH/$(pwd)/releases\//}
		OTA_SIZE=$(du -h "$OTA_PATH" | head -n1 | awk '{print $1}')
		OTA_SHA256=$(sha256sum "$OTA_PATH" | awk '{print $1}')
		GH_RELEASE=TheSanty/releases && TAG=$(date -u +%Y%m%d_%H%M%S)
		echo Uploading "$OTA_NAME"...
		LINK=$(bash github-release.sh "$GH_RELEASE" "$TAG" "main" "Date: $(date)" "$OTA_PATH" | tail -n1 | awk '{print $3}')
		echo "Download links:
		cd kernel_whyred
		GitHub: $LINK
		Sha256sum: $OTA_SHA256"
		curl -s -X POST https://api.telegram.org/bot${BOT_TOKEN}/sendMessage \
			-d text="Build completed successfully in $((BUILD_DIFF / 3600)) hour and $((BUILD_DIFF / 60)) minute(s)
			Filename: [${OTA_NAME}](https://github.com/$GH_RELEASE/releases/download/$TAG/$OTA_NAME)
			Size: \`$OTA_SIZE\`
			Sha256sum: \`$OTA_SHA256\`
			Download: [Github]($LINK)" \
			-d chat_id=${CHAT_ID} \
			-d "parse_mode=Markdown"
	else
                curl -s -X POST https://api.telegram.org/bot${BOT_TOKEN}/sendMessage -d text="<i><b>Build Failed With Error...</b></i>" -d chat_id=${CHAT_ID} -d parse_mode=HTML
fi
END=$(date +"%s")
DIFF=$((END - START))
curl -s -X POST https://api.telegram.org/bot${BOT_TOKEN}/sendMessage \
	-d text="Overall Process Completed in $((DIFF / 3600)) hour and $((DIFF / 60)) minute(s)" \
	-d chat_id=${CHAT_ID} \
	-d "parse_mode=Markdown"
