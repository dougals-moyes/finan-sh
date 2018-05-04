#!/bin/sh
# Journal takes one required parameter, and other optional for batch
# or external processing.
# <journal file> [command] [options]
# command
# post		post journal entries
# addentry	add an entry. reads commands from stdin. Commands are
#		as follows:
#		STRT <date, YYYYmmDD>
#		DEBT <account#> <amount>
#		CRED <account#> <amount>
#		DESC <description>
#		DONE	
##################################################

if [ -n "`echo '\c'`" ]
then
	#Because GNU wants to be special...
	export es="-e"
else
	export es=""
fi

export version="0.2"

if [ -z "$PAGER" ]
then
	export PAGER="more"
fi

pause(){
	echo $es '*** Press Enter ***\c'
	read x
}

accountbrowser()
{
	$PAGER $COAf
	pause
}
printbar(){
	a=0
	until [ $a = 8 ]
	do
		#a=`expr $a + 1`
		a=$((a + 1))
		echo  "$1$1$1$1$1$1$1$1$1$1\c"
	done
	echo ""
}


#cat << EOF
#  **** **** *   * **** ****    *   *         * **** *  * ****  *   *   *   *    
# *     *    **  * *    *   *  * *  *         * *  * *  * *   * **  *  * *  *    
# *  ** **** * * * **** ****  ***** *         * *  * *  * ****  * * * ***** *    
# *   * *    *  ** *    * *   *   * *     *   * *  * *  * * *   *  ** *   * *    
#  **** **** *   * **** *  *  *   * ****   ***  **** **** *  *  *   * *   * **** 
#Bourne Shell script version $version 
#
#EOF

############
#  These functions convert a floating point number to fixed point
#  and vice versa. for 2 pt numbers only.
############

float2tofix(){

	if [ "`echo $es "$1\c"|tail -c 3|head -c 1`" = '.' ]
	then
		dec="`echo $es "$1\c"|tail -c 2`"
		base="`echo $es "$1\c"|sed s/\.$dec//g`"
		if [ -z "$base" ]
		then
			base=0
		fi
	else
		dec="00"
		base="$1"
	
	fi
	test "$base$dec" -gt 0 &>/dev/null
	ret=$?
	if [ $ret = 2 ]
	then
		echo "ERROR: Must be numerical value" >/dev/tty
		return 1
	fi
	if [ $ret = 1 ]
	then	
		echo "ERROR: Must be non-negative" >/dev/tty
		return 1
	fi
	echo $es "$base$dec\c"
}
fix2tofloat(){
	size=`echo $es "$1\c"|wc -c`
	#bsize=`expr $size - 2`
	bsize=$((size - 2))
	if [ $bsize -eq 0 ]
	then
		base=0
	else
		base=`echo $es "$1\c"|head -c $bsize`
	fi
	dec=`echo $es "$1\c"|tail -c 2`
	echo $base.$dec
}

############################################# 
#                Output function            #
#############################################

# Takes no arguments, stdout date in YYYYmmDD format.
formatdate(){
date +%Y%m%d
}

############################################
#Takes file and waits for it to disappear.
#or aborts with "FAIL" and exit code of 1.
#Creates file when done by "touch".   
checklock()
{
if [ -f "$1" ] 
then
	echo $es "File in use. waiting for completion.\c"
	cmd=c
	a=0
	until [ "$cmd" != "c" -o ! -f "$1" ] 
	do
		cmd=" "
		a=0 
		until [ $a -gt 15 -o ! -f "$1" ] 
		do
			sleep 1;
			echo $es ".\c"
			#a=`expr $a + 1`
			a=$((a + 1))
		done
		if [ -f "$1" ]
		then
			echo "$1.tmp still exists."
			echo "press 'c' then enter to continue waiting."
			echo "... or just press return to abort."
			read cmd
		fi
	done
fi
if [ -f "$1" ]
then
	echo "FAIL"
	return 1 
else
	touch "$1"
	return 0 
fi

}
#############################################
#Takes two arguments. affected file, regular expression
# of lines to exclude.
deletelines() {
	if ! checklock "$1.tmp"
	then
		echo "File lock could not be established."
		echo "Could not perform operation."
	fi
	grep -v -e "$2" <"$1" >"$1.tmp"
	mv "$1.tmp" "$1"
}
############################################
#Creates a reference number.
refnum(){
	date +%H%M%S
}
############################################
#Takes the following arguments:
#<journal file> <date> <reference> <debit/credit> <acc#> <doc#>  <amount> [p]
# if p is given in the 8th argument, the record will be written as if
# it has been posted to an account.
# or
# <journal file> <date> <reference> ds <description...>
writeentry(){
if [ "$4" = "ds" ]
then
	echo "$2.$3 des $5" >>"$1"
else
if [ "$8" = "p" ]
then
	post="*"
else
	post="."
fi
	doc=`echo $es "$6\c"|colrm 11` 
	printf "$2.$3 $4 $post %8d %-10s %s\n" $5 "$doc" $7 >>"$1"
	sort <"$1" >"$1.tmp"
	mv "$1.tmp" "$1"
fi
}
#############################################
#          Record searching functions       #
#############################################
#All of these functions take the same arguments:
# <date>.reference. Since this is a grep
# search, reference may be omitted, as well as
# part of the date.

