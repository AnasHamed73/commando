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

alias cpy='xclip -selection c -silent'
alias pst='xclip -selection c -o'
# counts the number of lines in all the files in the current directory
alias lswc='for i in $(find . -maxdepth 1 ! -name . -prune -type d -printf "%f\n" ); do echo -ne "${i}: "; ls $i | wc -l; done'
