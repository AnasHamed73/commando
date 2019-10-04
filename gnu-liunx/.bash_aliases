alias resnet='sudo service network-manager restart'

function open_all() {
  for f in $*; do
		xdg-open $f &>/dev/null
		while [ $(pgrep -af "eog.*${f}" | wc -l) -ne "0" ]; do
			:
		done
	done
}

#alias vim='vim +"set nohlsearch" +"set number" +"set autoindent" +"set tabstop=2" +"set shiftwidth=2"'
alias vi='vim'
alias files='xdg-open . &'
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
alias gcpssh='gcloud compute ssh instance-1 --zone us-east4-c'
alias gcpscp='_f(){ gcloud compute scp --recurse $1 instance-1:~/sent --zone us-east4-c; }; _f '
alias gcpfetch='_f(){ gcloud compute scp --recurse instance-1:~/$1 . --zone us-east4-c; }; _f '
alias gcpstart='gcloud compute instances start instance-1 --zone us-east4-c'
alias gcpstop='gcloud compute instances stop instance-1 --zone us-east4-c'
alias gcpstatus='gcloud compute instances list'

alias cpy='xclip -selection c -silent'
alias pst='xclip -selection c -o'