######## Handler/sort functions
get_sortlist() {
colrm 16 <"$jfile"|uniq
}

findnext() {
	get_sortlist|grep -e "$1" -A 1|tail -1 
}
findprev() {
	get_sortlist|grep -e "$1" -B 1|head -1 
}

#############################
#      Display Functions    #
#############################
gettransdate(){
	echo "$1"|colrm 9
}
gettransref(){
	echo "$1"|colrm 1 9|colrm 7
}
gettranstype(){
	type=`echo "$1"|colrm 1 16|colrm 2`
	if [ $type = "d" ]
	then
		type="des"
	fi
	echo $type
}
getpoststat()
{
	echo "$1"|colrm 1 18|colrm 2
}
## this one returns the line, but marked as if posted.
# takes two parameters. first is the line, next is the post code
setpost()
{
	part1="`echo "$1"|colrm 19|tr -d \n`"
	part2="`echo "$1"|colrm 1 19|tr -d \n`"
	echo "$part1""$2""$part2"
	
}
getaccnt(){
	echo "$1"|colrm 1 20|colrm 10
}
getdesc(){
	echo "$1"|colrm 1 20
}
getdocno(){
	echo "$1"|colrm 1 29|colrm 11
}
getamnt(){
	#remove leading zeros, which were present in the 2003 format for small numbers.
	echo "$1"|colrm 1 40|sed 's/^ //'|sed 's/^0*//'
}
#########################
# Takes one argument: date.ref 
display_entry(){
	grep -e ^"$1" "$jfile"|display_entry_streamed
}
display_entry_streamed(){

	read line
	lines=1
	balance=0
	until [ -z "$line" ]
	do
		if [ $lines = 1 ]
		then
			echo $es "`gettransdate "$line"`\c"
		fi
		if [ $lines = 2 ]
		then
			echo $es "(`gettransref "$line"`)\c"
		fi
		if [ $lines -gt 2 ]
		then
			echo $es "        \c"
		fi
		type=`gettranstype "$line"`
		if [ "$type" != "des" ]
		then
			accno=`getaccnt "$line"`
			accname="`coa_manager "$COAf" lN $accno`"
			docno="`getdocno "$line"`"
			amnt=`getamnt "$line"`
			famnt=$amnt
			amnt=`fix2tofloat $amnt`
			posted=`getpoststat "$line"`
		fi
		case $type in
			c|D)
				if [ $type = c ]
				then
					#balance=`expr $balance - $famnt`
					balance=$((balance - famnt))
					printf " %2s%-23s" "" "$accname"
				else
					#balance=`expr $balance + $famnt`
					balance=$((balance + famnt))
					printf " %-23s%2s" "$accname" ""
				fi
				if [ "$posted" = "." ]
				then
					pinds="<"
					pinde=">"
				else
					pinds="["
					pinde="]"
				fi
				printf "$pinds%s$pinde" $accno
				printf " %10s" "$docno"
				if [ $type = c ]
				then
					printf " %12s" ""
				fi
					printf " %15s\n" $amnt
		 	  ;;
			des)
				getdesc "$line"|fmt -45| { 
					read line
					printf " %6s%s\n" "" "$line"
					read line
					until [ -z "$line" ]
					do
						printf "%8s %6s%s\n" \
						 "" "" "$line"
						 read line
					done
				} ;;
		esac			
		read line
		#lines=`expr $lines + 1`
		lines=$((lines + 1))
	done
	if [ $balance != 0 -a -z "$1" ]
	then
		echo '**** ENTRY DOES NOT BALANCE! ****'
		btype="Credit"
		if [ $balance -lt 0 ]
		then
			btype=Debit
			#balance=`expr $balance \* -1`
			balance=$((balance * -1))
		fi
		echo "Need $btype"s" of" `fix2tofloat $balance`
			
		return 1
	else
		return 0
	fi
}
###################################################################
#=================================================================
###################################################################

