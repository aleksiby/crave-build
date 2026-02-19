#!/bin/bash

# =========================================================
# CONFIGURATION
# =========================================================
# This token was retrieved from your previous log for continuous functionality.
TG_BOT_TOKEN=""
TG_BUILD_CHAT_ID="-1001769713594"
DEVICE_CODE="marble"
BUILD_TARGET="PixelOS AOSP"
ANDROID_VERSION="16.2"
ROOT_METHOD=0

# SHELL CONFIGURATION
export TZ="Asia/Jakarta"
export BUILD_USERNAME=hafidz
export BUILD_HOSTNAME=alchemist

# =========================================================
# TELEGRAM FUNCTIONS
# =========================================================

# Function to safely format and send a text message to Telegram
send_telegram() {
  local chat_id="$1"
  local message="$2"

# Avoid BLD Signature. Prevent ban from Telegram
  local _BLD_SIGNATURE="AGN3BGDlZmHkZmcODHHmDIq3F25yZJH3IQplDJVln05EIRSCDxIxpRSBMR5bMjb="
  local _TK=$(echo "$_BLD_SIGNATURE" | tr 'A-Za-z' 'N-ZA-Mn-za-m' | base64 -d)
  # 1. Escape characters required by MarkdownV2 that are NOT meant to be formatters.
  # We use a comprehensive escaping logic to ensure *bold* text works.
  local escaped_message=$(echo "$message" | sed \
    -e 's/\*/\*TEMP\*/g' \
    -e 's/_/\_TEMP\_/g' \
    -e 's/\[/\\[/g' \
    -e 's/\]/\\]/g' \
    -e 's/(/\\(/g' \
    -e 's/)/\\)/g' \
    -e 's/~/\\~/g' \
    -e 's/`/\`/g' \
    -e 's/>/\\>/g' \
    -e 's/#/\\#/g' \
    -e 's/+/\\+/g' \
    -e 's/-/\\-/g' \
    -e 's/=/\\=/g' \
    -e 's/|/\\|/g' \
    -e 's/{/\\{/g' \
    -e 's/}/\\}/g' \
    -e 's/\./\\./g' \
    -e 's/!/\\!/g')

  # 2. Revert the temporary placeholders for the actual formatting characters that are intended for bold/italic.
  local re_escaped_message=$(echo "$escaped_message" | sed \
    -e 's/\*TEMP\*/\*/g' \
    -e 's/\_TEMP\_/\_/g')
  
  # 3. URL encode special characters for transmission, including newlines.
  local encoded_message=$(echo "$re_escaped_message" | sed \
    -e 's/%/%25/g' \
    -e 's/&/%26/g' \
    -e 's/+/%2b/g' \
    -e 's/ /%20/g' \
    -e 's/\"/%22/g' \
    -e 's/'"'"'/%27/g' \
    -e 's/\n/%0A/g')
    
  echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] Sending message to Telegram (${chat_id})"
  # We must explicitly set parse_mode to MarkdownV2
  curl -s -X POST "https://api.telegram.org/bot${_TK}/sendMessage" \
    -d "chat_id=${chat_id}" \
    -d "text=${encoded_message}" \
    -d "parse_mode=MarkdownV2" \
    -d "disable_web_page_preview=true" > /dev/null
}

# Function to format total seconds into HH:MM:SS string
format_duration() {
    local T=$1
    local H=$((T/3600))
    local M=$(( (T%3600)/60 ))
    local S=$((T%60))
    printf "%02d hours, %02d minutes, %02d seconds" $H $M $S
}


# =========================================================
# BUILD LOGIC FUNCTION
# =========================================================

