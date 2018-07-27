export fpath=($fpath ~/.config/zsh)
export PATH=$PATH:/opt/local/bin:~/.npm-global/bin
export NPM_CONFIG_PREFIX='~/.npm-global'

export LC_ALL=en_US.UTF-
export LANG=en_US.UTF-8

# Android studio vars
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

# For "react-native run-android" to work, we need jdk 1.8
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_171.jdk/Contents/Home

SAVEHIST=1000000
