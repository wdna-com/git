#!/bin/bash

# Colors
RED='\033[0;31m'
ORANGE='\033[0;91m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SEPARATOR1="******************************************************************************************"
SEPARATOR2="------------------------------------------------------------------------------------------"
SEPARATOR3="##########################################################################################"

INFO="INFO"
ERROR="ERRO"
WARNING="WARN"
SUCCESS="INFO"

REDMINE_URL="https://redmine.wdna.com"

# check if the required packages are installed
SET_PKG="git git-flow xmlstarlet curl"
CHK_PKG=$(dpkg-query --show ${SET_PKG} &> /dev/null ; echo $?)
if [ "${CHK_PKG}" == "1" ]
then
    echo -e "- [${RED}${ERROR}${NC}]: Required packages are not installed, please install them using the following command:" > /dev/stderr
    echo -e "  ${YELLOW}sudo apt install ${SET_PKG}${NC}"
    exit 1
fi
# Check if git is initialized
if [ ! -d ".git" ]
then
    echo -e "- [${RED}${ERROR}${NC}]: This directory is not a git repository, please initialize it using the following command:" > /dev/stderr
    echo -e "  ${YELLOW}git init${NC}"
    exit 1
fi
# Check if develop is a branch
EXIST_DEVELOP_LOCAL=$(git branch --list develop)
EXIST_DEVELOP_REMOTE=$(git ls-remote --heads origin develop)
# -n => check if string is not empty
# -z => check if string is empty
if [ -n "${EXIST_DEVELOP_LOCAL}" ] && [ -n "${EXIST_DEVELOP_REMOTE}" ]
then
    echo -e "- [${GREEN}${SUCCESS}${NC}]: Remote branch [${YELLOW}develop${NC}] found. ✅"
    echo -e "- [${GREEN}${SUCCESS}${NC}]: Local branch [${YELLOW}develop${NC}] found. ✅"
elif [ -z "${EXIST_DEVELOP_LOCAL}" ] && [ -z "${EXIST_DEVELOP_REMOTE}" ]
then
    echo -e "- [${RED}${ERROR}${NC}]: Local and remote branch [${YELLOW}develop${NC}] not found." > /dev/stderr
    echo -e "- [${RED}${ERROR}${NC}]: Please create a [${YELLOW}develop${NC}] branch using the following command: [${YELLOW}git checkout -b develop${NC}]" > /dev/stderr
    echo -e "- [${RED}${ERROR}${NC}]: Please push the [${YELLOW}develop${NC}] branch to remote repository using the following command: [${YELLOW}git push origin develop${NC}]" > /dev/stderr
    exit 1
elif [ -z "${EXIST_DEVELOP_LOCAL}" ]
then
    echo -e "- [${RED}${ERROR}${NC}]: Local branch [${YELLOW}develop${NC}] not found." > /dev/stderr
    echo -e "- [${RED}${ERROR}${NC}]: Please get the [${YELLOW}develop${NC}] branch from remote repository using the following command: [${YELLOW}git checkout develop${NC}]" > /dev/stderr
    exit 1
elif [ -z "${EXIST_DEVELOP_REMOTE}" ]
then
    echo -e "- [${RED}${ERROR}${NC}]: Remote branch [${YELLOW}develop${NC}] not found." > /dev/stderr
    echo -e "- [${RED}${ERROR}${NC}]: Please push the [${YELLOW}develop${NC}] branch to remote repository using the following command: [${YELLOW}git push origin develop${NC}]" > /dev/stderr
    exit 1
fi

# Check if master or main is a branch
EXIST_MASTER_REMOTE=$(git ls-remote --heads origin master)
EXIST_MAIN_REMOTE=$(git ls-remote --heads origin main)
# -n => check if string is not empty
# -z => check if string is empty
if [ -n "${EXIST_MASTER_REMOTE}" ] && [ -n "${EXIST_MAIN_REMOTE}" ]
then
    echo -e "- [${RED}${ERROR}${NC}]: Remote branches [${YELLOW}master${NC}] and [${YELLOW}main${NC}] found at the same time. Please remove one of them." > /dev/stderr 
    exit 1
elif [ -z "${EXIST_MAIN_REMOTE}" ] && [ -z "${EXIST_MASTER_REMOTE}" ]
then
    echo -e "- [${RED}${ERROR}${NC}]: Remote branch [${YELLOW}main${NC}] not found. Please create a [${YELLOW}main${NC}] branch in remote repository." > /dev/stderr
    exit 1
