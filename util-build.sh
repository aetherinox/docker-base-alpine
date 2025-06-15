#!/bin/bash

# #
#   Utility › Build Script
#
#   @desc           this script allows you to build the docker images in Linux, without memorizing the long commands.
#                       ensure you run the command `sudo chmod +x util-build.sh` to set the proper execution permission.
#                       some of the parameters are optional, as a lot of the parameters have default values already.
#
#   @usage          ./util-build.sh --help
#                   ./util-build.sh --version 3.22 --arch amd64 --registry local
#                   ./util-build.sh --dockerfile CustomDockerfile --version 3.22 --arch amd64 --registry local
#                   ./util-build.sh --version 3.22 --arch amd64 --release beta --registry github --author Aetherinox --network default --name alpine
#
#                   This script includes the ability to:
#                       fix permissions
#                       restart docker container
#                       use bitwarden secret's manager
#
#                   Fix Permissions & Carriage / Lines
#                       will chmod +x all `run` files
#                       will change all Windows CRLF to Unix LF using dos2unix
#                           Line endings in text files are marked using special control characters:
#                               CR (Carriage Return, 0x0D or decimal 13)
#                               LF (Line Feed, 0x0A or decimal 10).
#                           Different operating systems use different conventions for line breaks:
#                               Windows uses a CRLF (\r\n) sequence to indicate the end of a line.
#                               Unix/Linux and modern macOS (starting from macOS 10.0) use LF (\n) only.
#                               Classic Mac OS (prior to version 10.0) used CR (\r) alone.
#                           If you attempt to build your Alpine docker image on Linux, and have windows CRLF
#                               in your files; you will get errors and the container will be unable to start.
#
#                   Restart Container
#                       to restart the docker container after this script finishes, append `-ra` or `--restart` to your command.
#                       if you need to load an .env file, add `--env` or `-E` to the beginning of the command; such as:
#                           ./util-build.sh -ra --env ./.myenv
#                       you can append as many env files as you need, simply seperate each file with a comma
#                           ./util-build.sh -ra --env ./.env,.anotherEnv,third.env
#                       your full command could look something like the following if you want to build and then restart:
#                           ./util-build.sh -ra --env ./.env,.anotherEnv,third.env \
#                               --version 3.22 \
#                               --arch amd64 \
#                               --release beta \
#                               --registry github \
#                               --author Aetherinox \
#                               --network default \
#                               --name alpine
#
#                   Bitwarden Secret's Manager
#                       this script supports injecting secrets into your docker container. if you use the Bitwarden CLI to normally start / restart
#                       your container, then your secrets will be automatically injected when the container restarts.
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
#   Define › Dirs
# #

app_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"            #  path where script was last found in
app_dir_this_dir="${PWD}"                                                           #  current script directory
app_dir_bin="${HOME}/bin"                                                           #  /home/$USER/bin

# #
#   Define › Files
# #

app_file_this=$(basename "$0")                                                      #  util.-uild.sh (with ext)
app_file_bin="${app_file_this%.*}"                                                  #  util.-uild (without ext)

# #
#   Docker Containers › Alpine Base
#
#   These commands allow you to re-build SearXNG with your custom files into a new docker image
#
#   @usage              ./util-build \
#                           --version 3.22 \
#                           --src <PATH:optional> \
#                           --dockerfile <PATH:optional> \
#                           --author <AUTHOR:optional> \
#                           --arch <ARCH:optional:amd64/arm64>
# #

script_title="Builder › Alpine"
script_about="This command allows you to build a docker image for $script_title"
script_updated="07-01-2025"
script_version="1.0.0"

# #
#   Define › Args
# #

