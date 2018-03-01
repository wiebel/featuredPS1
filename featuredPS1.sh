#!/bin/bash
## (c) by wiebel (wiebel42@gmail.com)
# Function to display the returncode of the previous command if not zero
ps1_return() {
if [ "$1" != "0" ]; then
	echo -e "$1 "
fi
return $1
}

# Generating the not symlinked part of the Working directory 

# Needs to be improved, by the use of $DIRSTACK, should be waaaay easier

ps1_pre() { 
ret=$?			# Buffer the returncode
dir=$PWD
dir_komp=$PWD
#if grep -q ^$HOME <<< $PWD
if [ -z "${PWD/${HOME}*}" ]; then
	athome=true
#	dir_komp=$(sed -e "s/^$(sed -e "s:/:\\\/:g" <<<$HOME)/~/" <<< $dir)
	dir_komp=${dir/${HOME}/\~}
	while [ "$PWD" != "$HOME" ]; do
#	if readlink "$PWD" >/dev/null; then
	if [ -L "$PWD" ]; then
		sym=true
		cd ..
		dir=$PWD/
	else
		cd ..
		fi
	done
#	dir=$(sed -e "s/^$(sed -e "s:/:\\\/:g" <<<$HOME)/~/" <<< $dir) 
	dir=${dir/${HOME}/\~}
else
	athome=false
	while [ "$PWD" != "/" ]; do
#	if readlink "$PWD" >/dev/null
	if [ -L "$PWD" ]; then
		sym=true
		cd ..
		dir=$PWD/
	else
		cd ..
	fi
	done
fi

#if [ `wc -c <<< $dir_komp`  -gt "30" ]
if [ ${#dir_komp} -gt "30" ]; then
	if [ $sym ]; then
		if $athome; then 
			dir="~/$(cut -d/ -f2 <<< $dir)/..."
		else
			dir="/$(cut -d/ -f2 <<< $dir)/..."
		fi
	else 
		dir=$(sed -e 's:\(/[^/]*/\).*\(/[^/]\):\1...\2:' <<< $dir)
#		dir=${dir/${HOME}/\~}
	fi
fi
echo -e $dir
return $ret
}

# coloring if we're at home or not
ps1_pre_color(){
ret=$?
#if grep -q $HOME <<<$PWD
if [ -z "${PWD/${HOME}*}" ]; then
	echo -e $HOME_COLOR
else 
	echo -e $ROOT_COLOR
fi
return $ret
}


# Now to the colors for the symlinked part of it
ps1_dir_color() {
ret=$?

#If we're not at home make it $ROOT_SYM
d_color=$ROOT_SYM
# If we're anywhere at home make it $HOME_SYM
#if grep -q ^$HOME <<< $PWD
if [ -z "${PWD/${HOME}*}" ]; then
	d_color=$HOME_SYM
fi
# Check if we really are where we ought to be (if there is a symlink in the path)
while [ "$PWD" != "/" ]; do
#	if readlink "$PWD" >/dev/null
	if [ -L "$PWD" ]; then
	# There is a symlink so now show me you're true color
		new_path=$(readlink "$PWD")
		cd ../;cd $new_path
#		if grep -q ^$HOME <<< $PWD
		if [ -z ${PWD/${HOME}*} ]; then 
			d_color=$HOME_SYM
		else 
			d_color=$ROOT_SYM
		fi
	else
		cd ..
	fi
done
echo -e "$d_color"
return $ret
}

# Ok show me the symlinked part of the path
ps1_dir() {
ret=$?
#	echo $1
#if grep -q ^~ <<< $1
if [ -z "${1/\~*}" ]; then
#	d=$(sed -e "s:~:$HOME:" <<<"$*")
	d=${*/\~/${HOME}}
else
	d="$*"
fi

if [ "$d" = "$PWD" ]; then
	dir=""
elif grep -q "\.\.\.$" <<<"$d"; then
	dir=$(sed -e "s:.*\(/[!/]*\):\1:" <<< $PWD)
elif grep -q "\/\.\.\.\/" <<< "$d"; then
	dir=""
else
	dir=$(sed -e "s/^$(sed -e "s:/:\\\/:g" <<<"$d")//" <<< $PWD)  
fi

echo -e "$dir"
return $ret
}

# So another thing, good to know is, if i am allowed to write, so here we go ...
ps1_write() {
ret=$?
if [ -w "$PWD" ]; then
	echo -e "$ON_COLOR"
else 
	echo -e "$OFF_COLOR"
fi
return $ret
}
# Do i own the current dir ??
ps1_own() {
ret=$?
if [ -O "$PWD" ]; then
	echo -e "$ON_COLOR"
else
	echo -e "$OFF_COLOR"
fi
return $ret
}

#DIR_P='$(ps1_pre)'
# Now to the root or not to root question (slightly modificated from the original profile)
# i've not yet came to it to set all colors to variable so feel free to adjust ;)
if [ `/usr/bin/whoami` = 'root' ]; then
	# Do not set PS1 for dumb terminals
	if [ "$TERM" != 'dumb'  ] && [ -n "$BASH" ]; then
		# like always no username for root for he is red 
		PS1pre='\A '
		PS1U='' 
		PS1H='\[\033[01;31m\]\h'
		# here we enlight if root does own it or not
		PS1P='\[$(ps1_own)\]\$ \[\033[0m\]'
		# patch up the returncode 
		PS1ret='\[\033[01;31m\]$(ps1_return $?)'
		#and now for the pwd stuff
		PS1dir='\[$(ps1_pre_color)\]$(ps1_pre)\[$(ps1_dir_color)\]$(ps1_dir $(ps1_pre))'
		# I found no other solution than embracing the colors right here 'cause  
		# echo -e "\[...\]" doesn't work for any reason. 
		# Another point where help would be appreciated ;)

		# ok now stitch it together
		export PS1="${PS1pre}${PS1U}${PS1H} ${PS1dir} ${PS1ret}${PS1P}"
	fi
else
	# Do not set PS1 for dumb terminals
	if [ "$TERM" != 'dumb'  ] && [ -n "$BASH" ]; then
		PS1pre='\A '
		PS1U='\[\033[01;33m\]\u'
		# Not to forget to enlight the @ to show if we are owner
		PS1H='\[$(ps1_own)\]@\[\033[00;32m\]\h'
		# and enlight the $ if we are to write
		PS1P='\[$(ps1_write)\]\$ \[\033[0m\]'
		PS1ret='\[\033[01;31m\]$(ps1_return $?)'
		PS1dir='\[$(ps1_pre_color)\]$(ps1_pre)\[$(ps1_dir_color)\]$(ps1_dir $(ps1_pre))'
		export PS1="${PS1pre}${PS1U}${PS1H} ${PS1dir} ${PS1ret}${PS1P}"
	fi
fi

ROOT_COLOR="\033[01;34m"		# blue
HOME_COLOR="\033[01;33m"		# yellow
ROOT_SYM="\033[00;36m"
HOME_SYM="\033[00;33m"

SYM_COLOR="\033[00;36m"			# cyan
ON_COLOR="\033[01;37m"			# white
OFF_COLOR="\033[01;30m"			# grey