elif [ -n "${EXIST_MAIN_REMOTE}" ]
then
    BRANCH_MAIN="main"
elif [ -n "${EXIST_MASTER_REMOTE}" ]
then
    BRANCH_MAIN="master"
fi

echo -e "- [${GREEN}${SUCCESS}${NC}]: Remote branch [${YELLOW}${BRANCH_MAIN}${NC}] found. ✅"

EXIST_MAIN_LOCAL=$(git branch --list "${BRANCH_MAIN}")
if [ -z "${EXIST_MAIN_LOCAL}" ]
then
    echo -e "- [${RED}${ERROR}${NC}]: Local branch [${YELLOW}${BRANCH_MAIN}${NC}] not found." > /dev/stderr
    echo -e "- [${RED}${ERROR}${NC}]: Please get the [${YELLOW}${BRANCH_MAIN}${NC}] branch from remote repository using the following command: [${YELLOW}git checkout ${BRANCH_MAIN}${NC}]" > /dev/stderr
    exit 1
fi

echo -e "- [${GREEN}${SUCCESS}${NC}]: Local branch [${YELLOW}${BRANCH_MAIN}${NC}] found. ✅"

# Check if git-flow is initialized
if [ ! -f .git/config ] || [ -z "$(grep '\[gitflow "branch"\]' .git/config)" ]
then
    echo -e "- [${RED}${ERROR}${NC}]: GitFlow is not initialized" > /dev/stderr
    echo -e "- [${RED}${ERROR}${NC}]: Please initialize GitFlow using the following command: [${YELLOW}git flow init${NC}]" > /dev/stderr
    exit 1
fi

echo -e "- [${GREEN}${SUCCESS}${NC}]: GitFlow is initialized 👌."

is_clean() {
    if [ -n "$(git status --porcelain)" ]
    then
        echo -e "- [${RED}${ERROR}${NC}]: You have uncommitted changes, please commit or stash them before continue"  > /dev/stderr
        _git_status
        exit 1
    fi
}

write_changelog() {
    echo -e "$1" >> CHANGELOG.tmp
}

# Main menu
main_menu() {
    echo -e "${SEPARATOR1}"
    echo -e "${GREEN}Current branch: ${YELLOW}$(git branch --show-current)${NC} 👀"
    echo -e "${SEPARATOR1}"
    echo -e "${GREEN}Select an action:${NC}"
    echo -e "${YELLOW}1) Git Actions${NC}"
    echo -e "${YELLOW}2) GitFlow Actions${NC}"
    echo -e "${YELLOW}q) Quit${NC}"
    echo -e "${SEPARATOR1}"
    read -p "$(echo -e ${BLUE}Enter your choice: ${NC})" choice

    case $choice in
        1) git_actions ;;
        2) gitflow_actions ;;
        q) exit 0 ;;
        *) echo -e "${SEPARATOR3}" && echo -e "${RED}Invalid choice:${NC}[${YELLOW}${choice}${NC}]\n${RED}Please try again.${NC}" && echo -e "${SEPARATOR3}" && main_menu ;;
    esac
}

_git_status() {
    echo -e "${SEPARATOR2}"
    git status --long --branch --show-stash
    echo -e "${SEPARATOR2}"
    exit 0
}

_git_log() {
    echo -e "${SEPARATOR2}"
    git log --graph \
            --all \
            --decorate \
            --oneline \
            --abbrev-commit \
            --date=relative \
            --color=always \
            --format=format:'%C(bold blue)%h%C(reset) %C(bold yellow)%d%C(reset) %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)'
    echo ""
    exit 0
}

_git_pull() {
    echo -e "${SEPARATOR2}"
    if [ -n "$(git status --porcelain)" ]
    then
        echo -e "${SEPARATOR3}"
        read -p "$(echo -e ${BLUE}You have uncommitted changes. Do you want to stash them? [y/N]: ${NC})" stash_choice
        if [[ "$stash_choice" =~ ^[Yy]$ ]]
        then
            git stash push -m "[TMP] `date +'%Y-%m-%d %H:%M:%S'`"
            STASHED=true
        else
            echo -e "- [${RED}${ERROR}${NC}]: Please commit or stash your changes before continuing." > /dev/stderr
            echo -e "${SEPARATOR3}"
            exit 1
        fi
        echo -e "${SEPARATOR3}"
    else
        STASHED=false
    fi

    git fetch --all
    for branch in $(git branch --format='%(refname:short)')
    do
        if git ls-remote --exit-code --heads origin "$branch" &>/dev/null
        then
            echo -e "- [${YELLOW}${INFO}${NC}]: Pulling changes from [${YELLOW}${branch}${NC}] branch..."
            git pull origin "$branch" -q
        else
            echo -e "- [${RED}${ERROR}${NC}]: Remote branch [${YELLOW}${branch}${NC}] not found. Please check your remote repository." > /dev/stderr
        fi
    done

    __git_stash_end "${STASHED}"
    echo -e "- [${GREEN}${SUCCESS}${NC}]: Changes pulled successfully."
    echo -e "${SEPARATOR2}"
    exit 0
}