###################################################################

#coa_manager, originally in it's own file in the 2003 version

# Takes the following arguments
# <file> <cmd> <parameter> 
# cmd parameter
# lN  <number> 	Looks up account by number, returns name.
# ln  <name>	Looks up account by name, returns number 
# pr  <number>	Returns parent account #, if any. exitcode 1 if none.
# ck  number	Check to see if account # exists
# finder	U/I to help locate an account.

coa_manager(){
file=$1
cmd=$2
op="$3"

case $cmd in 
	lN) if ! retname $file $op 
	    then
	    	echo $op
	    	return 1
	    else
	    	return 0
	    fi
	;;
	pr) name=`retname $file $op`
	    a=`grep ^$op $file|sed "s/$name//"|sed "s/^[0-9]*.//"`
 	    if [ -z "$a" ]
	    then
		return 1
	    fi
	    echo $a
	    return 0
	   ;;
	ck) if grep "^$op[ .]" $file
	    then
		return 0
	    else
	    	return 1
	    fi
	   ;;
esac	 
}

retname(){
a=`grep  ^$2 $1|sed "s/[0-9.]* //"`
if [ -z "$a" ]
then
	return 1
fi
echo $a
return 0
}
###################################################################
#=================================================================
###################################################################

# account_helperapp -- originally a separate script in the 2003 version
#
# format:
# <basedir> <cmd> [options] 
# cmd options
# pst <accnt> <date.ref> <type> <amnt> <source journal>
#		Posts an entry
# bpst 		Batch post. Reads entries to be posted from stdin.   
#		input lines take same format as above.	
# bal <accnt> [date]	Returns the balance of the account. If date is given,
#		returns the balance as of that date.
# forcepd	A fix in case bpst fails to post some accounts 	
# listbal [date] lists balances for ALL accounts. Output format:
#	        <amount> <account#>.[parent] <AccountName>

account_helperapp(){
basedir="$1"
if [ -z "$basedir" ]
then
	basedir="."
fi
dir="$basedir/ACCOUNTS"
cmd="$2"
shift
shift
options="$*"

if [ ! -d $dir ]
then
	mkdir "$dir"
fi
case "$cmd" in
	pst)
		post $options ;;
	bpst)
		batchpost;;
	forcepd)
		postdelayed $options ;;
	bal) balance $options;;
	listbal) listbal $options;;
	*)
		echo Unknown command 
		;;
	
esac
	
}