image_path_build="${app_dir_this_dir}"
image_name=alpine
image_author=aetherinox
image_arch=amd64
image_release=stable
image_registry=local
image_dockerfile=Dockerfile
image_network=host
image_git_sha1_long=$(git rev-parse HEAD)
image_git_sha1_short=${image_git_sha1_long:(-8)}
image_build_id=$(tr -dc A-Fa-f0-9 </dev/urandom | head -c 9; echo)
image_build_ident="$(date +%Y).$(date +%m).$(date +%d)-${image_git_sha1_short}"
image_builddate=$(date +'%Y%m%d')                                                   # 20250225
image_version=3.22                                                                  # 3.22
image_version_1digit=`echo ${image_version} | cut -d '.' -f1-1`                     # 3
image_version_2digit=`echo ${image_version} | cut --complement -c4`                 # 3.2
image_use_emulator=false
image_restart=false

# #
#   load .env on restart if -ra, --restart specified
# #

restart_env_in="${image_path_build}/.env"
restart_env_out=

# #
#   Define › Checks
# #

if [[ -z ${image_git_sha1_long} ]]; then
    image_git_sha1_long=0000000000000000000000000000000000000000
    image_git_sha1_short=${image_git_sha1_long:(-8)}
fi

# #
#   Define › Options
# #