__git_stash_end() {
    STASHED=$1
    if [ "${STASHED}" == "true" ]
    then
        echo -e "${SEPARATOR3}"
        read -p "$(echo -e ${BLUE}Do you want to apply the stashed changes? [y/N]: ${NC})" apply_choice
        if [[ "$apply_choice" =~ ^[Yy]$ ]]
        then
            echo -e "- [${YELLOW}${INFO}${NC}]: Applying stashed changes..."
            git stash pop
        else
            echo -e "- [${YELLOW}${INFO}${NC}]: Stashed changes are not applied."
        fi
        echo -e "${SEPARATOR3}"
    fi
}

_git_checkout() {

    echo -e "${SEPARATOR2}"
    if [ -n "$(git status --porcelain)" ]
    then
        echo -e "${SEPARATOR3}"
        read -p "$(echo -e ${BLUE}You have uncommitted changes. Do you want to stash them? [y/N]: ${NC})" stash_choice
        if [[ "$stash_choice" =~ ^[Yy]$ ]]
        then
            git stash push -m "[TMP] `date +'%Y-%m-%d %H:%M:%S'`"
            STASHED=true
        else
            echo -e "- [${RED}${ERROR}${NC}]: Please commit or stash your changes before continuing." > /dev/stderr > /dev/stderr
            echo -e "${SEPARATOR3}"
            exit 1
        fi
        echo -e "${SEPARATOR3}"
    else
        STASHED=false
    fi

    echo -e "${GREEN}Select a branch to checkout:${NC}"
    git branch -a | grep -v HEAD | cut -d'*' -f2- | sed -e 's/^[[:space:]]*//' | sed -e 's/[[:space:]]*$//' | cat -n
    read -p "$(echo -e ${BLUE}Enter your choice: ${NC})" choice
    if [ -n "${choice}" ]
    then
        branch=$(git branch -a | grep -v HEAD | cut -d'*' -f2- | sed -e 's/^[[:space:]]*//' | sed -n "${choice}p")
        # remove remote/origin
        branch=$(echo "${branch}" | sed 's/remotes\/origin\///')
        # check if branch exists in local
        if [ -z "$(git branch --list "${branch}")" ]
        then
            # check if branch exists in remote
            if [ -z "$(git ls-remote --heads origin "${branch}")" ]
            then
                echo -e "- [${RED}${ERROR}${NC}]: Branch [${YELLOW}${branch}${NC}] not found in local or remote repository." > /dev/stderr
                __git_stash_end "${STASHED}"
                exit 1
            else
                echo -e "- [${YELLOW}${INFO}${NC}]: Branch [${YELLOW}${branch}${NC}] found in remote repository, checking out..."
                git checkout -b "${branch}" "origin/${branch}"
                echo -e "- [${GREEN}${SUCCESS}${NC}]: Branch [${YELLOW}${branch}${NC}] checked out successfully."
            fi
        else
            echo -e "- [${YELLOW}${INFO}${NC}]: Branch [${YELLOW}${branch}${NC}] found in local repository, checking out..."
            git checkout "${branch}"
            echo -e "- [${GREEN}${SUCCESS}${NC}]: Branch [${YELLOW}${branch}${NC}] checked out successfully."
        fi
    else
        echo "${choice}"
        echo -e "- [${RED}${ERROR}${NC}]: Invalid choice, please try again." > /dev/stderr
        __git_stash_end "${STASHED}"
        _git_checkout
    fi
    __git_stash_end "${STASHED}"
    echo -e "${SEPARATOR2}"
}