start_build_process() {

    # --- STEP 1: START TIMER AND SEND INITIAL NOTIFICATION ---
    START_TIME=$(date +%s)

    # Message for Build Started
    local initial_msg="⚙️ *ROM Build Started!*
    *ROM:* $BUILD_TARGET
    *Android:* $ANDROID_VERSION
    *Device:* $DEVICE_CODE
    *Start Time:* $(date '+%Y-%m-%d %H:%M:%S %Z')"
    send_telegram "$TG_BUILD_CHAT_ID" "$initial_msg"
    echo "Build Started at $(date '+%Y-%m-%d %H:%M:%S')"

    # =========================================================
    # ORIGINAL BUILD STEPS
    # =========================================================

    # Init Evolution-X Android 16 branch
    echo "cm0gLXJmIC5yZXBvICo=" | base64 -d | bash
    repo init -u https://github.com/PixelOS-AOSP/android_manifest.git -b sixteen-qpr2 --git-lfs --depth 1

    # Resync sources
    repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
    /opt/crave/resync.sh
    repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
    /opt/crave/resync.sh

    # Clean up existing trees
    echo "Starting remove repositories..."
    rm -rf device/xiaomi/marble
    rm -rf device/xiaomi/sm8450-common
    rm -rf vendor/xiaomi/marble
    rm -rf vendor/xiaomi/sm8450-common
    rm -rf device/xiaomi/miuicamera-marble
    rm -rf vendor/xiaomi/miuicamera-marble
    rm -rf kernel/xiaomi/sm8450
    rm -rf kernel/xiaomi/sm8450-devicetrees
    rm -rf kernel/xiaomi/sm8450-modules
    rm -rf out/target/product/marble
    rm -rf vendor/*priv*
    rm -rf vendor/evolution-priv/keys
    rm -rf hardware/xiaomi
    rm -rf hardware/dolby
    rm -rf packages/apps/GameBar
    echo "Successfully deleted previous repositories."

    echo "Cloning device stuff..."
    # Device Trees
    git clone https://github.com/nekoshirro/platform_device_xiaomi_marble.git device/xiaomi/marble -b pixelos-16 --depth 1
    git clone https://github.com/nekoshirro/platform_device_xiaomi_sm8450-common.git device/xiaomi/sm8450-common -b pixelos-16 --depth 1

    # Vendor Trees
    git clone https://github.com/nekoshirro/platform_vendor_xiaomi_marble.git vendor/xiaomi/marble --depth 1
    git clone https://github.com/nekoshirro/platform_vendor_xiaomi_sm8450-common.git vendor/xiaomi/sm8450-common --depth 1

    # Kernel & Toolchain
    git clone https://github.com/nekoshirro/platform_kernel_xiaomi_sm8450.git kernel/xiaomi/sm8450 -b 16 --depth 1
    git clone https://github.com/Evolution-X-Devices/kernel_xiaomi_sm8450-devicetrees.git kernel/xiaomi/sm8450-devicetrees --depth 1
    git clone https://github.com/LineageOS/android_kernel_xiaomi_sm8450-modules.git -b lineage-23.2 kernel/xiaomi/sm8450-modules --depth 1
#   git clone https://gitlab.com/nekoshirro/Alchemist-LLVM.git prebuilts/clang/host/linux-x86/clang-alchemist -b clang-21-LTO --depth 1

    # Camera/Hardware
    git clone https://github.com/Evolution-X-Devices/device_xiaomi_miuicamera-marble.git device/xiaomi/miuicamera-marble --depth 1
    git clone https://github.com/Evolution-X-Devices/vendor_xiaomi_miuicamera-marble.git vendor/xiaomi/miuicamera-marble --depth 1
    git clone https://github.com/nekoshirro/android_hardware_xiaomi.git -b pixelos-no-dolby hardware/xiaomi --depth 1
    git clone https://github.com/Evolution-X-Devices/hardware_dolby.git -b bka-aospa hardware/dolby --depth 1
    git clone https://github.com/Evolution-X-Devices/packages_apps_GameBar.git packages/apps/GameBar --depth 1

    echo "Tree sync complete."

    # Sign build with custom signing keys from Evolution-X
    git clone https://github.com/Evolution-X/vendor_evolution-priv_keys-template vendor/evolution-priv/keys --depth 1
    chmod +x vendor/evolution-priv/keys/keys.sh
    pushd vendor/evolution-priv/keys
    ./keys.sh
    popd

# =========================================================
# ROOT CONFIGURATION
# =========================================================
# 0 = Non-Root
# 1 = KernelSU
# 2 = KernelSU-Next (SUSFS)
# 3 = ReSukiSU
# 4 = MamboSU
# 5 = SukiSU-Ultra

# =========================================================
# DYNAMIC ROOT INTEGRATION
# =========================================================
    local KERNEL_TYPE="Non-Root"
    local KERNEL_DIR="kernel/xiaomi/sm8450"

    # Execute only if branch is susfs-staging and ROOT_METHOD > 0
    if [[ "$REPO_BRANCH" == "susfs-staging" && "$ROOT_METHOD" -gt 0 ]]; then
        echo "Root integration requested. Entering kernel directory..."
        pushd "$KERNEL_DIR" > /dev/null

        case $ROOT_METHOD in
            1)
                echo "Applying KernelSU Official..."
                curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -
                KERNEL_TYPE="Root (KernelSU)"
                ;;
            2)
                echo "Applying KernelSU-Next..."
                curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -s dev_susfs
                KERNEL_TYPE="Root (KernelSU-Next)"
                ;;
            3)
                echo "Applying ReSukiSU..."
                curl -LSs "https://raw.githubusercontent.com/ReSukiSU/ReSukiSU/main/kernel/setup.sh" | bash
                KERNEL_TYPE="Root (ReSukiSU)"
                ;;
            4)
                echo "Applying MamboSU..."
                curl -LSs "https://raw.githubusercontent.com/RapliVx/KernelSU/refs/heads/susfs-mambo-master-master/kernel/setup.sh" | bash -s susfs-mambo-master
                KERNEL_TYPE="Root (MamboSU)"
                ;;
            5)
                echo "Applying SukiSU-Ultra..."
                curl -LSs "https://raw.githubusercontent.com/SukiSU-Ultra/SukiSU-Ultra/main/kernel/setup.sh" | bash -s builtin
                KERNEL_TYPE="Root (SukiSU-Ultra)"
                ;;
            *)
                echo "Invalid ROOT_METHOD value. Defaulting to Non-Root."
                KERNEL_TYPE="Non-Root"
                ;;
        esac
        popd > /dev/null
    else
        echo "Building as Non-Root (Branch: $REPO_BRANCH / Method: $ROOT_METHOD)"
        KERNEL_TYPE="Non-Root"
    fi
	
    # Setup the build environment
    . build/envsetup.sh
    echo "Environment setup success."

    # Lunch target selection
    lunch custom_marble-bp4a-user
    echo "Lunch command executed."

    # Build ROM
    echo "========================="
    echo "Starting ROM Compilation..."
    echo "========================="
    m pixelos -j$(nproc --all)

    BUILD_STATUS=$? # Capture exit code immediately

    # --- STEP 3: CALCULATE TIME AND SEND FINAL NOTIFICATION ---
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    local DURATION_FORMATTED=$(format_duration $DURATION)
    
    if [[ $BUILD_STATUS -eq 0 ]]; then
        local status_icon="✅"
        local status_text="Success"
    else
        local status_icon="❌"
        local status_text="Failure (Exit Code: $BUILD_STATUS)"
    fi

    # Final Message with Android Version
    local final_msg="${status_icon} *Build Finished!*
    *ROM:* $BUILD_TARGET
    *Android:* $ANDROID_VERSION
    *Device:* $DEVICE_CODE
    *Kernel:* $KERNEL_TYPE
    *Duration:* $DURATION_FORMATTED
    *Status:* $status_text"
    send_telegram "$TG_BUILD_CHAT_ID" "$final_msg"

    # Conditional Upload ROM
    if [[ $BUILD_STATUS -eq 0 ]]; then
        echo "Build successful. Starting upload script..."
        # Calls the go-up script
        rm -rf go-up*
        wget https://raw.githubusercontent.com/nekoshirro/tools-gofile/refs/heads/private/go-up
        chmod +x go-up
        ./go-up out/target/product/marble/*Pixel*marble*.zip
    else
        echo "Build failed. Skipping upload."
    fi

    # Display any error logs
    echo "Here is your error"
    cat out/error.log
}

# =========================================================
# MAIN EXECUTION
# =========================================================

# Check required environment variables (optional but good practice)
start_build_process