while [ $# -gt 0 ]; do
    case "$1" in
        -v|--ver|--version)
            if [[ "$1" != *=* ]]; then shift; fi
            image_version="${1#*=}"                                                 #  3.22
            image_version_1digit=`echo ${image_version} | cut -d '.' -f1-1`         #  3
            image_version_2digit=`echo ${image_version} | cut --complement -c4`     #  3.2
            ;;
        -n|--name)
            if [[ "$1" != *=* ]]; then shift; fi
            image_name="${1#*=}"
            ;;
        -s|--src|--source)
            if [[ "$1" != *=* ]]; then shift; fi
            image_path_build="${1#*=}"
            ;;
        -f|--file|--dockerfile)
            if [[ "$1" != *=* ]]; then shift; fi
            image_dockerfile="${1#*=}"
            ;;
        -a|--author)
            if [[ "$1" != *=* ]]; then shift; fi
            image_author="${1#*=}"
            ;;
        -A|--arch)
            if [[ "$1" != *=* ]]; then shift; fi
            image_arch="${1#*=}"
            ;;
        -r|--rel|--release)
            if [[ "$1" != *=* ]]; then shift; fi
            image_release="${1#*=}"
            ;;
        -R|--registry)
            if [[ "$1" != *=* ]]; then shift; fi
            image_registry="${1#*=}"
            ;;

        # #
        #   env files
        # #

        -E|--env)
            if [[ "$1" != *=* ]]; then shift; fi
            envList="${1#*=}"
            restart_docker_env_list=()
            for envfile in $(echo $envList | awk -F, '{for (i=1; i<=NF; i++) print $i}' ); do
                restart_docker_env_list+=("$envfile")
            done

            # #
            #   array to single string
            #       --env-file something.env --env-file another.env --env-file third.env
            #  #

            restart_env_out=""
            for cmd in "${restart_docker_env_list[@]}"; do
                restart_env_out+="--env-file $cmd "
            done
            ;;

        -ra|--restart)
            image_restart=true
            printf '%-29s %-65s\n' "  ${c[bluel]}${app_file_this}${c[end]}" "${c[greenl]}Container will restart after build${c[end]}"
            ;;
        -N|--network)
            if [[ "$1" != *=* ]]; then shift; fi
            image_network="${1#*=}"
            ;;
        -e|--emulator)
            image_use_emulator=true

            if [ "${image_use_emulator}" = true ]; then
                printf '%-29s %-65s\n' "  ${c[bluel]}${app_file_this}${c[end]}" "${c[greenl]}Starting emulator QEMU ${c[end]}"
                docker run --privileged --rm tonistiigi/binfmt --install all
            fi
            ;;
        -h|--help|/?)
            echo -e
            printf "  ${c[blue1]}${script_title}${c[end]}\n" 1>&2
            echo -e
            printf "  ${c[grey2]}${script_about}${c[end]}\n" 1>&2
            printf "  ${c[grey1]}last update: $script_updated${c[end]} | ${c[grey1]}version: v$script_version${c[end]}\n" 1>&2
            printf "  ${c[fuchsia2]}$app_file_this${c[end]} ${c[grey1]}[${c[grey2]}-h${c[grey1]} | ${c[grey2]}--help${c[grey1]}] | ${c[grey2]}--name ${c[yellow1]}arg${c[grey1]} ${c[grey2]}--version ${c[yellow1]}arg${c[grey1]} ${c[grey2]}--arch ${c[yellow1]}arg${c[end]}" 1>&2
            echo -e
            echo -e
            printf '  %-5s %-40s\n' "${c[grey1]}Syntax:${c[end]}" "" 1>&2
            printf '  %-5s %-30s %-40s\n' "    " "${c[grey1]}Command${c[end]}           " "${c[fuchsia2]}$app_file_this${c[grey1]} [ ${c[grey2]}-option ${c[grey1]}[ ${c[yellow1]}arg${c[grey1]} ]${c[grey1]} ]${c[end]}" 1>&2
            printf '  %-5s %-30s %-40s\n' "    " "${c[grey1]}Options${c[end]}           " "${c[fuchsia2]}$app_file_this${c[grey1]} [ ${c[grey2]}-h${c[grey1]} | ${c[grey2]}--help${c[grey1]} ]${c[end]}" 1>&2
            printf '  %-5s %-30s %-40s\n' "    " "    ${c[grey2]}-A${c[end]}            " "required" 1>&2
            printf '  %-5s %-30s %-40s\n' "    " "    ${c[grey2]}-A...${c[end]}         " "required; multiple can be specified" 1>&2
            printf '  %-5s %-30s %-40s\n' "    " "    ${c[grey2]}[ -A ]${c[end]}        " "optional" 1>&2
            printf '  %-5s %-30s %-40s\n' "    " "    ${c[grey2]}[ -A... ]${c[end]}     " "optional; multiple can be specified" 1>&2
            printf '  %-5s %-30s %-40s\n' "    " "    ${c[grey2]}{ -A | -B }${c[end]}   " "one or the other; do not use both" 1>&2
            printf '  %-5s %-30s %-40s\n' "    " "${c[grey1]}Arguments${c[end]}         " "${c[fuchsia2]}$app_file_this${c[end]} ${c[grey1]}${c[end]}" 1>&2
            printf '  %-5s %-30s %-40s\n' "    " "${c[grey1]}Examples${c[end]}          " "${c[fuchsia2]}$app_file_this${c[end]} ${c[grey2]}--name${c[yellow1]} \"${image_name}\" ${c[grey2]}--version${c[yellow1]} \"${image_version}\" ${c[grey2]}--arch${c[yellow1]} \"amd64|arm64\" ${c[grey2]}--release${c[yellow1]} \"stable|development\"${c[end]}" 1>&2
            printf '  %-5s %-30s %-40s\n' "    " "${c[grey1]}${c[end]}                  " "${c[fuchsia2]}$app_file_this${c[end]} ${c[grey2]}--name${c[yellow1]} \"${image_name}\" ${c[grey2]}--version${c[yellow1]} \"${image_version}\" ${c[grey2]}--arch${c[yellow1]} \"amd64|arm64\" ${c[grey2]}--release${c[yellow1]} \"stable|development\" ${c[grey2]}--dockerfile${c[yellow1]} \"${image_dockerfile}\"${c[end]}" 1>&2
            printf '  %-5s %-30s %-40s\n' "    " "${c[grey1]}${c[end]}                  " "${c[fuchsia2]}$app_file_this${c[end]} ${c[grey2]}--name${c[yellow1]} \"${image_name}\" ${c[grey2]}--version${c[yellow1]} \"${image_version}\" ${c[grey2]}--arch${c[yellow1]} \"amd64|arm64\" ${c[grey2]}--release${c[yellow1]} \"stable|development\" ${c[grey2]}--dockerfile${c[yellow1]} \"${image_dockerfile}\" ${c[grey2]}--author${c[yellow1]} \"${image_author}\"${c[end]}" 1>&2
            printf '  %-5s %-30s %-40s\n' "    " "${c[grey1]}${c[end]}                  " "${c[fuchsia2]}$app_file_this${c[end]} ${c[grey2]}--name${c[yellow1]} \"${image_name}\" ${c[grey2]}--version${c[yellow1]} \"${image_version}\" ${c[grey2]}--arch${c[yellow1]} \"amd64|arm64\" ${c[grey2]}--release${c[yellow1]} \"stable|development\" ${c[grey2]}--dockerfile${c[yellow1]} \"${image_dockerfile}\" ${c[grey2]}--author${c[yellow1]} \"${image_author}\" ${c[grey2]}--source${c[yellow1]} \"${image_path_build}\"${c[end]}" 1>&2
            printf '  %-5s %-30s %-40s\n' "    " "${c[grey1]}${c[end]}                  " "${c[fuchsia2]}$app_file_this${c[end]} ${c[grey1]}[ ${c[grey2]}--VERSION${c[grey1]} | ${c[grey2]}-V${c[grey1]} | ${c[grey2]}/v${c[grey1]} ]${c[end]}" 1>&2
            printf '  %-5s %-30s %-40s\n' "    " "${c[grey1]}${c[end]}                  " "${c[fuchsia2]}$app_file_this${c[end]} ${c[grey1]}[ ${c[grey2]}--help${c[grey1]} | ${c[grey2]}-h${c[grey1]} | ${c[grey2]}/?${c[grey1]} ]${c[end]}" 1>&2
            echo -e
            printf '  %-5s %-40s\n' "${c[grey1]}Options:${c[end]}" "" 1>&2
            printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-s${c[grey1]},${c[blue2]}  --source ${c[yellow1]}<string>${c[end]}             " "specify build folder where Dockerfile exists ${c[navy]}<default> ${c[peach]}$image_path_build${c[end]}" 1>&2
            printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-v${c[grey1]},${c[blue2]}  --version ${c[yellow1]}<string>${c[end]}            " "version tag to use for built docker image ${c[end]} ${c[navy]}<default> ${c[peach]}$image_version${c[end]}" 1>&2
            printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-f${c[grey1]},${c[blue2]}  --dockerfile ${c[yellow1]}<string>${c[end]}         " "name of dockerfile to load ${c[navy]}<default> ${c[peach]}$image_dockerfile${c[end]}" 1>&2
            printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-a${c[grey1]},${c[blue2]}  --author ${c[yellow1]}<string>${c[end]}             " "author to use for docker image tag; must be lowercase${c[end]} ${c[navy]}<default> ${c[peach]}$image_author${c[end]}" 1>&2
            printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}  ${c[grey1]} ${c[blue2]}      ${c[yellow1]}${c[end]}                          " "   ${c[fuchsia2]}$app_file_this${c[end]} ${c[grey1]}--author ${c[blue1]}${image_author} ${c[grey1]}--name ${c[blue1]}${image_name}${c[grey1]} ${c[grey1]}--version ${c[blue1]}${image_version}${c[end]}" 1>&2
            printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}  ${c[grey1]} ${c[blue2]}      ${c[yellow1]}${c[end]}                          " "   ${c[grey1]}docker tag: ${c[blue1]}image_author/image_name:image_version${c[end]}" 1>&2
            printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}  ${c[grey1]} ${c[blue2]}      ${c[yellow1]}${c[end]}                          " "   ${c[grey1]}docker tag: ${c[blue1]}$image_author/$image_name:$image_version${c[end]}" 1>&2
            printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}  ${c[grey1]} ${c[blue2]}      ${c[yellow1]}${c[end]}                          " "   ${c[grey1]}docker tag: ${c[blue1]}ghcr.io/$image_author/$image_name:$image_version${c[end]}" 1>&2
            printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-n${c[grey1]},${c[blue2]}  --name ${c[yellow1]}<string>${c[end]}               " "specify docker image name; must be lowercase${c[end]} ${c[navy]}<default> ${c[peach]}$image_name${c[end]}" 1>&2
            printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-A${c[grey1]},${c[blue2]}  --arch ${c[yellow1]}<string>${c[end]}               " "architecture to build docker image for${c[end]} ${c[navy]}<default> ${c[peach]}$image_arch${c[end]}" 1>&2
            printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}  ${c[grey1]} ${c[blue2]}      ${c[yellow1]}${c[end]}                          " "   ${c[grey1]}pick any of the following options:" 1>&2
            printf '  %-5s %-30s %-40s\n' "    " "${c[blue2]}  ${c[grey1]} ${c[blue2]}      ${c[yellow1]}${c[end]}                          " "      - ${c[green1]}amd64${c[end]}" 1>&2
            printf '  %-5s %-30s %-40s\n' "    " "${c[blue2]}  ${c[grey1]} ${c[blue2]}      ${c[yellow1]}${c[end]}                          " "      - ${c[green1]}arm64${c[end]}" 1>&2
            printf '  %-5s %-30s %-40s\n' "    " "${c[blue2]}  ${c[grey1]} ${c[blue2]}      ${c[yellow1]}${c[end]}                          " "      - ${c[green1]}i386${c[end]}" 1>&2
            printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-r${c[grey1]},${c[blue2]}  --release ${c[yellow1]}<string>${c[end]}            " "specify type of release ${c[navy]}<default> ${c[peach]}$image_release${c[end]}" 1>&2
            printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}  ${c[grey1]} ${c[blue2]}      ${c[yellow1]}${c[end]}                          " "   ${c[grey1]}pick any of the following options:" 1>&2
            printf '  %-5s %-30s %-40s\n' "    " "${c[blue2]}  ${c[grey1]} ${c[blue2]}      ${c[yellow1]}${c[end]}                          " "      - ${c[green1]}stable${c[end]}" 1>&2
            printf '  %-5s %-30s %-40s\n' "    " "${c[blue2]}  ${c[grey1]} ${c[blue2]}      ${c[yellow1]}${c[end]}                          " "      - ${c[green1]}development${c[end]}" 1>&2
            printf '  %-5s %-30s %-40s\n' "    " "${c[blue2]}  ${c[grey1]} ${c[blue2]}      ${c[yellow1]}${c[end]}                          " "      - ${c[green1]}alpha${c[end]}" 1>&2
            printf '  %-5s %-30s %-40s\n' "    " "${c[blue2]}  ${c[grey1]} ${c[blue2]}      ${c[yellow1]}${c[end]}                          " "      - ${c[green1]}nightly${c[end]}" 1>&2
            printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-R${c[grey1]},${c[blue2]}  --registry ${c[yellow1]}<string>${c[end]}           " "registry you are releasing the image on ${c[end]} ${c[navy]}<default> ${c[peach]}$image_registry${c[end]}" 1>&2
            printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-N${c[grey1]},${c[blue2]}  --network ${c[yellow1]}<string>${c[end]}            " "network to use for docker buildx ${c[navy]}<default> ${c[peach]}$image_network${c[end]}" 1>&2
            printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-e${c[grey1]},${c[blue2]}  --emulator ${c[yellow1]}${c[end]}                   " "start QEMU emulator before building docker image ${c[navy]}<default> ${c[peach]}$image_use_emulator${c[end]}" 1>&2
            printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-ra${c[grey1]},${c[blue2]} --restart ${c[yellow1]}${c[end]}                    " "restart docker container for the folder you are in ${c[navy]}<default> ${c[peach]}$image_restart${c[end]}" 1>&2
            printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}  ${c[grey1]} ${c[blue2]}      ${c[yellow1]}${c[end]}                          " "   ${c[grey1]}can be used in combination with ${c[blue1]}--env${end}" 1>&2
            printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-E${c[grey1]},${c[blue2]}  --env ${c[yellow1]}${c[end]}                        " "force docker to load your env file(s) when you restart the container ${c[end]}" 1>&2
            echo -e
            printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-V${c[grey1]},${c[blue2]}  --VERSION ${c[yellow1]}${c[end]}                    " "current version of ${c[blue1]}${script_title}${c[end]}" 1>&2
            printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-x${c[grey1]},${c[blue2]}  --dev ${c[yellow1]}${c[end]}                        " "developer mode; verbose logging${c[end]}" 1>&2
            printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-h${c[grey1]},${c[blue2]}  --help ${c[yellow1]}${c[end]}                       " "show this help menu${c[end]}" 1>&2
            echo -e
            echo -e
            exit 1
            ;;
        *)
            echo
            echo -e "  ${c[bold]}${c[redl]}ERROR            ${c[end]}Invalid parameter specified${c[end]}"
            echo -e "  ${c[end]}                 You specified a parameter which is not valid. To see the available options, type:${c[end]}"
            echo -e "  ${c[bold]}${c[grey2]}                         ${c[fuchsia2]}./${app_file_this}${c[end]} --help"
            echo -e "  ${c[bold]}${c[grey2]}                         ${c[fuchsia2]}./${app_file_this}${c[end]} -h"
            echo

            exit 1
            ;;
    esac
    shift