# Git actions menu
git_actions() {
    echo -e "${SEPARATOR1}"
    echo -e "${GREEN}Select a Git action:${NC}"
    echo -e "${YELLOW}1) Status${NC}............(show the working tree status)"
    echo -e "${YELLOW}2) log${NC}...............(show the commit logs)"
    echo -e "${YELLOW}3) Pull${NC}..............(fetch from and integrate with another repository or a local branch)"
    echo -e "${YELLOW}4) Checkout${NC}..........(switch branches or restore working tree files)"
    echo -e "${YELLOW}b) Back to main menu${NC}.(return to the main menu)"
    echo -e "${SEPARATOR1}"
    read -p "$(echo -e ${BLUE}Enter your choice: ${NC})" choice

    case $choice in
        1) _git_status || exit 1 ;;
        2) _git_log ||  exit 1 ;;
        3) _git_pull || exit 1 ;;
        4) _git_checkout || exit 1 ;;
        b) main_menu ;;
        *) echo -e "${SEPARATOR3}" && echo -e "${RED}Invalid choice:${NC}[${YELLOW}${choice}${NC}]\n${RED}Please try again.${NC}" && echo -e "${SEPARATOR3}" && git_actions ;;
    esac
}

# GitFlow actions menu

_gitflow_start_feature() {

    echo -e "${SEPARATOR2}"

    is_clean || exit 1

    if [ "$(git branch --show-current)" != "develop" ]
    then
        echo -e "- [${RED}${ERROR}${NC}]: You must be on the [${YELLOW}develop${NC}] branch to start a feature." > /dev/stderr
        exit 1
    fi
    echo -e "- [${YELLOW}${INFO}${NC}]: Pulling latest changes from [${YELLOW}develop${NC}] branch..."
    git pull origin develop -q
    echo -e "- [${YELLOW}${INFO}${NC}]: Creating a new feature branch..." 
    read -rp "$(echo -e ${BLUE}Enter feature number: ${NC})" FEATURE_NUMBER
    if [ -z "${FEATURE_NUMBER}" ]
    then
        echo -e "- [${RED}${ERROR}${NC}]: Feature number cannot be empty" > /dev/stderr
        exit 1
    elif  [[ ! "${FEATURE_NUMBER}" =~ ^[0-9]+$ ]]
    then
        echo -e "- [${RED}${ERROR}${NC}]: Feature number must be a number" > /dev/stderr
        exit 1
    else
        echo -e "- [${YELLOW}${INFO}${NC}]: Creating a new feature branch  [${YELLOW}feature/#${FEATURE_NUMBER}${NC}] from [${YELLOW}develop${NC}] branch..." 
        git flow feature start "#${FEATURE_NUMBER}" > /dev/null
        echo -e "- [${YELLOW}${INFO}${NC}]: Pushing the new feature branch [${YELLOW}feature/#${FEATURE_NUMBER}${NC}] to remote repository..."
        git flow feature publish "#${FEATURE_NUMBER}" > /dev/null
        echo -e "- [${GREEN}${SUCCESS}${NC}]: Feature branch [${YELLOW}feature/#${FEATURE_NUMBER}${NC}] created and pushed successfully."
    fi
    echo -e "${SEPARATOR2}"
    exit 0
}

