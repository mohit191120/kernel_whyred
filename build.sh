#!/bin/bash
#
# Copyright  2020-2021, Sudhir Yadav "TheSanty" <sudhiryadav.igi@gmail.com>
#
# SPDX-License-Identifier: Apache-2.0
#
export GITHUB_TOKEN=${GH_TOKEN}
cd ~
git clone https://github.com/TheSanty/kernel_xiaomi_sdm660.git
git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9
git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9
mkdir clang
cd clang 
wget https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/master/clang-r416183b1.tar.gz
tar xvf clang-r416183b1.tar.gz
cd ../
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
cd ~
git clone https://github.com/TheSanty/AnyKernel3.git
cp $(pwd)/kernel_xiaomi_msm8953/out/arch/arm64/boot/Image.gz-dtb $(pwd)/AnyKernel3
mkdir releases
cd AnyKernel3
zip -r9 Rename-Whyred-V5.zip *
cd ../
mv $(pwd)/AnyKernel3/Rename-Whyred-V5.zip $(pwd)/releases
curl -F chat_id="-1001377058531" \
		 -F caption="$(sha1sum $(pwd)/releases/Rename-Whyred-V5.zip | awk '{ print $1 }')" \
                 -F document=@"$(pwd)/releases/Rename-Whyred-V5.zip" \
                  https://api.telegram.org/bot1834871407:AAGO4do-QGZxF46ibzPshG_pec5SniEk3T4/sendDocument
		    
if [ -f $(pwd)/github*.sh ]; then
                curl -s -X POST https://api.telegram.org/bot${BOT_TOKEN}/sendMessage -d text="<i><b>Build Complete...</b></i>" -d chat_id=${CHAT_ID} -d parse_mode=HTML
        else
                curl -s -X POST https://api.telegram.org/bot${BOT_TOKEN}/sendMessage -d text="<i><b>Build Failed With Error...</b></i>" -d chat_id=${CHAT_ID} -d parse_mode=HTML
fi
OTA_PATH=$(find $(pwd)/github*)
OTA_NAME=${OTA_PATH/$(pwd)\//}
OTA_SIZE=$(du -h "$OTA_PATH" | head -n1 | awk '{print $1}')
OTA_SHA256=$(sha256sum "$OTA_PATH" | awk '{print $1}')
GH_RELEASE=TheSanty/releases && TAG=$(date -u +%Y%m%d_%H%M%S)
echo Uploading "$OTA_NAME"...
LINK=$(bash github-release.sh "$GH_RELEASE" "$TAG" "main" "Date: $(date)" "$OTA_PATH" | tail -n1 | awk '{print $3}')
echo "Download links:
GitHub: $LINK
Sha256sum: $OTA_SHA256"
curl -s -X POST https://api.telegram.org/bot${BOT_TOKEN}/sendMessage \
        -d text="Filename: [${OTA_NAME}](https://github.com/$GH_RELEASE/releases/download/$TAG/$OTA_NAME)
        Size: \`$OTA_SIZE\`
        Sha256sum: \`$OTA_SHA256\`
        Download: [Github]($LINK)" \
        -d chat_id=${CHAT_ID} \
        -d "parse_mode=Markdown"
