alias resnet='sudo service network-manager restart'

alias vim='vim +"set nohlsearch" +"set number" +"set autoindent" +"set tabstop=2" +"set shiftwidth=2"'
alias vi='vim'
alias files='xdg-open . &'
alias idea='/usr/share/idea/idea-IC-183.5912.21/bin &'
alias pycharm='/usr/share/pycharm/pycharm-community-2018.3.4/bin/pycharm.sh &'

alias sprsync='_f(){ rsync -avr $1 ahamed@springsteen.cse.buffalo.edu:/home/csgrad/ahamed/basecode; }; _f '
alias sprssh='ssh ahamed@springsteen.cse.buffalo.edu'
alias mtlsync='_f(){ rsync -avr $1 ahamed@metallica.cse.buffalo.edu:/home/csgrad/ahamed/sent; }; _f '
alias mtlssh='ssh ahamed@metallica.cse.buffalo.edu'
alias tmbsync='_f(){ rsync -avr $1 ahamed@timberlake.cse.buffalo.edu:/home/csgrad/ahamed; }; _f '
alias tmbssh='ssh ahamed@timberlake.cse.buffalo.edu'

alias cpy='xclip -selection c -silent'
alias pst='xclip -selection c -o'
