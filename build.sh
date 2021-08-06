#!/bin/bash
#
# Copyright  2020-2021, Sudhir Yadav "TheSanty" <sudhiryadav.igi@gmail.com>
#
# SPDX-License-Identifier: Apache-2.0
#
export GITHUB_TOKEN=${{ secrets.GH_TOKEN }}
if [ -f $(pwd)/github*.sh ]; then
                curl -s -X POST https://api.telegram.org/bot${{ secrets.BOT_TOKEN }}/sendMessage -d text="<i><b>Build Complete...</b></i>" -d chat_id=${{ secrets.CHAT_ID }} -d parse_mode=HTML
        else
                curl -s -X POST https://api.telegram.org/bot${{ secrets.BOT_TOKEN }}/sendMessage -d text="<i><b>Build Failed With Error...</b></i>" -d chat_id=${{ secrets.CHAT_ID }} -d parse_mode=HTML
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
curl -s -X POST https://api.telegram.org/bot${{ secrets.BOT_TOKEN }}/sendMessage \
        -d text="Filename: [${OTA_NAME}](https://github.com/$GH_RELEASE/releases/download/$TAG/$OTA_NAME)
        Size: \`$OTA_SIZE\`
        Sha256sum: \`$OTA_SHA256\`
        Download: [Github]($LINK)" \
        -d chat_id=${{ secrets.CHAT_ID }} \
        -d "parse_mode=Markdown"
