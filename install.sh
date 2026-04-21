#!/bin/bash

echo -e "\e[1;36m==============================\e[0m"
echo -e "\e[1;32m  Welcome to termuxOS Installer \e[0m"
echo -e "\e[1;36m==============================\e[0m"

# Ask for details
read -p "Enter your desired Username: " input_user
read -p "Enter your desired Hostname (Device Name): " input_host

# 1. Create the configuration directory and file
mkdir -p ~/.termuxOS
cat <<ENV > ~/.termuxOS/config.env
CUSTOM_USER="${input_user}"
CUSTOM_HOST="${input_host}"
ARROW_CODE="38;2;140;247;123m"
DIR_CODE="38;2;142;250;253m"
CMD_CODE="0m"
SHOW_NEOFETCH="yes"
ENV

# 2. Create the configuration menu script (init)
cat <<'INIT' > ~/.termuxOS/init.sh
CONFIG="$HOME/.termuxOS/config.env"
source $CONFIG

clear
echo -e "\e[1;36m=== termuxOS Configuration ===\e[0m"
echo "1. Change Prompt Colors"
echo "2. Change Neofetch Username & Hostname"
echo "3. Toggle Neofetch on startup (Current: $SHOW_NEOFETCH)"
echo "4. Uninstall termuxOS & Restore Default Termux"
echo "5. Exit"
read -p "Choose an option: " opt

case $opt in
    1)
        echo "1) Default MT Style (Perfect Color Match)"
        echo "2) Hacker (Green Arrow, Green Folder, Green CMD)"
        echo "3) Cyberpunk (Magenta Arrow, Yellow Folder, Cyan CMD)"
        echo "4) Custom Color Codes"
        read -p "Select theme: " col
        
        if [ "$col" = "1" ]; then
            sed -i 's/ARROW_CODE=.*/ARROW_CODE="38;2;140;247;123m"/' $CONFIG
            sed -i 's/DIR_CODE=.*/DIR_CODE="38;2;142;250;253m"/' $CONFIG
            sed -i 's/CMD_CODE=.*/CMD_CODE="0m"/' $CONFIG
        elif [ "$col" = "2" ]; then
            sed -i 's/ARROW_CODE=.*/ARROW_CODE="1;32m"/' $CONFIG
            sed -i 's/DIR_CODE=.*/DIR_CODE="1;32m"/' $CONFIG
            sed -i 's/CMD_CODE=.*/CMD_CODE="1;32m"/' $CONFIG
        elif [ "$col" = "3" ]; then
            sed -i 's/ARROW_CODE=.*/ARROW_CODE="1;35m"/' $CONFIG
            sed -i 's/DIR_CODE=.*/DIR_CODE="1;33m"/' $CONFIG
            sed -i 's/CMD_CODE=.*/CMD_CODE="1;36m"/' $CONFIG
        elif [ "$col" = "4" ]; then
            echo -e "\nUse standard ANSI format (e.g., 1;32m for Green, 0m for Normal text)"
            read -p "1st - Enter Arrow color code: " custom_arrow
            read -p "2nd - Enter Directory color code: " custom_dir
            read -p "3rd - Enter Command text color code: " custom_cmd
            
            sed -i "s/ARROW_CODE=.*/ARROW_CODE=\"$custom_arrow\"/" $CONFIG
            sed -i "s/DIR_CODE=.*/DIR_CODE=\"$custom_dir\"/" $CONFIG
            sed -i "s/CMD_CODE=.*/CMD_CODE=\"$custom_cmd\"/" $CONFIG
        fi
        
        echo ""
        read -p "Apply changes now? (y/n): " apply
        if [[ "$apply" == "y" || "$apply" == "Y" ]]; then
            source ~/.bashrc
            echo "Colors applied!"
        fi
        ;;
    2)
        read -p "New Username: " nu
        read -p "New Hostname: " nh
        sed -i "s/CUSTOM_USER=.*/CUSTOM_USER=\"$nu\"/" $CONFIG
        sed -i "s/CUSTOM_HOST=.*/CUSTOM_HOST=\"$nh\"/" $CONFIG
        
        echo ""
        read -p "Apply changes now? (y/n): " apply
        if [[ "$apply" == "y" || "$apply" == "Y" ]]; then
            source ~/.bashrc
            echo "Names updated! Run 'neofetch' to see."
        fi
        ;;
    3)
        if [ "$SHOW_NEOFETCH" = "yes" ]; then
            sed -i 's/SHOW_NEOFETCH=.*/SHOW_NEOFETCH="no"/' $CONFIG
            echo "Neofetch disabled on startup."
        else
            sed -i 's/SHOW_NEOFETCH=.*/SHOW_NEOFETCH="yes"/' $CONFIG
            echo "Neofetch enabled on startup."
        fi
        ;;
    4)
        echo ""
        echo -e "\e[1;31mWARNING: This will completely remove termuxOS.\e[0m"
        read -p "Are you sure you want to uninstall? (y/n): " confirm
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            
            # 1. Remove the config folder
            rm -rf ~/.termuxOS
            
            # 2. Remove the custom su wrapper
            rm -f /data/data/com.termux/files/usr/bin/su
            
            # 3. ONLY remove our custom bashrc from root (leaves user's other root files perfectly intact)
            su -c "rm -f ~/.suroot/.bashrc" 2>/dev/null || rm -f ~/.suroot/.bashrc
            
            # 4. Remove pure black colors
            rm -f ~/.termux/color.properties
            termux-reload-settings 2>/dev/null
            
            # 5. Restore a clean bashrc
            cat <<'CLEANBASH' > ~/.bashrc
