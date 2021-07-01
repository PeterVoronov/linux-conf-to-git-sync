#!/usr/bin/env bash

scriptName="$(basename $0)"
scriptPath="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
#echo ${scriptPath}
#echo $(pwd)
appName="${scriptName%.*}"
hardLinked=("rsync_git.sh" ".rsyncFilters" ".sourcesList" ".config")
isHardLinked=()
gitFolder="/backup/git"
separatoString="------------"
#dryRun="--dry-run"
dryRun=""

logger="logger -s -t ${appName}"

check_hard_link() {
    local fileName="${scriptPath}/${1}"
    local linkedName="${gitFolder}/${1}"
    local execStatus
    #echo -e "${separatoString}\n${execCmd}\n${separatoString}" | ${logger} 
    local execOut=$(find ${linkedName}  -samefile $fileName -print -quit)
    execStatus=$?
    [[ -n "${execOut}" ]] && echo "Hard link for ${fileName} is found - ${execOut}" | ${logger}
    [[ "${execOut}" = "${linkedName}" ]]
    return 
}


for hardLink in ${hardLinked[@]}; do
    if check_hard_link ${hardLink}; then
        isHardLinked+=("yes")
    else
        isHardLinked+=("no")
    fi
done

git checkout master
git fetch origin  || { echo "Can't fetch! Exiting ..."  | ${logger}; exit 1 ; }
git diff --exit-code --no-patch master origin/master || git merge origin/master || { git merge --abort; echo "Can't merge. Exiting ..."  | ${logger}; exit 1 ; }

for iHardLink in ${!hardLinked[@]}; do
    echo "${iHardLink} ${isHardLinked[$iHardLink]}  ${hardLinked[$iHardLink]}"
    if [[ "${isHardLinked[${iHardLink}]}" = "yes" ]]; then
        if check_hard_link ${hardLinked[$iHardLink]}; then
            echo "Hard link for ${hardLinked[$iHardLink]} is Ok!" | ${logger}
        else
            echo "Hard link for ${hardLinked[$iHardLink]} is broken!" | ${logger}
            [[ -f "${gitFolder}/${hardLinked[$iHardLink]}" ]] && rm ${gitFolder}/${hardLinked[$iHardLink]}
            execOut=$(link ${scriptPath}/${hardLinked[$iHardLink]} ${gitFolder}/${hardLinked[$iHardLink]})
            harLinkStatus=$?
            if !((${harLinkStatus})); then
                echo "Hard link is fixed! With result ${execOut}" | ${logger}
            else
                echo "Can't fix! With result ${execOut}" | ${logger}
            fi
        fi
    else
        if ! [[ -f "${gitFolder}/${hardLinked[$iHardLink]}" ]]; then
            echo "No file in ${gitFolder} for ${hardLinked[$iHardLink]} is exists! Will hardlink it" | ${logger}
            execOut=$(link ${scriptPath}/${hardLinked[$iHardLink]} ${gitFolder}/${hardLinked[$iHardLink]})
            harLinkStatus=$?
            if !((${harLinkStatus})); then
                echo "Hard link is created, with result ${execOut}" | ${logger}
            else
                echo "Can't create hardlink! With result ${execOut}" | ${logger}
            fi
        fi
    fi
done


