alias resnet='sudo service network-manager restart'

function open_all() {
  for f in $*; do
		xdg-open ${f}* &>/dev/null
		while [ $(pgrep -af "eog.*${f}" | wc -l) -ne "0" ]; do
			:
		done
	done
}

#alias vim='vim +"set nohlsearch" +"set number" +"set autoindent" +"set tabstop=2" +"set shiftwidth=2"'
alias vi='vim'
alias files='xdg-open . &>/dev/null &'
alias sublime='/opt/sublime_text/sublime_text '
alias idea='/usr/share/idea/idea-IC-183.5912.21/bin &'
alias pycharm='/usr/share/pycharm/pycharm-community-2018.3.4/bin/pycharm.sh &'
alias chrome='_f(){ google-chrome-stable -U ${1} &>/dev/null; }; _f '
alias xo='open_all '

# GIT
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
# removes stale local branches that have been removed in remote
alias gitpl='git branch -r | awk '\''{print $1}'\'' | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk '\''{print $1}'\'' | xargs git branch -d'
alias gitst='git status'
alias gitdh='git diff HEAD '
# select a specific file from stash to be applied
alias gitpsf='git checkout stash@{0} -- '
# follow specific file through git history
function gitfollow() {
	file_path="$1"
	succ=HEAD
	first=y
  echo "q to quit, any other key to continue"
	for commit in $(git log --oneline --follow -- $file_path | cut -f1 -d' '); do
		[ $first == 'y' ] && first=n && continue
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


# MEZ
rsync_send() {
  hostname="$1"; shift
  rsync -avr --progress $* ${hostname}:/home/ubuntu/airport
}
rsync_get() {
  hostname="$1"; shift
  rsync -avr --progress ${hostname}:/home/ubuntu/$1 .
}
sshp() {
  ssh_host=$1
}
alias commitmez='_f(){ git commit -m "MEZ-${1}, MEZ-${2} - ${3}"; }; _f '
#ssh_host="ec2"
#ssh_host="biggerguns"
#ssh_host="bigguns"
ssh_host="mezdev"
alias sshmez="ssh $ssh_host"
alias sendmez="rsync_send $ssh_host "
alias fetchmez="rsync_get $ssh_host "

cookies_file="./cookie_vals.txt"
primsg() {
  curl -b "$cookies_file" -H "Content-Type: application/json" -X POST -d "{\"userId\": \"5e3b319688eb61114b5d10b5\", \"message\":\"$1\"}" 'http://localhost:4000/messages/private'
}
groupmsg() {
  curl -b "$cookies_file" -H "Content-Type: application/json" -X POST -d "{\"message\":\"$1\"}" 'http://localhost:4000/messages/all'
}
  # Potree
alias makec='cd /home/anas/src/potree/PotreeConverter/master/build && make && cd /home/anas/src/potree/PotreeConverter/master/Converter/src'
alias rlas='/home/anas/src/potree/PotreeConverter/master/build/PotreeConverter -i /home/anas/src/potree/input/aligned.las -o /home/anas/src/potree/PotreeConverter/master/build/out/'
alias rply='/home/anas/src/potree/PotreeConverter/master/build/PotreeConverter -i /home/anas/src/potree/input/aligned.ply -o /home/anas/src/potree/PotreeConverter/master/build/out/'

# UB VM
alias sprsync='_f(){ rsync -avr $1 ahamed@springsteen.cse.buffalo.edu:/home/csgrad/ahamed/basecode; }; _f '
alias sprssh='ssh ahamed@springsteen.cse.buffalo.edu'
alias mtlsync='_f(){ rsync -avr $1 ahamed@metallica.cse.buffalo.edu:/home/csgrad/ahamed/sent; }; _f '
alias mtlssh='ssh ahamed@metallica.cse.buffalo.edu'
alias tmbsync='_f(){ rsync -avr $1 ahamed@timberlake.cse.buffalo.edu:/home/csgrad/ahamed; }; _f '
alias tmbssh='ssh ahamed@timberlake.cse.buffalo.edu'

# GCP
#GCP_INSTANCE_NAME="instance-1"
#GCP_INSTANCE_ZONE="us-east1-c"
GCP_INSTANCE_NAME="instance-2"
GCP_INSTANCE_ZONE="us-east1-d"
alias gcpssh='gcloud compute ssh "$GCP_INSTANCE_NAME" --zone "$GCP_INSTANCE_ZONE"'
alias gcpscp='_f(){ gcloud compute scp --recurse $* "$GCP_INSTANCE_NAME":~/sent --zone "$GCP_INSTANCE_ZONE"; }; _f '
alias gcpfetch='_f(){ gcloud compute scp --recurse "$GCP_INSTANCE_NAME":~/$1 . --zone "$GCP_INSTANCE_ZONE"; }; _f '
alias gcpstart='gcloud compute instances start "$GCP_INSTANCE_NAME" --zone "$GCP_INSTANCE_ZONE"'
alias gcpstop='gcloud compute instances stop "$GCP_INSTANCE_NAME" --zone "$GCP_INSTANCE_ZONE"'
alias gcpstatus='gcloud compute instances list'
alias gcpexec="gcloud compute ssh "$GCP_INSTANCE_NAME" --zone "$GCP_INSTANCE_ZONE" --command "

# HEROKU
HEROKU_APP_NAME="portfolio-anas"
HEROKU_DB_USER="mydb"
HEROKU_DB_PASSWD="mypass"
alias herokubash="heroku run bash -a $HEROKU_APP_NAME"
alias herokulogs="heroku logs --tail -a $HEROKU_APP_NAME"
alias herokucredit="heroku ps -a $HEROKU_APP_NAME"
alias herokupushdb="PGUSER=$HEROKU_DB_USER PGPASSWORD=$HEROKU_DB_PASSWD heroku pg:push postgres://localhost/pfdb postgresql-curly-51366 -a $HEROKU_APP_NAME"
alias herokuresetdb='heroku pg:reset -a $HEROKU_APP_NAME'

alias ganache='/home/kikuchio/Downloads/installers/ganache-2.1.1-linux-x86_64.AppImage &> /dev/null &'

alias cpy='xargs echo -n | xclip -selection c -silent'
alias pst='xclip -selection c -o'
alias lswc='for i in $(find . -maxdepth 1 ! -name . -prune -type d -printf "%f\n" ); do echo -ne "${i}: "; ls $i | wc -l; done'
