#!/usr/bin/env bash
#
# 📦 适用于Debian/Ubuntu的LeviLamina一键安装脚本
#
# 作者: Yzev (GitHub: @YzevDev)
# 版本: 0.0.3
#
# MIT License
# Copyright (c) 2025 Yzev
# 参考: https://opensource.org/license/mit
#

set -e
clear
trap 'stty sane; tput cnorm; printf "\r${reset}"' EXIT

SUPPORT_CODENAMES=(plucky oracular noble jammy focal trixie bookworm bullseye)

red=$(tput setaf 9)
yellow=$(tput setaf 11)
blue=$(tput setaf 12)
green=$(tput setaf 10)
purple=$(tput setaf 13)
reset=$(tput sgr0)

printf "\n${red}%s${reset}\n" '  _                _ _                     _             '
printf "${red}%s${reset}\n" ' | |              (_) |                   (_)            '
printf "${yellow}%s${reset}\n" ' | |     _____   ___| |     __ _ _ __ ___  _ _ __   __ _ '
printf "${blue}%s${reset}\n" ' | |    / _ \ \ / / | |    / _` | '\''_ ` _ \| | '\''_ \ / _` |'
printf "${green}%s${reset}\n" ' | |___|  __/\ V /| | |___| (_| | | | | | | | | | | (_| |'
printf "${purple}%s${reset}\n" ' |______\___| \_/ |_|______\__,_|_| |_| |_|_|_| |_|\__,_|'
printf "${purple}%s${reset}\n" '          _____           _        _ _            '
printf "${purple}%s${reset}\n" '         |_   _|         | |      | | |           '
printf "${green}%s${reset}\n" '           | |  _ __  ___| |_ __ _| | | ___ _ __  '
printf "${blue}%s${reset}\n" '           | | | '\''_ \/ __| __/ _` | | |/ _ \ '\''__| '
printf "${yellow}%s${reset}\n" '          _| |_| | | \__ \ || (_| | | |  __/ |    '
printf "${red}%s${reset}\n\n" '         |_____|_| |_|___/\__\__,_|_|_|\___|_|    '
printf "${blue}作者: ${yellow}%s${reser}\n" 'Yzev'
printf "${blue}版本: ${yellow}%s${reser}\n" '0.0.3'

spinner() {
  spin='-\|/'
  while [[ -d /proc/$1 ]]; do
    printf "\r${yellow}[${spin:i++%4:1}] ${blue}%s${reset}" $2
    sleep 0.1
  done
  printf "\r%${COLUMNS}s" ''
}

if [[ $(id -u) -ne 0 ]]; then
  printf "${red}LeviLamina安装脚本必须以root用户运行${reset}\n"
  exit 1
fi

current_codename=$(lsb_release -cs)
if [[ $(uname -m) != x86_64 ]] || ! [[ ${SUPPORT_CODENAMES[*]} =~ (^| )${current_codename}( |$) ]]; then
  printf "${red}当前系统不支持安装LeviLamina${reset}\n"
  exit 1
fi

default_install_path=~/LeviLamina
printf "${blue}请输入LeviLamina安装目录(默认: ${default_install_path}): ${yellow}"
read install_path
tput cuu1
tput el
install_path=$(realpath ${install_path:-$default_install_path})
if [[ -d $install_path ]]; then
  printf "${red}目录${install_path}已存在${reset}\n"
  exit 1
else
  printf "${blue}将安装目录设置在${yellow}${install_path}? [Y/n] "
  read answer
  answer=${answer:-Y}
  if [[ $answer =~ ^[Y/y]$ ]]; then
    mkdir -p $install_path
    if [[ $? -ne 0 ]]; then
      printf "${red}目录${install_path}无法创建${reset}\n"
      exit 1
    else
      cd $install_path
      stty -echo -icanon time 0 min 0
      tput cuu1
      tput el
      tput civis
    fi
  else
    tput cuu1
    tput el
    printf "${yellow}LeviLamina安装脚本退出${reset}\n"
    exit 1
  fi
fi

start_time=$(date +%s)

dpkg --add-architecture i386

curl -sSo /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key &
spinner $! '正在下载Wine密钥'

current_distributor_id=$(lsb_release -is)
sources_path=/etc/apt/sources.list.d/winehq-${current_codename}.sources
curl -sSo $sources_path https://dl.winehq.org/wine-builds/${current_distributor_id,,}/dists/${current_codename}/winehq-${current_codename}.sources &
spinner $! '正在下载Wine源文件'

sed -i "s|URIs: .*|URIs: https://mirrors.tuna.tsinghua.edu.cn/wine-builds/${current_distributor_id,,}/|" $sources_path

apt-get update &> /dev/null &
spinner $! '正在更新软件包列表'

apt-get install -y winehq-stable &> /dev/null &
spinner $! '正在安装Wine'

wineboot -u &> /dev/null &
spinner $! '正在初始化Wine环境'

apt-get install -y xvfb &> /dev/null &
spinner $! '正在安装Xvfb'

curl -sSo dotnet.exe https://builds.dotnet.microsoft.com/dotnet/Runtime/9.0.6/dotnet-runtime-9.0.6-win-x64.exe &
spinner $! '正在下载.NET运行时'

xvfb-run -a wine dotnet.exe /quiet /norestart &> /dev/nill &
spinner $! '正在安装.NET运行时'

rm -rf dotnet.exe

curl -sSo lip.msi https://github.bibk.top/futrime/lip/releases/latest/download/lip-cli-win-x64-zh-CN.msi &
spinner $! '正在下载Lip'

wine lip.msi /quiet /norestart &> /dev/null &
spinner $! '正在安装Lip'

rm -rf lip.msi

wine lip config set github_proxies=https://github.bibk.top &> /dev/null &
spinner $! '正在设置Lip代理'

wine lip config set go_module_proxies=https://goproxy.cn &> /dev/null &
spinner $! '正在设置Lip代理'

wine lip install github.com/LiteLDev/LeviLamina &> /dev/null &
spinner $! '正在安装LeviLamina'

wine bedrock_server_mod &> /dev/null &
spinner $! '正在安装LeviLamina'

sed -i 's|"enableStatistics": true|"enableStatistics": false|' plugins/LeviLamina/config/Config.json

printf "${blue}启动服务器:${reset}\n"
printf "${yellow}~\$ cd ${install_path}${reset}\n"
printf "${yellow}~\$ ( cat | wine bedrock_server_mod ) 2> /dev/null${reset}\n\n"

end_time=$(date +%s)
elapsed=$((end_time - start_time))
minutes=$((elapsed / 60))
seconds=$((elapsed % 60))
printf "${green}LeviLamina安装成功 耗时: ${minutes}分${seconds}秒${reset}\n"
