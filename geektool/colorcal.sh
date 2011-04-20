#!/bin/bash
# 
# colorcal - change current day and date via ANSI color escape sequences 
# 
# developed/tested on 10.6.3 with: 
# /bin/sh --version GNU bash, version 3.2.48(1)-release (x86_64-apple-darwin10.0) 
# geektool 3, 3.0 (12A) 
# Terminal Version 2.1.1 (273) 
# see http://www.termsys.demon.co.uk/vtansi.htm for color codes. 
# 
# sed (1) is your friend. 
# 

# pick color, clear color 
color="\033[1;31m" 
nocolor="\033[0m" 

# get day & date 
current_day=`/bin/date "+%a" | cut -b 1,2` 
current_date=`date | awk '{print $3}'` 

#color em. 
color_day=`echo -e "${color}${current_day}${nocolor}"` 
color_date=`echo -e "${color}${current_date}${nocolor}"` 

# format cal output so the sed replacements work at begining and end of cal output. 
function calendar { 
/usr/bin/cal | sed 's/ /_/g' | sed -e 's/^/ /' -e 's/$/_/' | sed 's/_/ /g' 
} 

# run calendar & substitute colored day & date. 
calendar | /usr/bin/sed -e "s/ ${current_day} / ${color_day} /" -e "s/ ${current_date} / ${color_date} /" 
# END of colorcal 

next_year=`date +%Y`
next_month=$((`date +%m` + 1))
if [[ $next_month -gt 12 ]]; then
  next_month=1
  next_year=$(($next_year + 1))
fi
/usr/bin/cal $next_month $next_year
