#!/usr/bin/env bash

scriptName=$(basename $0)
scriptPath="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
appName="${scriptName%.*}"
sourcesList=".sourcesList"
gitFolder="/backup/git"
rsyncFlags="-D --numeric-ids --copy-links -keep-dirlinks --hard-links --itemize-changes --times --recursive --perms --owner --group --stats --human-readable --del --relative --ignore-errors --prune-empty-dirs"
separatoString="------------"

dryRun=""
[ -n ${1} ] && [[ ${1} = "--dry-run" ]] && dryRun="--dry-run"
#dryRun="--dry-run"

[[ -f "${scriptPath}/.config" ]] && source ${scriptPath}/.config

logger="logger -s -t ${appName}"

exec_command() {
    local execCmd="$1"
    local execOut=""
    echo -e "${separatoString}\n${execCmd}\n${separatoString}" | ${logger} 
    execOut=$(eval ${execCmd})
    local execStatus=$?
    [[ -n "${execOut}" ]] && echo "${execOut}" | ${logger}
    return ${execStatus}
}


rsyncCmd="rsync ${dryRun}"
rsyncCmd="${rsyncCmd} ${rsyncFlags}"

[[ -f "${gitFolder}/.gitignore" ]] && rsyncCmd="${rsyncCmd} --exclude-from=${gitFolder}/.gitignore"
[[ -f "${gitFolder}/.rsyncignore" ]] && rsyncCmd="${rsyncCmd} --exclude-from=${gitFolder}/.rsyncignore"
[[ -f "${gitFolder}/.rsyncFilters" ]] && rsyncCmd="${rsyncCmd} --filter='merge ${gitFolder}/.rsyncFilters'"

[[ -f "${gitFolder}/${sourcesList}" ]] || { echo "No ${sourcesList} in ${gitFolder}/ !" | ${logger}; exit 1; }
while read sourceFolder; do
    rsyncCmd="${rsyncCmd} ${sourceFolder}"
done < ${gitFolder}/${sourcesList}

rsyncCmd="$rsyncCmd ${gitFolder}"
rsyncStatus=$?

exec_command "${rsyncCmd}"

cd ${gitFolder}
[[ $(pwd) == ${gitFolder} ]] || exit 1

gitCmd="git add ${dryRun} . 2>&1"

exec_command "${gitCmd}"

gitCmd="git diff --numstat --cached --exit-code  2>&1"
exec_command "${gitCmd}"
diffStatus=$?

if ((${diffStatus})); then
    commitMessage="$(hostname) $(date)"
    gitCmd="git commit ${dryRun} --all -m \"$(hostname) $(date +'%Y-%m-%d %H:%M:%S %Z')\" 2>&1"
    exec_command "${gitCmd}"
    commitStatus=$?
    if ! ((${commitStatus})); then
        gitCmd="git push ${dryRun} origin master"
        exec_command "${gitCmd}"
    fi
fi
