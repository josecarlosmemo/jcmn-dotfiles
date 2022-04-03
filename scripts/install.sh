#!/usr/bin/env bash

clear
echo "  _____           _        _ _           "
echo " |_   _|         | |      | | |          "
echo "   | |  _ __  ___| |_ __ _| | | ___ _ __ "
echo "   | | | '_ \/ __| __/ _\` | | |/ _ \ '__|"
echo "  _| |_| | | \__ \ || (_| | | |  __/ |   "
echo " |_____|_| |_|___/\__\__,_|_|_|\___|_|   "
echo "                                         "
echo "                                         "
echo " "

# Usage: options=("one" "two" "three"); chooseOption "Choose:" 1 "${options[@]}"; choice=$?; echo "${options[$choice]}"

function chooseOption() {
    echo "$1"
    shift
    echo $(tput sitm)$(tput dim)-"Change selection: [up/down]  Select: [ENTER]" $(tput sgr0)
    local selected="$1"
    shift

    ESC=$(echo -e "\033")
    cursor_blink_on() { tput cnorm; }
    cursor_blink_off() { tput civis; }
    cursor_to() { tput cup $(($1 - 1)); }
    print_option() { echo $(tput dim) "   $1" $(tput sgr0); }
    print_selected() { echo $(tput bold) "=> $1" $(tput sgr0); }
    get_cursor_row() {
        IFS=';' read -sdR -p $'\E[6n' ROW COL
        echo ${ROW#*[}
    }
    key_input() {
        read -s -n3 key 2>/dev/null >&2
        [[ $key = $ESC[A ]] && echo up
        [[ $key = $ESC[B ]] && echo down
        [[ $key = "" ]] && echo enter
    }

    for opt; do echo; done

    local lastrow=$(get_cursor_row)
    local startrow=$(($lastrow - $#))
    trap "cursor_blink_on; echo; echo; exit" 2
    cursor_blink_off

    : selected:=0

    while true; do
        local idx=0
        for opt; do
            cursor_to $(($startrow + $idx))
            if [ $idx -eq $selected ]; then
                print_selected "$opt"
            else
                print_option "$opt"
            fi
            ((idx++))
        done

        case $(key_input) in
        enter) break ;;
        up)
            ((selected--))
            [ $selected -lt 0 ] && selected=$(($# - 1))
            ;;
        down)
            ((selected++))
            [ $selected -ge $# ] && selected=0
            ;;
        esac
    done

    cursor_to $lastrow
    cursor_blink_on
    echo

    return $selected
}

# Function for Progress Bars
function progressBar() {
    local BAR='████████████████████'
    local SPACE='                    '
    for i in {1..20}; do
        echo -ne "\r|${BAR:0:$i}${SPACE:$i:20}| $(($i * 5))% [ $2 ] "
        sleep $1
    done
    echo -ne '
'
}

echo " "
progressBar .1 "OS Detection..."
# Detecting OS
if [[ "$HOME" = *Users* ]]; then
    OS=macos
else
    OS=linux
fi

# # # # # #
# Mac OS #
# # # # #
if [ "$OS" = "macos" ]; then
    if [ ! -f "/usr/bin/xcrun" ]; then # If xcrun doesn't exist
        echo " "
        progressBar .1 "Installing Xcode Tools..."
        xcode-select --install
        echo " "
        options=("Continue")
        chooseOption "When the popup window finishes installing:" 1 "${options[@]}"
        choice=$?
        clear
    fi

    # Downloads dotfiles gitlab to tmp
    currentDIR=$(pwd)
    cd /tmp
    git clone https://gitlab.com/josecarlosmemo/dotfiles.git
    cd $currentDIR

    if [ ! -f "/usr/local/bin/brew" ]; then # If brew doesn't exist
        echo " "
        progressBar .1 "Installing brew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
        clear
    fi

    if [ ! -f "/bin/zsh" ]; then # If zsh doesn't exist
        echo " "
        progressBar .1 "Installing zsh..."
        brew install zsh
        clear
    fi

    if [ ! -f "/usr/local/bin/lf" ]; then # If lf doesn't exist
        echo " "
        progressBar .1 "Installing lf..."
        brew install lf
        clear
    fi

    if [ ! -f "/usr/local/bin/spt" ]; then # If spt doesn't exist
        echo " "
        progressBar .1 "Installing Spotify for Terminal..."
        brew install Rigellute/tap/spotify-tui
        clear
    fi

    if [ ! -f "/usr/local/bin/ffmpeg" ]; then # If ffmpeg doesn't exist
        echo " "
        progressBar .1 "Installing ffmpeg..."
        brew install ffmpeg
        clear
    fi

    if [ ! -f "/usr/local/bin/youtube-dl" ]; then # If youtube-dl doesn't exist
        echo " "
        progressBar .1 "Installing youtube-dl..."
        brew install youtube-dl
        clear
    fi

    if [ "$SHELL" != "/bin/zsh" ]; then # If zsh not enabled.
        echo " "
        progressBar .1 "Fixing quirks with zsh..."
        chsh --shell /bin/zsh $(whoami)
        sudo chmod -R go-w /usr/local/share
        sudo chown -R $(whoami) /usr/local/share/zsh /usr/local/share/zsh/site-functions
        chmod u+w /usr/local/share/zsh /usr/local/share/zsh/site-functions
        clear
    fi

    # Sets as variable packages installed by brew.
    brewInstalled=$(brew list)

    if [[ "$brewInstalled" != *zsh-syntax-highlighting* ]]; then # If zsh-syntax-highlighting not installed.
        echo " "
        progressBar .1 "Installing zsh-syntax-highlighting..."
        brew install zsh-syntax-highlighting
        clear
    fi

    # Sets as variable fonts installed by user.
    fontsInstalled=$(ls $HOME/Library/Fonts)

    if [[ "$fontsInstalled" != *Powerline* ]]; then # If powerline fonts not installed.
        echo " "
        progressBar .1 "Installing Powerline Fonts..."
        git clone https://github.com/powerline/fonts.git --depth=1
        cd fonts
        ./install.sh
        cd ..
        rm -rf fonts
        clear
    fi

    if [ ! -f "$HOME/.zshrc" ]; then # If zshrc doesn't exist intall oh-my-zsh & get config.
        echo " "
        progressBar .1 "Installing oh-my-zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh --unattended)"
        mv -f /tmp/dotfiles/.zshrc $HOME/.zshrc
        clear
    fi

    if [ ! -f "$HOME/.p10k.zsh" ]; then # If zsh theme not installed.
        echo " "
        progressBar .1 "Installing powerlevel10k..."
        if [[ "$fontsInstalled" != *MesloLGS* ]]; then # Install p10k fonts
            wget --quiet https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
            mv MesloLGS NF Regular.ttf $HOME/Library/Fonts/MesloLGS NF Regular.ttf
            wget --quiet https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
            mv MesloLGS NF Bold.ttf $HOME/Library/Fonts/MesloLGS NF Bold.ttf
            wget --quiet https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
            mv MesloLGS NF Italic.ttf $HOME/Library/Fonts/MesloLGS NF Italic.ttf
            wget --quiet https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf
            mv MesloLGS NF Bold Italic.ttf $HOME/Library/Fonts/MesloLGS NF Bold Italic.ttf
        fi
        mv -f /tmp/dotfiles/.oh-my-zsh $HOME/.oh-my-zsh
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
        clear
    fi

    if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then # If no zsh-autosuggestions
        echo " "
        progressBar .1 "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
        clear
    fi

    if [ ! -d "/Applications/iTerm.app" ]; then # If iTerm not installed.
        echo " "
        progressBar .1 "Installing iTerm..."
        brew cask install iterm2
        mv -f /tmp/dotfiles/.iterm2 $HOME/.iterm2
        open /Applications/iTerm.app
        options=("Continue")
        chooseOption "Wait for iTerm2 to fully open...:" 1 "${options[@]}"
        choice=$?
        defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "$HOME/.iterm2"
        defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true
        clear
    fi
    if [ ! -f "$HOME/.z" ]; then # Fixes z bug
        echo " "
        progressBar .1 "Installing z..."
        touch $HOME/.z
        clear
    fi

    gemInstalled=$(gem list) # Sets variable for Ruby Installs

    if [[ "$gemInstalled" != *colorls* ]]; then # If no colorls installed
        echo " "
        progressBar .1 "Installing colorls..."
        gem install colorls
        clear
    fi

    if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/you-should-use" ]; then # If no you-should-use
        echo " "
        progressBar .1 "Installing you-should-use..."
        git clone https://github.com/MichaelAquilina/zsh-you-should-use.git $ZSH_CUSTOM/plugins/you-should-use
        clear
    fi
    echo " "
    progressBar .1 "Finishing up..."
    # Gets p10k.zsh
    mv -f /tmp/dotfiles/.p10k.zsh $HOME/.p10k.zsh
    # Gets .zshenv
    mv -f /tmp/dotfiles/.zshenv $HOME/.zshenv
    # Gets .bash_aliases
    mv -f /tmp/dotfiles/.bash_aliases $HOME/.bash_aliases
    # Gets .bashrc
    mv -f /tmp/dotfiles/.bashrc $HOME/.bashrc

    # Gets scripts folder
    if [ -d "$HOME/scripts" ]; then
        rm -rf $HOME/scripts
        mv -f /tmp/dotfiles/scripts $HOME/scripts

    fi
    rm -rf /tmp/dotfiles
    clear

else
    # # # # #
    # Linux #
    # # # # #

    sudo apt update -qq
    clear

    # Downloads dotfiles gitlab to tmp
    progressBar .1 "Installing dotfiles..."
    currentDIR=$(pwd)
    cd /tmp
    git clone https://gitlab.com/josecarlosmemo/dotfiles.git
    cd $currentDIR
    clear

    if [ ! -f "/bin/zsh" ]; then # If zsh doesn't exist
        echo " "
        progressBar .1 "Installing zsh..."
        sudo apt-get -qq --yes install zsh
        clear
    fi

    if [ ! -f "/usr/bin/lf" ]; then # If lf doesn't exist
        echo " "
        progressBar .1 "Installing lf..."
        wget --quiet https://github.com/gokcehan/lf/releases/download/r14/lf-linux-amd64.tar.gz
        tar -xzvf lf-linux-amd64.tar.gz
        sudo mv lf /usr/bin/lf
        sudo chmod +x /usr/bin/spt
        rm lf-linux-amd64.tar.gz
        clear
    fi

    if [ "$SHELL" != "/bin/zsh" ]; then # If zsh not enabled.
        echo " "
        progressBar .1 "Switching from $SHELL to /bin/zsh..."
        chsh --shell /bin/zsh $(whoami)
        clear
    fi
    # Sets as variable packages installed by brew.
    aptInstalled=$(apt list --installed)

    if [[ "$aptInstalled" != *zsh-syntax-highlighting* ]]; then # If zsh-syntax-highlighting not installed.
        echo " "
        progressBar .1 "Installing zsh-syntax-highlighting..."
        sudo apt-get -qq --yes install zsh-syntax-highlighting
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git
        cd zsh-syntax-highlighting
        sudo make install
        cd ..
        rm -rf zsh-syntax-highlighting
        clear
    fi

    if [[ "$aptInstalled" != *fonts-powerline* ]]; then # If powerline fonts not installed.
        echo " "
        progressBar .1 "Installing Powerline Fonts..."
        sudo apt-get -qq --yes install fonts-powerline
        clear
    fi

    if [ ! -f "$HOME/.zshrc" ]; then # If zshrc doesn't exist intall oh-my-zsh & get config.
        echo " "
        progressBar .1 "Installing oh-my-zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh) --unattended"
        mv -f /tmp/dotfiles/.zshrc $HOME/.zshrc
        clear
    fi

    if [ ! -f "$HOME/.p10k.zsh" ]; then # If zsh theme not installed.
        echo " "
        progressBar .1 "Installing powerlevel10k..."
        if [[ "$fontsInstalled" != *MesloLGS* ]]; then # Install p10k fonts
            wget --quiet https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
            sudo mv 'MesloLGS NF Regular.ttf' '/usr/share/fonts/truetype/MesloLGS NF Regular.ttf'
            wget --quiet https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
            sudo mv 'MesloLGS NF Bold.ttf' '/usr/share/fonts/truetype/MesloLGS NF Bold.ttf'
            wget --quiet https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
            sudo mv 'MesloLGS NF Italic.ttf' '/usr/share/fonts/truetype/MesloLGS NF Italic.ttf'
            wget --quiet https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf
            sudo mv 'MesloLGS NF Bold Italic.ttf' '/usr/share/fonts/truetype/MesloLGS NF Bold Italic.ttf'
        fi
        mv -f /tmp/dotfiles/.oh-my-zsh $HOME/.oh-my-zsh
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
        clear
    fi

    if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then # If no zsh-autosuggestions
        echo " "
        progressBar .1 "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
        clear
    fi

    if [ ! -f "$HOME/.z" ]; then # Fixes z bug
        echo " "
        progressBar .1 "Installing z..."
        touch $HOME/.z
        clear
    fi

    if [ ! -f "/usr/bin/spt" ]; then # If spt doesn't exist
        echo " "
        progressBar .1 "Installing Spotify for Terminal..."
        wget --quiet https://github.com/Rigellute/spotify-tui/releases/download/v0.20.0/spotify-tui-linux.tar.gz
        tar -xzvf spotify-tui-linux.tar.gz
        sudo mv spt /usr/bin/spt
        sudo chmod +x /usr/bin/spt
        rm spotify-tui-linux.tar.gz
        clear
    fi

    gemInstalled=$(gem list) # Sets variable for Ruby Installs

    if [[ "$gemInstalled" != *colorls* ]]; then # If no colorls installed
        echo " "
        progressBar .1 "Installing colorls..."
        gem install colorls
        clear
    fi

    if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/you-should-use" ]; then # If no you-should-use
        echo " "
        progressBar .1 "Installing you-should-use..."
        git clone https://github.com/MichaelAquilina/zsh-you-should-use.git $ZSH_CUSTOM/plugins/you-should-use
        clear
    fi

    if [ ! -f "/usr/bin/ffmpeg" ]; then # If ffmpeg doesn't exist
        echo " "
        progressBar .1 "Installing ffmpeg..."
        sudo apt-get -qq --yes install ffmpeg
        clear
    fi

    if [ ! -f "/usr/bin/youtube-dl" ]; then # If youtube-dl doesn't exist
        echo " "
        progressBar .1 "Installing youtube-dl..."
        sudo apt-get -qq --yes install youtube-dl
        clear
    fi

    echo " "
    progressBar .1 "Finishing up..."
    # Gets p10k.zsh
    mv -f /tmp/dotfiles/.p10k.zsh $HOME/.p10k.zsh
    # Gets .zshenv
    mv -f /tmp/dotfiles/.zshenv $HOME/.zshenv
    # Gets .bash_aliases
    mv -f /tmp/dotfiles/.bash_aliases $HOME/.bash_aliases
    # Gets .bashrc
    mv -f /tmp/dotfiles/.bashrc $HOME/.bashrc
    # Gets scripts folder
    if [ -d "$HOME/scripts" ]; then
        rm -rf $HOME/scripts
        mv -f /tmp/dotfiles/scripts $HOME/scripts
    fi
    mv -f /tmp/dotfiles/.config/qterminal.org/qterminal.ini $HOME/.config/qterminal.org/qterminal.ini
    rm -rf /tmp/dotfiles
    echo $(tput setaf 1)Done!$(tput sgr0)
    clear
    exit

fi