# Default Bashrc
CLEANBASH
            
            # 6. Unset active variables for the current session
            unset PROMPT_COMMAND
            unset PS0
            PS1="\$ "
            unalias init 2>/dev/null
            unalias neofetch 2>/dev/null
            
            echo -e "\e[1;32mUninstall complete. Termux is back to normal.\e[0m"
            echo "Please restart Termux to fully clear the environment."
            echo -e "\n\e[1;33m[IMPORTANT]\e[0m To restore the default Termux 'su' command, please run:"
            echo -e "  \e[1;36mpkg install --reinstall termux-tools\e[0m\n"
            
            return 2>/dev/null || exit
        else
            echo "Uninstall cancelled."
        fi
        ;;
    *)
        echo "Exiting..."
        ;;
esac
INIT
chmod +x ~/.termuxOS/init.sh

# 3. Generate the new .bashrc
cat <<'BASHRC' > ~/.bashrc
# Load termuxOS Configuration
source ~/.termuxOS/config.env

# termuxOS Prompt Style
prompt_style() {
    local EXIT_STATUS=$?
    
    local GREEN="\[\e[${ARROW_CODE}\]"
    local RED="\[\e[1;31m\]"
    local CYAN="\[\e[${DIR_CODE}\]"
    local CMD_COLOR="\[\e[${CMD_CODE}\]"
    local RESET="\[\e[0m\]"
    
    local PROMPT_CHAR="➜"
    local CHAR_COLOR=$GREEN
    
    if [ $(id -u) -eq 0 ]; then
        PROMPT_CHAR="#"
    fi
    
    if [ $EXIT_STATUS -ne 0 ]; then
        CHAR_COLOR=$RED
    fi
    
    PS1="${RESET}${CHAR_COLOR}${PROMPT_CHAR} ${CYAN}\W ${CMD_COLOR}"
}
PROMPT_COMMAND=prompt_style

# Instantly reset color back to normal the exact moment you hit Enter
PS0="\e[0m"

# Create 'init' command to launch config menu
alias init='source ~/.termuxOS/init.sh'

# Custom Neofetch Wrapper
alias neofetch='USER=$CUSTOM_USER HOSTNAME=$CUSTOM_HOST /data/data/com.termux/files/usr/bin/neofetch'

# Run Neofetch on startup if enabled (but skip if using 'su')
if [ "$SHOW_NEOFETCH" = "yes" ] && [ -z "$TERMUX_OS_BOOTED" ]; then
    clear
    neofetch
    export TERMUX_OS_BOOTED=1
fi
BASHRC

# 4. Create the root wrapper for KernelSU/Magisk
cat << 'SU_WRAPPER' > /data/data/com.termux/files/usr/bin/su
#!/data/data/com.termux/files/usr/bin/bash
exec /system/bin/su -p -s /data/data/com.termux/files/usr/bin/bash "$@"
SU_WRAPPER
chmod +x /data/data/com.termux/files/usr/bin/su

# 5. Sync to root environment safely
mkdir -p ~/.suroot
cp ~/.bashrc ~/.suroot/.bashrc

# 6. Apply Pure Black Theme
mkdir -p ~/.termux
echo "background=#000000" > ~/.termux/color.properties
echo "foreground=#ffffff" >> ~/.termux/color.properties
echo "cursor=#ffffff" >> ~/.termux/color.properties
termux-reload-settings 2>/dev/null

echo -e "\e[1;32mInstallation Complete!\e[0m"
echo "Please completely close Termux and open it again to see termuxOS in action."