done

# #
#   start
# #

echo -e
printf '%-29s %-65s\n' "  ${c[bluel]}${app_file_this}${c[end]}" "${c[greenl]}Starting build ... ${c[end]}"

# #
#   Build folder doesn't exist
# #

if [ ! -d "$image_path_build" ]; then
    echo
    echo -e "  ${c[bold]}${c[orange1]}WARNING          ${c[end]}$script_title Source Path Does Not Exist${c[end]}"
    echo -e "  ${c[end]}                 You must specify a valid path where the $script_title source files are.${c[end]}"
    echo -e "  ${c[bold]}${c[grey2]}                         ${c[fuchsia2]}./${app_file_this}${c[end]}"
    echo

    exit 1
fi

# #
#   Build tag version not specified
# #

if [ -z "$image_version" ]; then
    echo
    echo -e "  ${c[bold]}${c[orange1]}WARNING          ${c[end]}Version Not Specified${c[end]}"
    echo -e "  ${c[end]}                 You must supply a version tag for the docker image${c[end]}"
    echo -e "  ${c[bold]}${c[grey2]}                         ${c[fuchsia2]}${image_version}${c[end]}"
    echo

    exit 1
fi

# #
#   run script fix perms
# #

source ./util-fix.sh

# #
#   change work directory
# #