_gitflow_finish_feature() {

    echo -e "${SEPARATOR2}"
    is_clean || exit 1

    if [[ "$(git branch --show-current)" != feature/#* ]]
    then
        echo -e "- [${RED}${ERROR}${NC}]: You must be on a feature branch to finish a feature." > /dev/stderr
        exit 1
    fi
    local old_branch
    old_branch=$(git branch --show-current)
    echo -e "- [${YELLOW}${INFO}${NC}]: Changing to [${YELLOW}develop${NC}] branch..."
    git checkout develop -q
    echo -e "- [${YELLOW}${INFO}${NC}]: Pulling latest changes from [${YELLOW}develop${NC}] branch..."
    git pull origin develop -q
    echo -e "- [${YELLOW}${INFO}${NC}]: Changing to [${YELLOW}${old_branch}${NC}] branch..."
    git checkout "${old_branch}" -q
    echo -e "- [${YELLOW}${INFO}${NC}]: Finishing the current feature branch..."
    # [GIT_MERGE_AUTOEDIT=no] for non interative release operation
    GIT_MERGE_AUTOEDIT=no git flow feature finish -m ""Merge branch 'feature/#${FEATURE_NUMBER}' into develop"" > /dev/null
    echo -e "- [${YELLOW}${INFO}${NC}]: Pushing changes to remote repository..."
    git push -q
    echo -e "- [${GREEN}${SUCCESS}${NC}]: Feature branch finished successfully."
    echo -e "${SEPARATOR2}"
    exit 0
}

_gitflow_start_release() {

    echo -e "${SEPARATOR2}"
    is_clean || exit 1

    if [ "$(git branch --show-current)" != "develop" ]
    then
        echo -e "- [${RED}${ERROR}${NC}]: You must be on the [${YELLOW}develop${NC}] branch to start a release." > /dev/stderr
        exit 1
    fi
    # Check if the user wants to start a new release
    read -rp "$(echo -e "- [${YELLOW}${INFO}${NC}]: Redmine API KEY (url: ${YELLOW}${REDMINE_URL}/my/account${NC}): ")" REDMINE_API_KEY
    if [ -z "${REDMINE_API_KEY}" ]
    then
        echo -e "- [${RED}${ERROR}${NC}]: Redmine API KEY cannot be empty" > /dev/stderr
        exit 1
    fi
    RESPONSE=$(curl -sb -H "Content-Type: application/xml" -H "X-Redmine-API-Key: ${REDMINE_API_KEY}" "${REDMINE_URL}/issues.xml?limit=1")
     if [ -n "${RESPONSE}" ]
     then
        echo -e "- [${YELLOW}${INFO}${NC}]: Redmine API KEY is valid"
    else
        echo -e "- [${RED}${ERROR}${NC}]: Redmine API KEY is invalid" > /dev/stderr
        exit 1
    fi

    local version_old
    version_old=$(git tag --sort=v:refname | tail -1)
    if [ -z "${version_old}" ]
    then
        version_old="0.0.0"
    fi
    read -rp "$(echo -e "- ${YELLOW}${INFO}${NC}: Enter new release version (current version: ${YELLOW}${version_old}${NC}): ")" RELEASE_VERSION
    if [ -z "${RELEASE_VERSION}" ]
    then
        echo -e "- [${RED}${ERROR}${NC}]: Release version cannot be empty" > /dev/stderr
        exit 1
    elif  [[ ! "${RELEASE_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
    then
        echo -e "- [${RED}${ERROR}${NC}]: Release version must be in the format [${YELLOW}x.x.x${NC}]" > /dev/stderr
        exit 1
    else
        echo -e "- [${YELLOW}${INFO}${NC}]: Pulling latest changes from [${YELLOW}${BRANCH_MAIN}${NC}] branch..."
        git pull origin "${BRANCH_MAIN}" -q
        echo -e "- [${YELLOW}${INFO}${NC}]: Pulling latest changes from [${YELLOW}develop${NC}] branch..."
        git pull origin develop -q
        echo -e "- [${YELLOW}${INFO}${NC}]: Creating a new release branch [${YELLOW}release/${RELEASE_VERSION}${NC}] from [${YELLOW}develop${NC}] branch..." 
        git flow release start "${RELEASE_VERSION}" > /dev/null
        if [ $? -ne 0 ]
        then
            echo -e "- [${RED}${ERROR}${NC}]: Release branch [${YELLOW}release/${RELEASE_VERSION}${NC}] failed to create" > /dev/stderr
            exit 1
        fi
        # Extract git feature codes (sorted and unique only)
        local feature_list
        feature_list=$(git log --pretty=oneline --no-decorate ${BRANCH_MAIN}..HEAD  | grep "Merge branch 'feature/#" | awk '{print $4}' | sed 's/feature\/#//')
        # Remove quotes 
        feature_list=$(echo "${feature_list}" | tr -d '"' | tr -d "'")
        # Sort feature codes by number
        feature_list=$(echo "${feature_list}" | sort -n | uniq)
        # convert to list
        feature_list=$(echo "${feature_list}" | tr '\n' '#')

         # Generating temporary changelog ************************
        local changelog_head changelog_tail
        changelog_head=$(head -8 CHANGELOG.md)
        changelog_tail=$(tail --lines=+10 CHANGELOG.md)
        echo -e "- [$YELLOW}INFO${NC}]: Generating temporary changelog..."
        rm -f CHANGELOG.tmp
        write_changelog "${changelog_head}"
        write_changelog ""

        # Add release version
        write_changelog "## [${RELEASE_VERSION}] - $(date +'%Y-%m-%d')"
        OLD_IFS=$IFS
        export IFS="#"
        for feature in ${feature_list}
        do
            if [ -n "${feature}" ]
            then
                local XML_RESPONSE
                XML_RESPONSE=$(curl -sb -H "Content-Type: application/xml" -H "X-Redmine-API-Key: ${REDMINE_API_KEY}" "${REDMINE_URL}/issues/${feature}.xml")
                if [ -n "${XML_RESPONSE}" ]
                then
                    local feature_title
                    feature_title=$(xmlstarlet select -t -v "//issue/subject/text()" <<< "${XML_RESPONSE}")
                    echo -e "- [${YELLOW}${INFO}${NC}]: Adding feature [${YELLOW}#${feature}${NC}] to changelog..."
                    write_changelog "- ${feature} - ${feature_title}"
                else
                    echo -e "- [${RED}${ERROR}${NC}]: Feature [${YELLOW}#${feature}${NC}] not found in Redmine or API KEY is invalid for this feature" > /dev/stderr
                    read -n 1 -r -s -p "$(echo -e ${BLUE}Do you want to continue? [y/N]: ${NC})" CONTINUE
                    echo ""
                    if [ "${CONTINUE}" != "y" ] && [ "${CONTINUE}" != "Y" ]
                    then
                        echo -e "- [${RED}${ERROR}${NC}]: Release branch [${YELLOW}release/${RELEASE_VERSION}${NC}] failed to create" > /dev/stderr
                        exit 1
                    fi
                fi
            fi
        done
        export IFS=$OLD_IFS
        write_changelog ""
        write_changelog "${changelog_tail}"
        # Replace main changelog with tmp
        mv CHANGELOG.tmp CHANGELOG.md
        # Store version number in VERSION text file
        echo "${RELEASE_VERSION}" > VERSION

        echo -e "- [${YELLOW}${INFO}${NC}]: Committing changes to [${YELLOW}release/${RELEASE_VERSION}${NC}] branch..."
        git commit -am "Release version ${RELEASE_VERSION}" > /dev/null
        if [ $? -ne 0 ]
        then
            echo -e "- [${RED}${ERROR}${NC}]: Release branch [${YELLOW}release/${RELEASE_VERSION}${NC}] failed to commit changes" > /dev/stderr
            exit 1
        fi

        echo -e "- [${YELLOW}${INFO}${NC}]: Pushing the new release branch [${YELLOW}release/${RELEASE_VERSION}${NC}] to remote repository..."
        git flow release publish "${RELEASE_VERSION}" > /dev/null
        echo -e "- [${GREEN}${SUCCESS}${NC}]: Release branch [${YELLOW}release/${RELEASE_VERSION}${NC}] created and pushed successfully."
    fi
    echo -e "${SEPARATOR2}"
    exit 0
}


_gitflow_finish_release() {

    echo -e "${SEPARATOR2}"
    is_clean || exit 1

    if [[ "$(git branch --show-current)" != release/*.*.* ]]
    then
        echo -e "- [${RED}${ERROR}${NC}]: You must be on a release branch to finish a release." > /dev/stderr
        exit 1
    fi
    local RELEASE_VERSION
    RELEASE_VERSION=$(git branch --show-current | grep -oP '\d+\.\d+\.\d+')
    echo -e "- [${YELLOW}${INFO}${NC}]: Pulling latest changes from [${YELLOW}${BRANCH_MAIN}${NC}] branch..."
    git pull origin "${BRANCH_MAIN}" -q
    echo -e "- [${YELLOW}${INFO}${NC}]: Pulling latest changes from [${YELLOW}develop${NC}] branch..."
    git pull origin develop -q
    echo -e "- [${YELLOW}${INFO}${NC}]: Finishing the current release branch..."
    # [GIT_MERGE_AUTOEDIT=no] for non interative release operation
    GIT_MERGE_AUTOEDIT=no git flow release finish -m "Release version ${RELEASE_VERSION}" > /dev/null
    echo -e "- [${YELLOW}${INFO}${NC}]: Pushing changes to remote [${YELLOW}${BRANCH_MAIN}${NC}] branch..."
    git push origin "${BRANCH_MAIN}" -q
    echo -e "- [${YELLOW}${INFO}${NC}]: Pushing changes to remote [${YELLOW}develop${NC}] branch..."
    git push origin develop -q
    echo -e "- [${GREEN}${SUCCESS}${NC}]: Release branch finished successfully."
    # Push new tag to remote
    echo -e "- [${YELLOW}${INFO}${NC}]: Pushing new tag [${YELLOW}${RELEASE_VERSION}${NC}] to remote repository..."
    git push origin "${RELEASE_VERSION}" -q
    echo -e "${SEPARATOR2}"
    exit 0
}


_gitflow_start_hotfix() {
    echo -e "${SEPARATOR2}"
    is_clean || exit 1

    if [ "$(git branch --show-current)" != "${BRANCH_MAIN}" ]
    then
        echo -e "- [${RED}${ERROR}${NC}]: You must be on the [${YELLOW}${BRANCH_MAIN}${NC}] branch to start a hotfix." > /dev/stderr
        exit 1
    fi

    local version_old
    version_old=$(git tag --sort=v:refname | tail -1)
    if [ -z "${version_old}" ]
    then
        version_old="0.0.0"
    fi
    read -rp "$(echo -e "- ${YELLOW}${INFO}${NC}: Enter new hotfix version (current version: ${YELLOW}${version_old}${NC}): ")" HOTFIX_VERSION
    if [ -z "${HOTFIX_VERSION}" ]
    then
        echo -e "- [${RED}${ERROR}${NC}]: Hotfix version cannot be empty" > /dev/stderr
        exit 1
    elif  [[ ! "${HOTFIX_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
    then
        echo -e "- [${RED}${ERROR}${NC}]: Hotfix version must be in the format [${YELLOW}x.x.x${NC}]" > /dev/stderr
        exit 1
    else
        echo -e "- [${YELLOW}${INFO}${NC}]: Pulling latest changes from [${YELLOW}${BRANCH_MAIN}${NC}] branch..."
        git pull origin "${BRANCH_MAIN}" -q
        echo -e "- [${YELLOW}${INFO}${NC}]: Pulling latest changes from [${YELLOW}develop${NC}] branch..."
        git pull origin develop -q

        echo -e "- [${YELLOW}${INFO}${NC}]: Creating a new hotfix branch  [${YELLOW}hotfix/${HOTFIX_VERSION}${NC}] from [${YELLOW}${BRANCH_MAIN}${NC}] branch..." 
        git flow hotfix start "${HOTFIX_VERSION}" > /dev/null
        if [ $? -ne 0 ]
        then
            echo -e "- [${RED}${ERROR}${NC}]: Hotfix branch [${YELLOW}hotfix/${HOTFIX_VERSION}${NC}] failed to create" > /dev/stderr
            exit 1
        fi
        # Store version number in VERSION text file
        echo "${HOTFIX_VERSION}" > VERSION
         # Commit last changes
        echo -e "- [${YELLOW}${INFO}${NC}]: Committing changes to [${YELLOW}hotfix/${HOTFIX_VERSION}${NC}] branch..."
        git commit -am "Hotfix version ${HOTFIX_VERSION}" > /dev/null
        if [ $? -ne 0 ]
        then
            echo -e "- [${RED}${ERROR}${NC}]: Hotfix branch [${YELLOW}hotfix/${HOTFIX_VERSION}${NC}] failed to commit changes" > /dev/stderr
            exit 1
        fi
        echo -e "- [${YELLOW}${INFO}${NC}]: Pushing the new hotfix branch [${YELLOW}hotfix/${HOTFIX_VERSION}${NC}] to remote repository..."
        git flow hotfix publish "${HOTFIX_VERSION}" > /dev/null
        echo -e "- [${GREEN}${SUCCESS}${NC}]: Hotfix branch [${YELLOW}hotfix/${HOTFIX_VERSION}${NC}] created and pushed successfully."
    fi
    echo -e "${SEPARATOR2}"
    exit 0
}

_gitflow_finish_hotfix() {
    echo -e "${SEPARATOR2}"
    is_clean || exit 1

    if [[ "$(git branch --show-current)" != hotfix/*.*.* ]]
    then
        echo -e "- [${RED}${ERROR}${NC}]: You must be on a hotfix branch to finish a hotfix." > /dev/stderr
        exit 1
    fi
    echo -e "- [${YELLOW}${INFO}${NC}]: Pulling latest changes from [${YELLOW}${BRANCH_MAIN}${NC}] branch..."
    git pull origin "${BRANCH_MAIN}" -q
    echo -e "- [${YELLOW}${INFO}${NC}]: Pulling latest changes from [${YELLOW}develop${NC}] branch..."
    git pull origin develop -q
    local HOTFIX_VERSION
    HOTFIX_VERSION=$(git branch --show-current | grep -oP '\d+\.\d+\.\d+')
    # Generating temporary changelog ************************
    local changelog_head changelog_tail
    changelog_head=$(head -8 CHANGELOG.md)
    changelog_tail=$(tail --lines=+10 CHANGELOG.md)
    echo -e "- [$YELLOW}INFO${NC}]: Generating temporary changelog..."
    rm -f CHANGELOG.tmp
    write_changelog "${changelog_head}"
    write_changelog ""

    # Extract git commit comments (sorted and unique only)
    local commit_list=$(git log --no-merges --reverse --first-parent "${BRANCH_MAIN}..HEAD" --pretty=oneline --abbrev-commit --no-decorate --grep='\[.*\]' | sort -u)
    write_changelog "## [${HOTFIX_VERSION}] - $(date +'%Y-%m-%d')"
    OLD_IFS=$IFS
    export IFS=$'\n'
    for commit in ${commit_list}
    do
        if [ -n "${commit}" ]
        then
            echo -e "- [${YELLOW}${INFO}${NC}]: Adding commit [${YELLOW}${commit}${NC}] to changelog..."
            write_changelog "- HOTFIX: ${commit}"
        fi
    done
    export IFS=$OLD_IFS
    write_changelog ""
    write_changelog "${changelog_tail}"
    # Replace main changelog with tmp
    mv CHANGELOG.tmp CHANGELOG.md
    # Commit changes
    echo -e "- [${YELLOW}${INFO}${NC}]: Committing changes to [${YELLOW}hotfix/${HOTFIX_VERSION}${NC}] branch..."
    git commit -am "Hotfix version ${HOTFIX_VERSION}" > /dev/null
    if [ $? -ne 0 ]
    then
        echo -e "- [${RED}${ERROR}${NC}]: Hotfix branch [${YELLOW}hotfix/${HOTFIX_VERSION}${NC}] failed to commit changes" > /dev/stderr
        exit 1
    fi
    # Finish the new release version with git-flow ***********
    # [GIT_MERGE_AUTOEDIT=no] for non interative release operation
    echo -e "- [${YELLOW}${INFO}${NC}]: Finishing the current hotfix branch..."
    GIT_MERGE_AUTOEDIT=no git flow hotfix finish -m "Hotfix version ${HOTFIX_VERSION}" > /dev/null
    echo -e "- [${YELLOW}${INFO}${NC}]: Pushing changes to remote [${YELLOW}${BRANCH_MAIN}${NC}] branch..."
    git push origin "${BRANCH_MAIN}" -q
    echo -e "- [${YELLOW}${INFO}${NC}]: Pushing changes to remote [${YELLOW}develop${NC}] branch..."
    git push origin develop -q
    # Push new tag to remote
    echo -e "- [${YELLOW}${INFO}${NC}]: Pushing new tag [${YELLOW}${HOTFIX_VERSION}${NC}] to remote repository..."
    git push origin "${HOTFIX_VERSION}" -q
    echo -e "- [${GREEN}${SUCCESS}${NC}]: Hotfix branch finished successfully."
    echo -e "${SEPARATOR2}"
    exit 0
}

gitflow_actions() {
    echo -e "${SEPARATOR1}"
    echo -e "${GREEN}Select a GitFlow action:${NC}"
    echo -e "${YELLOW}1) Start Feature${NC}..........(create a new feature branch)"
    echo -e "${YELLOW}2) Finish Feature${NC}.........(finish a feature branch)"
    echo -e "${YELLOW}3) Start Release${NC}..........(create a new release branch)"
    echo -e "${YELLOW}4) Finish Release${NC}.........(finish a release branch)"
    echo -e "${YELLOW}5) Start Hotfix${NC}...........(create a new hotfix branch)"
    echo -e "${YELLOW}6) Finish Hotfix${NC}..........(finish a hotfix branch)"
    echo -e "${YELLOW}b) Back to main menu${NC}......(return to the main menu)"
    echo -e "${SEPARATOR1}"
    read -p "$(echo -e ${BLUE}Enter your choice: ${NC})" choice

    case $choice in
        1) _gitflow_start_feature || exit 1 ;;
        2) _gitflow_finish_feature || exit 1 ;;
        3) _gitflow_start_release || exit 1 ;;
        4) _gitflow_finish_release || exit 1 ;;
        5) _gitflow_start_hotfix || exit 1 ;;
        6) _gitflow_finish_hotfix || exit 1 ;;
        b) main_menu ;;
        *) echo -e "${SEPARATOR3}" && echo -e "${RED}Invalid choice:${NC}[${YELLOW}${choice}${NC}]\n${RED}Please try again.${NC}" && echo -e "${SEPARATOR3}" && gitflow_actions ;;
    esac
}

check_changelog() {
    if [ ! -f CHANGELOG.md ]
    then
        echo -e "- [${RED}${ERROR}${NC}]: Changelog file [${YELLOW}CHANGELOG.md${NC}] not found." > /dev/stderr
        exit 1
    fi
}

check_version() {
    if [ ! -f VERSION ]
    then
        echo -e "- [${RED}${ERROR}${NC}]: Version file [${YELLOW}VERSION${NC}] not found." > /dev/stderr
        exit 1
    fi
}

check_changelog || exit 1
check_version || exit 1
# Start the script
main_menu