####### 
# Posts an entry.
# <accnt> <date.ref> <type> <amnt> <source journal>
post(){
	acc="$dir/$1"
	type="$3"
	val="$4"
	ref="$2"
	j="`basename "$5"`"
	js="`echo "$j"|colrm 16`"
	tmp="$acc.tmp"
	if [ "`checklock "$tmp"`" = "FAIL" ]
	then
		echo "Can't establish lock. Terminating"
		return 1
	fi
	touch "$tmp"
	printf "$ref %-15s $type %s \n" "$js" $val |cat - "$acc" |sort >>"$tmp"
	mv "$tmp" "$acc"
}
###################################
# 		USED FOR BATCH POSTINGS ONLY!!!
# DOES NO LOCKING CHECKS. DOES NOT COMMIT CHANGES TO MAIN ACCOUNT FILE
# UNTIL postdelayed IS CALLED!
# format:
# <accnt> <date.ref> <type> <amnt> <source journal> [pid]
# Although any text for [pid] will do, it **SHOULD** be the pid of the
# current process as it will be used in the naming of the batch
# temporary file.
####################################
delayedpost(){
	tmp="$dir/$1.tmp.$6"
	type="$3"
	val="$4"
	ref="$2"
	j="`basename "$5"`"
	js="`echo "$j"|colrm 16`"
	printf "$ref %-15s $type %s\n" "$js" $val >>"$tmp"

}
######################
#postdelayed, cleans up from the last posting and updates main files
# takes only [pid] as a parameter.
postdelayed()
{
	for file in "$dir"/*.tmp.$1
	do
		lockfile="$dir"/"`basename "$file" .$1`"
		basefile="$dir"/"`basename "$lockfile" .tmp`"
		touch "$basefile"
		while  [ "`checklock "$lockfile"`" = "FAIL" ]
		do
			echo "Lock file $lockfile is holding up posting. Please resolve"
			echo "or your accounts will be in an unstable posted state."
			echo
			echo "Press Enter when lock has been resolved."
			read x
		done

		touch $lockfile
		cat "$basefile" "$file"|sort >"$lockfile"
		mv "$lockfile" "$basefile"
		rm "$file"
	
	done
}
#######################
#Reads lines to be posted from stdin, saves them for batch
#processing with delayepost, then processes the batch by calling
#postdelayed.
batchpost()
{
	read line
	until [ -z "$line" ]
	do
		delayedpost $line $$
		read line
	done
	postdelayed $$
	
}
##############################################
####
# returns the balance in an account. Credit balances are returned
# as negative numbers.
#format: [-fp] <account>  [end date] 
balance() {
	file="$dir/"$1
	stopdate="99990000"
	if [ "$1" = "-fp" ]
	then
		fp="true"
		shift
	else
		fp="false"
	fi
	if [ "0$2" -gt "10001212" ]
	then
		stopdate="$2"	
	fi

	if [ ! -f "$file" ]
	then
		echo ""
		return 1
	fi
	cat "$file"|{
		balance=0
		read line
		until [ -z "$line" ]
		do
			date=`echo "$line"|colrm 9`
			type=`echo "$line"|colrm 1 32|colrm 2`
			amnt=`echo "$line"|colrm 1 33|sed 's/^ //'|sed 's/^0*//'`
			if [ $type = D ]
			then
				type="+"
			else
				type="-"
			fi
			if [ $date -le "$stopdate" ]
			then
				#balance=`expr $balance $type $amnt`
				balance=$((balance $type amnt))
			fi
			read line
		done
		if [ $fp = "true" ]
		then
			echo $balance
		else
			fix2tofloat $balance
		fi
	}
}

