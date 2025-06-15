#!/bin/bash

# #
#   Utility › Fix Perms
#
#   ensure you chmod +x util-fix.sh
# #

# #
#   define > colors
#
#   Use the color table at:
#       - https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797
# #

declare -A c=(
    [end]=$'\e[0m'
    [white]=$'\e[97m'
    [bold]=$'\e[1m'
    [dim]=$'\e[2m'
    [underline]=$'\e[4m'
    [strike]=$'\e[9m'
    [blink]=$'\e[5m'
    [inverted]=$'\e[7m'
    [hidden]=$'\e[8m'
    [black]=$'\e[0;30m'
    [redl]=$'\e[0;91m'
    [redd]=$'\e[0;31m'
    [red1]=$'\e[38;5;160m'
    [red2]=$'\e[38;5;196m'
    [magental]=$'\e[0;95m'
    [magentad]=$'\e[0;35mm'
    [fuchsia1]=$'\e[38;5;205m'
    [fuchsia2]=$'\e[38;5;198m'
    [bluel]=$'\e[0;94m'
    [blued]=$'\e[0;34m'
    [blue1]=$'\e[38;5;033m'
    [blue2]=$'\e[38;5;033m'
    [blue3]=$'\e[38;5;68m'
    [cyanl]=$'\e[0;96m'
    [cyand]=$'\e[0;36m'
    [greenl]=$'\e[0;92m'
    [greend]=$'\e[0;32m'
    [green1]=$'\e[38;5;2m'
    [green2]=$'\e[38;5;76m'
    [yellowl]=$'\e[0;93m'
    [yellowd]=$'\e[0;33m'
    [yellow1]=$'\e[38;5;184m'
    [yellow2]=$'\e[38;5;190m'
    [yellow3]=$'\e[38;5;193m'
    [orange1]=$'\e[38;5;202m'
    [orange2]=$'\e[38;5;208m'
    [greyl]=$'\e[0;37m'
    [greyd]=$'\e[0;90m'
    [grey1]=$'\e[38;5;240m'
    [grey2]=$'\e[38;5;244m'
    [grey3]=$'\e[38;5;250m'
    [navy]=$'\e[38;5;62m'
    [olive]=$'\e[38;5;144m'
    [peach]=$'\e[38;5;210m'
)

# #
#   define
# #

app_file_this=$(basename "$0")                                                      #  file.sh (with ext)
app_file_bin="${app_file_this%.*}"                                                  #  file (without ext)

# #
#   start
# #

echo -e
printf '%-29s %-65s\n' "  ${c[bluel]}${app_file_this}${c[end]}" "${c[greenl]}Starting to fix permissions ... ${c[end]}"

# #
#   set execute on run files
# #

find ./ -name 'run' -print -exec sudo chmod +x {} \;

# #
#   fix CRLF (Windows) to LF (Linux) line-endings
# #

find ./ -type f | grep -Ev 'docs|node_modules|.git|*.jpg|*.jpeg|*.gif|*.png' | xargs dos2unix --

# #
#   finish
# #

printf '%-29s %-65s\n' "  ${c[bluel]}${app_file_this}${c[end]}" "${c[greenl]}Finished fixing permissions ${c[end]}"
echo -e