# cd ${image_path_build}

# #
#   build docker image
# #

docker buildx build \
    --build-arg IMAGE_NAME=$image_name \
    --build-arg IMAGE_ARCH=$image_arch \
    --build-arg IMAGE_BUILDDATE=$image_builddate \
    --build-arg IMAGE_VERSION=$image_version \
    --build-arg IMAGE_RELEASE=$image_release \
    --build-arg IMAGE_REGISTRY=$image_registry \
    --tag $image_author/$image_name:latest \
    --tag $image_author/$image_name:$image_version_1digit \
    --tag $image_author/$image_name:$image_version_2digit \
    --tag $image_author/$image_name:$image_version \
    --tag $image_author/$image_name:$image_version-$image_arch \
    --file $image_dockerfile \
    --platform linux/$image_arch \
    --attest type=provenance,disabled=true \
    --attest type=sbom,disabled=true \
    --output type=docker \
    --allow network.${image_network} \
    --network ${image_network} \
    --no-cache \
    --pull \
    .

# #
#   change back to original folder
# #

# cd -

echo -e
printf '%-17s %-50s %-55s\n' "        ${c[grey2]} [ app ]         " "${c[blue2]}${image_name}" "${c[end]}"
printf '%-17s %-50s %-55s\n' "        ${c[grey2]} [ arch ]        " "${c[blue2]}${image_arch}" "${c[end]}"
printf '%-17s %-50s %-55s\n' "        ${c[grey2]} [ build-date ]  " "${c[blue2]}${image_builddate}" "${c[end]}"
printf '%-17s %-50s %-55s\n' "        ${c[grey2]} [ version ]     " "${c[blue2]}${image_version}" "${c[end]}"
printf '%-17s %-50s %-55s\n' "        ${c[grey2]} [ release ]     " "${c[blue2]}${image_release}" "${c[end]}"
printf '%-17s %-50s %-55s\n' "        ${c[grey2]} [ registry ]    " "${c[blue2]}${image_registry}" "${c[end]}"
printf '%-17s %-50s %-55s\n' "        ${c[grey2]} [ author ]      " "${c[blue2]}${image_author}" "${c[end]}"
printf '%-17s %-50s %-55s\n' "        ${c[grey2]} [ dockerfile ]  " "${c[blue2]}${image_dockerfile}" "${c[end]}"
printf '%-17s %-50s %-55s\n' "        ${c[grey2]} [ network ]     " "${c[blue2]}${image_network}" "${c[end]}"
printf '%-17s %-50s %-55s\n' "        ${c[grey2]} [ src ]         " "${c[blue2]}${image_path_build}" "${c[end]}"
printf '%-17s %-50s %-55s\n' "        ${c[grey2]} [ tag ]         " "${c[blue2]}$image_author/$image_name:latest" "${c[grey1]}${c[end]}"
printf '%-17s %-50s %-55s\n' "        ${c[grey2]} [ tag ]         " "${c[blue2]}$image_author/$image_name:$image_version_1digit" "${c[grey1]}${c[end]}"
printf '%-17s %-50s %-55s\n' "        ${c[grey2]} [ tag ]         " "${c[blue2]}$image_author/$image_name:$image_version_2digit" "${c[grey1]}${c[end]}"
printf '%-17s %-50s %-55s\n' "        ${c[grey2]} [ tag ]         " "${c[blue2]}$image_author/$image_name:$image_version" "${c[grey1]}${c[end]}"
printf '%-17s %-50s %-55s\n' "        ${c[grey2]} [ tag ]         " "${c[blue2]}$image_author/$image_name:$image_version-$image_arch" "${c[grey1]}${c[end]}"
echo -e
printf '%-17s %-50s %-55s\n' "        ${c[grey2]} [ build # ]     " "${c[blue2]}${image_build_id}" "${c[end]}"
printf '%-17s %-50s %-55s\n' "        ${c[grey2]} [ build-id ]    " "${c[blue2]}${image_build_ident}" "${c[end]}"
printf '%-17s %-50s %-55s\n' "        ${c[grey2]} [ SHA1-long ]   " "${c[blue2]}${image_git_sha1_long}" "${c[end]}"
printf '%-17s %-50s %-55s\n' "        ${c[grey2]} [ SHA1-short ]  " "${c[blue2]}${image_git_sha1_short}" "${c[end]}"
echo -e

# #
#   finish
# #

printf '%-29s %-65s\n' "  ${c[bluel]}${app_file_this}${c[end]}" "${c[greenl]}Finished build ${c[end]}"
echo -e

# #
#   restart container
#       only activates if -ra, --restart parameter specified
# #

if [ "${image_restart}" = true ]; then
    if alias docker-restart >/dev/null 2>&1; then
        docker-restart
    else
        if command -v bws >/dev/null 2>&1; then
            bws run -- "docker compose ${restart_env_out} down --remove-orphans && docker compose ${restart_env_out} up -d"
        elif command -v docker >/dev/null 2>&1; then
            docker compose ${restart_env_out} down --remove-orphans && \
            docker compose ${restart_env_out} up -d
        else
            echo
            echo -e "  ${c[bold]}${c[redl]}ERROR            ${c[end]}Cannot restart container${c[end]}"
            echo -e "  ${c[end]}                 Could not find docker command or docker aliases${c[end]}"
            echo -e "  ${c[bold]}${c[grey2]}                         ${c[fuchsia2]}./${app_file_this}${c[end]} --help"
            echo -e "  ${c[bold]}${c[grey2]}                         ${c[fuchsia2]}./${app_file_this}${c[end]} -h"
            echo
        fi
    fi
fi