#################
# listbal()
#################
listbal(){
	for account in "$dir"/* 
	do
		acc=`basename "$account"`
		bal=`balance $acc $1`
		name=`coa_manager $basedir/COA lN $acc`
		parent=`coa_manager $basedir/COA pr $acc`
		if [ -n "$parent" ]
		then
			acc="$acc.$parent"
		fi
		printf "%15s $acc $name \n" $bal
#		echo "$bal $acc $name"
	done
}


###################################################################
#=================================================================
###################################################################

####################################################################
#                   *   *  **** ***** ****  
#                   *   * *     *     *   * 
#                   *   *   *   ***** ****  
#                   *   *     * *     * *   
#                   ***** ****  ***** *  *  
#
#    ***** *   * ***** ***** ****  *****   *    **** ***** 
#      *   **  *   *   *     *   * *      * *  *     *     
#      *   * * *   *   ***** ****  ***** *****   *   ***** 
#      *   *  **   *   *     * *   *     *   *     * *     
#    ***** *   *   *   ***** *  *  *     *   * ****  ***** 
#######################################################################

####################
# prompts user for input and adds entry. 
# arguments: file date reference.
# Not intended to be called directly! 

addentry(){
	echo "Press enter for account list."
	acc=""
	until [ -n "$acc" ]
	do
		echo $es "Account:\c"
		read acc
		if [ -z "$acc" ]
		then
			accountbrowser
		fi
	done		
	
	accname=`coa_manager "$COAf" lN $acc`
	if [ $? = 0 ] 
	then
		echo "$acc listed as \"$accname\""
	else
		echo "***NOTICE*** No listing for $acc."
		echo "Press enter to abort, or 'c' and enter to continue."
		read cmd
		if [ cmd != 'c' ]
		then
			return 1
		fi
	fi
	type=" "
	until [ "$type" = "D" -o "$type" = "c" ]
	do
		echo $es "Debit/Credit (d/c):\c"
		read type
		type=`echo $type|tr [dC] [Dc]`
	done
	ret=1
	until [ $ret = 0 ]
	do
		echo $es "Amount:\c"
		read amount
		amount=`echo $amount|tr -d ',$'` 
		amount=`float2tofix $amount`
		ret=$?
	done
	echo $es "Doc No.:\c"
	read doc
	echo "Press enter to write, or 'a' and enter to abort."
	read cmd
	if [ "$cmd" != "a" ]
	then
		writeentry $1 $2 $3 $type $acc "$doc" $amount
	fi
}
######################
#
addentries()
{
	date=`formatdate`
	echo $es "Enter date in YYYYmmDD format [$date]:\c"
	read cmd
	if [ "0$cmd" -gt 19801201 -a "0$cmd" -le 32101231 ]
	then
		date="$cmd"
	else
		if [ -n "$cmd" ]
		then
			echo "BAD FORMAT."
			return
		fi
	fi
	ref=`refnum`
	file="$1$date.$ref"
	touch "$file"
	des=""
	until false
	do
		
		echo
		printbar -
		(cat $file;echo "$date.$ref des $des")|display_entry_streamed
		printbar -
		ret=$?
		echo "____________________________"   
		echo "|   Entry date: $date   |"
		echo "+--------------------------+"
		echo "| a Add entry              |"
		echo "| d Delete entry           |"
		echo "| c change description     |"
		echo "| s spellcheck description |"
		echo "| w write and exit         |"
		echo "| e abort                  |"
		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
		echo $es "Command:\c"
		read cmd
		echo ""
		
		case "$cmd" in 
			a) addentry "$file" $date $ref;;
			c) echo $es "Description:\c"; read des;;
			e) rm "$file";return;;
			d) cat "$file"|{
			    read line
			    touch "$file.tmp"
			    until [ -z "$line" ]
			    do
				echo "$line"|display_entry_streamed no
				echo $es "*** Press enter to keep, 'd' to delete:\c"
				read c </dev/tty
				if [ "$c" != "d" ]
				then
					echo "$line" >>"$file.tmp"
				fi
				read line
			     done
			     mv "$file.tmp" "$file"
			   }
			 ;;
			w) 
			   if [ $ret != 0 ]
			   then
			   	echo "ENTRY DOES NOT BALANCE!"
			   	echo $es" I will not record.\c"
			   	echo "Press enter."
			   	read
			   	continue
			   fi
			   if checklock "$1.tmp"
			   then
			   	if [ -n "$des" ]
				then
				writeentry "$file" $date $ref ds "$des"
				fi
			   	cat "$1" "$file"|sort >"$1.tmp"
				mv "$1.tmp" "$1"
				rm "$file"
				else
				echo "Can't establish lock on $1 to commit."
			   fi 
			   return ;;
			s) echo "$des" >"$file.spell"
			   ispell "$file.spell"
			   des=`cat "$file.spell"`
			   rm "$file.spell" "$file.spell.bak" &>/dev/null;;
		esac	
	done
}
browser(){
	if [ -n "$1" ]
	then
		ref=$1
	else
		echo $es "Enter start date or record or press enter:\c"
		read c
		if [ -n "$c" ]
		then
			ref=`grep -e ^$c "$jfile"|head -1|colrm 16`
		else
			ref=`head -1 <"$jfile"|colrm 16`
		fi
	fi
	c=" " 	
	until [ "$c" = "e" ]
	do
		if [ -z "$ref" ]
		then
			echo "** NONE FOUND **"
		else
			display_entry "$ref"
		fi
		echo " "
		echo $es "Enter for next, p for previous, e to exit:\c"
		read c
		if [ "$c" = "p" ]
		then
			ref=`findprev $ref`
		else
			ref=`findnext $ref`
		fi
		echo '************************************************'
	done 
}
menu(){
until false
do
cat << EOF



  *****   
    *    Version $version (Bourne Shell)      
    *  **** *  * * ***   ***   ** * *     
    *  *  * *  * **   * *   * *  ** *     
*   *  *  * *  * *      *   * *   * *     
 ***   **** **** *      *   *  ** * *     
 Using $jfiledisplay journal
    a Add entries      aac add accounts 
    d Delete entries   al list accounts
    l list entries 

    p post (required to show balances) 
    b account balance
    ball balances for all accounts

    e exit


EOF
echo $es "Command:\c"
read cmd
case "$cmd" in
	aac) addAccount;;
	al)  accountbrowser;;
	a) addentries "$1";;
	d) echo "** UNIMPLEMENTED **";;
	l) browser ;;
	e) return;;
	p) post;;
	b) echo $es "Account number:\c"
	   read acc
	   bal=`account_helperapp $jbasedir bal $acc`
	   name="`coa_manager $COAf lN $acc`" 
	   echo "Balance for \"$name\" ($acc) is \$$bal" 
	   pause
	   ;;
	ball) file="/dev/tty"
	      echo $es "File to dump listing to [$file]:\c"
	      read f
	      if [ -n "$f" ]
	      then
	      	file="$f"
	      fi
	      account_helperapp $jbasedir listbal >"$file"
	      echo "---Listing Complete"
	      pause
	      ;;
esac	
done
}
#########################################
#  Posting and batch functions		#
#########################################
post() {
	postfile="$jfile.posting"
	tmp="$jfile.tmp"
	jname="`basename $jfile`"
	if  ! checklock "$tmp"
	then
		echo "Can't post while file is locked"
		return 1
	fi
	cat "$jfile"|{
		echo "Posting..."
		read line
		until [ -z "$line" ]
		do
			if [ "`getpoststat "$line"`" = "." ]
			then
				echo $es "*\c"
				setpost "$line" \* >>"$tmp"
				accnt=`getaccnt "$line"`
				amnt=`getamnt "$line"`
				type=`gettranstype "$line"`
				date=`gettransdate "$line"`
				ref=`gettransref "$line"`
				echo $accnt $date.$ref \
				   $type $amnt $jname >>"$postfile"
			else
				echo $es ".\c"
				echo "$line" >>"$tmp"
			fi
			read line
		done
		echo
	}
	if [ ! -f "$postfile" ]
	then
		echo "No accounts were posted."
		rm "$tmp"
	else
		if account_helperapp "$jbasedir" bpst < "$postfile"
		then	
			mv "$tmp" "$jfile"
		else
			echo '*** UNKNOWN FAILURE ***'
			echo "Posting aborted."
			echo "Account files might be corrupted."
			pause
			rm "$tmp"
		fi
			
			rm "$postfile"
	fi

}

addAccount(){
cat <<EOF
Add Account
-----------
	  (1) Asset    (2) Liability
	  (3) Capital
	  (4) Revenue  (5)Expense
EOF
	echo $es "Account Type:\c"

	read type
	if [ "$type" -gt 5 -o "$type" -lt 1 ]
	then
		echo "Invalid type"
		return 1
	fi
	echo $es "Last three digits of account:\c"
	read last3
	#leading zeros cause a number to be treated
	#as octal in arithmetic expansion
	last3=`echo $last3|sed 's/^0*//'`
	if [ -z "$last3" ]
	then 
		last3=0
	fi

	if [ "$last3" -lt 0 -o "$last3" -gt 999 ]
	then
		echo "Invalid range"
		return 1
	fi

	echo $es "Parent account (enter for none):\c"
	read parent

	account=$((type*1000+last3))
	echo "Checking for excising accounts..."
	if grep -e "^$account" "$COAf"
	then
		echo "***ERROR: Account exists"
		return 1
	fi
	if [ -n "$parent" ]
	then
		echo  "Looking up parent account..."
		if grep -e "^$parent" "$COAf"
		then
			account="$account.$parent"
		else
			echo "***ERROR: Parent doesn't exist"
			return 1
		fi

	fi

	echo $es "Account name:\c"
	read name
	echo "$account $name"|cat - "$COAf" |sort  >"$COAf.bk"
	mv "$COAf.bk" "$COAf"

}



