
function open_all() {
  for f in $*; do
    xdg-open ${f}* &>/dev/null
    while [ $(pgrep -af "eog.*${f}" | wc -l) -ne "0" ]; do
      :
    done
  done
}

ALIAS_DIR="${HOME}/git-repos/commando/gnu-linux"
pushalias() {
 cp ${HOME}/.bash_aliases "$ALIAS_DIR"
 pdir="$(pwd)"
 cd "$ALIAS_DIR"
 git add .bash_aliases
 git commit -m "$1" && git push
 cd "$pdir"
}

# follow specific file through git history
function gitfollow() {
  file_path="$1"
  succ=HEAD
  first=y
  echo "q to quit, any other key to continue"
  for commit in $(git log --oneline --follow -- $file_path | cut -f1 -d' '); do
    [ $first == 'y' ] && first=n && continue
    echo "showing diff between $commit (older) and $succ (newer)"
    git diff --color=always ${commit}:${file_path} ${succ}:${file_path} | less -R
    succ=$commit
    read; if [ "$REPLY" == "q" ]; then break; fi
  done
}
# track all remote branches in repo locally
function gitta() {
  matches=$(git branch -a | grep remote | grep -v HEAD | grep -v master)
  if [ ! -z "$1" ]; then
    matches=$(grep -i $1 <<< $matches)
  fi
  for i in $matches; do git branch --track ${i#remotes/origin/} $i 2>/dev/null; done
}
# delete remote branch by regex
function gitdrb() {
  for ex in $*; do
    match=$(gitbrregex $ex)
    match=${match// /}
    if [ -z "$match" ]; then
      echo "no match found for $ex"
      continue
    fi
    IFS=$'\n'
    for br in $match; do
      read -p "delete remote branch ${br}? (y/n) "
      if [ "$REPLY" = "y" ]; then
        git push -d origin "$br"
      fi
    done
  done
}
git_apply_dirty() {
  IFS=$'\n'
  for f in $(git diff --name-only HEAD && git ls-files -o --exclude-standard); do
    if [ -f "${f}" ]; then
      eval "$1" "$f"
    fi
  done
}

# SID
commitsid() {
  msg="$1"
  team="$(git rev-parse --abbrev-ref HEAD | cut -f 1 -d / | sed 's/\w/\u&/')"
  task="$(git rev-parse --abbrev-ref HEAD | cut -f 2 -d /)"
  git commit -m "${team} | ${task} | ${msg}"
}

getdbpassngx() {
  if [ -z "$1" ]; then
    echo "provide the ip address of the node"
    return 1  
  fi
  ip_add="$1"
  ssh -tt "$ip_add" <<- EOF
    sudo su - ngxuser
    echo dev3 | sstool -a VIEW_ALL --be | grep install.db
    exit
    exit
EOF
}
getdbpasstango() {
  if [ -z "$1" ]; then
    echo "provide the ip address of the node"
    return 1  
  fi
  ip_add="$1"
  ssh -tt "$ip_add" <<- EOF
    sudo su -
    echo dev3 | sstool -a VIEW_ALL | grep install.db
    exit
    exit
EOF
}

debugtunnel() {
  if [ -z "$1" ]; then
    echo "provide the ip address of the node"
    return 1  
  fi
  ip_add="$1"
  ssh -L 18098:${ip_add}:8098 -i ~/.ssh/azure_ops_dev3.pem azure-user@${ip_add} <<- EOF
    sudo su -
    sudo tail -f /var/log/rsa/securidaccess/ngx-be/ngx-be.log 
EOF
}

tangodb() {
  if [ -z "$1" ]; then
    echo "provide the ip address of the node"
    return 1  
  fi
  ip_add="$1"

  ssh -tt $ip_add > /tmp/tf <<- 'EOF1'
    sudo su -
    mysqlParameters=`echo rsa | sstool -a VIEW_ALL | grep -e install.db.user -e install.db.password -e install.db.hostname | paste - - - | sed 's/install.db.user =>/ -u/; s/install.db.password => / -p/; s/install.db.hostname => / PARAM_DELIM -h /; s/$/  --ssl-ca=\/usr\/local\/symplified\/shared\/MANAGED_MYSQL_CERT_PEM_FILE.pem/;'`
    echo "$mysqlParameters"
    exit
    exit
EOF1
  mysql_params="$(cat /tmp/tf | grep PARAM_DELIM | awk -F PARAM_DELIM '{print $2}')"
  echo "mysql params: $mysql_params"
}

#alias vim='vim +"set nohlsearch" +"set number" +"set autoindent" +"set tabstop=2" +"set shiftwidth=2"'
alias vi='vim'
alias srcrc='source ~/.bashrc'
alias balias='vim ~/.bash_aliases'
alias barc='vim ${HOME}/.bashrc'
alias vich='_f(){ vim $(which $1); }; _f'
alias files='xdg-open . &>/dev/null &'
alias sublime='/snap/bin/sublime-text.subl'
alias pycharm='/usr/share/pycharm/pycharm-community-2018.3.4/bin/pycharm.sh &'
alias chrome='_f(){ google-chrome-stable -U ${1} &>/dev/null; }; _f '
alias xo='open_all '

# interactive find and replace for all files under a given dir
function replace () {
  reg="$1"
  rep="$2"
  target_dir="$3"
  if [ -z "$target_dir" ]; then
    echo "please specify target dir"
    return 1
  fi
  if [ ! -d "$target_dir" ]; then
    echo "$target_dir does not exist or is not a dir"
    return 1
  fi
  for fname in $(find "$target_dir" -mindepth 1 -type f); do
    if grep -q "$reg" "$fname"; then
      vim -c 'set title' -c "%s/${reg}/${rep}/gc" -c 'wq' "$fname";
    fi
  done
}



repos=("Planitia" "tango" "singlepoint-appliance" "active-active")
repos_dir="${HOME}/git"
function pullall() {
  old_dir="$(pwd)"
  for repo in ${repos[@]}; do
    echo "pulling $repo"
    cd "$repos_dir"/"$repo"
    git pull  
  done
  cd "$old_dir"
}
function branches() {
  old_dir="$(pwd)"
  for repo in ${repos[@]}; do
    cd "$repos_dir"/"$repo"
    printf "%-30s %-50s\n" "$repo" ":$(gitbn)"
  done
  cd "$old_dir"
}
function gitbrregex(){
  git branch -r | tr -d ' ' | sed 's/origin\///' | grep -E $1 ;
}
# checkout the first branch that matches the given regex
function gitco(){ 
  #git checkout $(tr -d '"'"' \t\n\r'"'"' < <(gitbrregex $1)) --; 
  git checkout $(tr -d ' \t\n\r' < <(gitbrregex $1)) --; 
}
function gitcall() {
  old_dir="$(pwd)"
  for repo in ${repos[@]}; do
    cd "$repos_dir"/"$repo"
    gitco "$1" && git pull
  done
  cd "$old_dir"
}
function gitcmall() {
  gitcall "^master$"
}

alias idea="( /home/devuser/.local/share/JetBrains/Toolbox/apps/IDEA-U/ch-0/213.6777.52/bin/idea.sh & &> /dev/null )"
function gradledeps() {
  dir="$1"
  if [ -z "$1" ]; then
    dir=.
  fi
  old_dir=$(pwd)
  cd "$dir"
  ./gradlew dependencies $(./gradlew -q projects \
    | grep -o "Project '.*'" \
    | sed -e "s/Project '//g" -e "s/'//g" \
    | sed 's/:\(.*\)/\1:dependencies/g')
  cd "$old_dir"
}

function tailcarma() { tail -f /var/log/rsa/via/carma/carma.log; }
function tailad() { tail -f /var/log/rsa/securidaccess/admin/admin.log; }
function tailfe() { tail -f /var/log/rsa/securidaccess/ngx-fe/ngx-fe.log; }
function tailbe() { tail -f /var/log/rsa/securidaccess/ngx-be/ngx-be.log; }
function tailco() { tail -f /var/log/rsa/securidaccess/controller/controller.log; }
function tailst() { tail -f /var/log/symplified/catalina.out; }
function tailsy() { tail -f /var/log/symplified/symplified.log; }

function lesscarma() { less /var/log/rsa/via/carma/carma.log; }
function lessad() { less /var/log/rsa/securidaccess/admin/admin.log; }
function lessfe() { less /var/log/rsa/securidaccess/ngx-fe/ngx-fe.log; }
function lessbe() { less /var/log/rsa/securidaccess/ngx-be/ngx-be.log; }
function lessco() { less /var/log/rsa/securidaccess/controller/controller.log; }
function lessst() { less /var/log/symplified/catalina.out; }
function lesssy() { less /var/log/symplified/symplified.log; }

alias resnet='sudo service network-manager restart'

# GIT
alias gitc='git checkout'
# checks out the provided file to the version in the latest local commit
alias gitch='git checkout HEAD'
# checks out the master branch
alias gitcm='git checkout master'
# check out master, pull, prune branches
alias gitcmc='git checkout master && git pull && git remote prune origin && gitpl &> /dev/null'
# shows the commits on the current branch as compared with master
#alias gitlb='git log master..HEAD'
alias gitlb='gitlo master..HEAD'
# fetches a list of the names of the files that were updated in the
# provided commit hash
alias gitcf='git diff-tree --no-commit-id --name-only -r '
# lists all remote branches
alias gitbr='git remote show origin'
# discard all local commits and make branch identical to upstream
alias gitrst='git reset --hard @{u}'
# show all commits on current branch one by one
alias gitshow='echo "q to quit, any other key to continue"; for i in $(git log --oneline | cut -f1 -d" "); do git show --color=always $i | less -R; read; if [ "$REPLY" == "q" ]; then break; fi; done'
# shows branch hierarchy in a tree-like structure
alias gitlog='git log --graph --pretty=oneline --abbrev-commit'
# git log --oneline + author and date
alias gitlo='git log --color --pretty=format:"%C(Yellow)%h%Creset  %<(12,trunc)%an %C(Cyan)%<(30,trunc)%ad%Creset %s"'
# shows commits on the current branch that are not on master
alias gitsbc='git cherry -v master'
# removes stale local branches that have been removed in remote
alias gitpl='git branch -r | awk '\''{print $1}'\'' | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk '\''{print $1}'\'' | xargs git branch -D'
alias gitst='git status'
alias gitdh='git diff HEAD '
# select a specific file from stash to be applied
alias gitpsf='git checkout stash@{0} -- '
# merge the first branch that matches the given regex
alias gitmrg='_gmg() { git merge --no-ff $(tr -d '"'"' \t\n\r'"'"' < <(gitbrregex $1)) --; }; _gmg'
# print branch name
alias gitbn='git rev-parse --abbrev-ref HEAD'
# rename a branch locally and in remote
function gitbrnm() {
  old_name="$1"
  new_name="$2"
  git branch -m "$old_name" "$new_name"
  git push origin :"$old_name" "$new_name"
  git push origin -u "$new_name"
}
alias gitsu='git push --set-upstream origin $(gitbn)'
alias gitusersa='git config --global user.email "anas.hamed@securid.com"'
alias gitusepersonal='git config --global user.email "anas.ta.hamed@gmail.com"'
function mrg() {
  branch="karma/sb278"
  repo="$1"
  old_dir=$(pwd)
  cd "$repo"
  if [ ! -z "$(gitbr | grep -ir "$branch")" ]; then
    echo -e "\n* checking out $branch" && git checkout "$branch" \
    && echo -e "\n* pulling latest changes" && git pull \
    && echo -e "\n* checking out master and pulling latest changes" && git checkout master && git pull \
    && echo -e "\n* going back to $branch" && git checkout "$branch" \
    && echo -e "\n* merging master into $branch" && git merge master && git push
    #&& echo -e "\n*** running build" && ./gradlew build
  else
    echo "repo does not have a $branch branch"
  fi
  cd "$old_dir"
}
function mrgall() {
  start_idx=0
  i=0
  for repo in $(ls -A $1); do
    echo "offset: $i"
    if [ "$i" -lt "$start_idx" ]; then
      echo "*** skipping $repo"
      i=$((i+1))
      continue
    fi
    echo "*** PROCESSING $repo" | tee -a ~/git/mrgall_logs
    mrg "$1/$repo" $@ | tee -a ~/git/mrgall_logs
    [ ${PIPESTATUS[0]} -ne 0 ] && echo "$repo" >> ~/git/mrgall_failed
    echo -e "\n______\n" | tee -a ~/git/mrgall_logs
    i=$((i+1))
  done
}

# copy to clipboard
alias cpy='xargs echo -n | xclip -selection c -silent'
# paste from clipboard
alias pst='xclip -selection c -o'
# print number of files in all the dirs in current dir
alias lswc='for i in $(find . -maxdepth 1 ! -name . -prune -type d -printf "%f\n" ); do echo -ne "${i}: "; ls $i | wc -l; done'
# pretty print json
alias ppj='python -m json.tool'