######################################################################
#                                                                    #
# End of functions                                                   #
#                                                                    #
######################################################################
if [ -z "$1" ]
then
cat << EOF
Computer technology is very limited in this day and age.  Mainly,
it lacks the ability to read the users thoughts. Seeing as computers
are unable to read thoughts, I need you to specify the journal
file on the command line, like this:

journal [DataDir|JournalFile]

EOF
exit 1
fi

if [ ! -e "$1" ]
then
	echo $es "$1 does not exist, Create it? (y/n)\c"
	read x
	if [ "$x" != "y" ]
	then
		exit 1
	fi
	mkdir "$1"
	mkdir "$1/ACCOUNTS"
	touch "$1/JOURNAL"
	touch "$1/COA"
fi

if [ ! -w "$1" -o ! -r "$1" ]
then
	echo $es "Unable to access $1. Permission denied.\c"
	echo " Shame on you! ;-)"
	exit 1
fi




export jfiledisplay="$1"


if [ -d "$1" ]
then
	export jfile="$1/JOURNAL"
	export jbasedir="$1"
	export COAf="$1/COA"

else
	export jfile="$1"
	export jbasedir="`dirname "$1"`"
	export COAf="$jbasedir/COA"
fi


if [ -z "$2" ]
then
	menu $jfile
else
	case "$2" in
		post) post;;
		addentry) addentry;;
	esac
fi
