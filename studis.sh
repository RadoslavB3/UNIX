#!/bin/bash

logoperation() {
  DATE=`date '+%Y-%m-%d %H:%M.%S'`
  echo "$DATE $$ ${LOGNAME:-x} $0 $PARAMETERS">> $LOGFILE
}

dejlog() {
  if [ $ARGS -gt 2 ]; then echo "Too much parameters" >&2 && exit 1; fi
  if [ $ARGS -eq 1 ]; then cat $LOGFILE && exit 0; fi
  egrep -q "$1" $LOGFILE && egrep "$1" $LOGFILE && exit 0
  exit 1
}

newfaculty() {
  IDLEN=`expr length $1`
  if [ $IDLEN -gt 8 ]; then echo "Too long ID." >&2 && exit 1; fi
  egrep -q "\<"$1"\>" $FACFILE && echo "Duplicate faculty." >&2 && exit 1;
  echo "$1|"$2"" >> $FACFILE
}

deletefaculty() {
  if [ $ARGS -ne 2 ]; then echo "Bad amount of arguments." >&2 && exit 1; fi
  if egrep -q "\<"$1"\>" $SEMFILE; then echo "Faculty is used in semester register." >&2 && exit 1;fi
  egrep -q "\<"$1"\>" $FACFILE && grep -Fv "$1|" $FACFILE > fac.tmp && mv fac.tmp $FACFILE && exit 0
  echo "Faculty does not exist." >&2 && exit 1
}

changename() {
  egrep -q "\<"$1"\>" $FACFILE && sed -i "s/$1|.*/$1|$2/gi" $FACFILE && exit 0
  echo "Faculty does not exist." >&2 && exit 1
}

printfaculties() {
  printf "%-8s | %s\n" "Fakulta" "Název"
  echo "--------------------------"
  if [ $ARGS -eq 2 ]; then grep $1 $FACFILE |(IFS='|'; while read ID NAME; do printf '%-8s | %s\n' $ID $NAME; done)|sort -k 2 -t "|" -n;
  else cat $FACFILE |(IFS='|'; while read ID NAME; do printf "%-8s | %s\n" $ID $NAME; done)|sort -k 2 -t "|" -n;
  fi
}

newsemester() {
  IDLEN=`expr length $2`
  if [ $IDLEN -gt 8 ]; then echo "Too long ID." >&2 && exit 1; fi
  ! egrep -q "\<"$1"\>" $FACFILE && echo "Faculty does not exist." >&2 && exit 1;
  egrep -q "\<"$1"\|"$2"\>" $SEMFILE && echo "Duplicate semester." >&2 && exit 1;
  UPPER=`date -d "+2 years" +"%Y-%m-%d"`
  if ! [[ $3 =~ ^[0-9]{4}-[0-1][0-9]-[0-3][0-9]$ ]] || ! date -d "$3" >/dev/null 2>&1; then echo "Invalid date." >&2 && exit 1; fi
  if [[ "$3" < "2000-01-01" ]]; then echo "Invalid date." >&2 && exit 1; fi
  if [[ "$3" > "$UPPER" ]]; then echo "Invalid date." >&2 && exit 1; fi
  echo "$1|$2|$3|"$4"" >> $SEMFILE
}

deletesemester() {
  if egrep -q "\<"$2"\>" $PREMFILE; then echo "Semester is used in subject register." >&2 && exit 1;fi
  egrep -q "\<"$1"\|"$2"\>" $SEMFILE && sed -i "/$1|$2/d" $SEMFILE && exit 0
  echo "Semester does not exist." >&2 && exit 1
}

printsemester() {
  if [ $ARGS -ge 2 ] && ! egrep -q "\<"$1"\>" $SEMFILE; then echo "Faculty does not exist." >&2 && exit 1;fi
  if [ $ARGS -eq 3 ] && ! egrep -q "\<"$2"\>" $SEMFILE; then echo "Semester does not exist." >&2 && exit 1;fi
  printf "%-8s | %-8s | %-8s | %s\n" "Fakulta" "Semestr" "Od" "Název"
  echo "-----------------------------------------"
  if [ $ARGS -eq 2 ]; then grep $1 $SEMFILE |(IFS='|'; while read FAC ID DATE NAME; do printf "%-8s | %-8s | %-8s | %s\n" $FAC $ID $DATE $NAME; done)|sort -k3 -k1 -t "|";
  elif [ $ARGS -eq 3 ]; then egrep "\<"$1"\|"$2"\>" $SEMFILE |(IFS='|'; while read FAC ID DATE NAME; do printf "%-8s | %-8s | %-8s | %s\n" $FAC $ID $DATE $NAME; done)|sort -k3 -k1 -t "|";
  else cat $SEMFILE |(IFS='|'; while read FAC ID DATE NAME; do printf "%-8s | %-8s | %-8s | %s\n" $FAC $ID $DATE $NAME; done)|sort -k3 -k1 -t "|"; fi
}

changesemname() {
  if ! egrep -q "\<"$1"\|"$2"\>" $SEMFILE; then echo "Semester does not exist." >&2 && exit 1;fi
  LINE="$(egrep "\<"$1"\|"$2"\>" $SEMFILE)"
  DATE="$(echo $LINE | cut -d "|" -f 3)"
  egrep -q "\<"$1"\|"$2"\>" $SEMFILE && sed -i "s/$1|$2.*/$1|$2|$DATE|$3/gi" $SEMFILE && exit 0
  echo "Semester does not exist." >&2 && exit 1
}

changesemdate() {
  if ! egrep -q "\<"$1"\|"$2"\>" $SEMFILE; then echo "Semester does not exist." >&2 && exit 1;fi
  LINE="$(egrep "\<"$1"\|"$2"\>" $SEMFILE)"
  NAME="$(echo $LINE | cut -d "|" -f 4)"
  UPPER=`date -d "+2 years" +"%Y-%m-%d"`
  if ! [[ $3 =~ ^[0-9]{4}-[0-1][0-9]-[0-3][0-9]$ ]] || ! date -d "$3" >/dev/null 2>&1; then echo "Invalid date." >&2 && exit 1; fi
  if [[ "$3" < "2000-01-01" ]]; then echo "Invalid date." >&2 && exit 1; fi
  if [[ "$3" > "$UPPER" ]]; then echo "Invalid date." >&2 && exit 1; fi
  egrep -q "\<"$1"\|"$2"\>" $SEMFILE && sed -i "s/$1|$2.*/$1|$2|$3|$NAME/gi" $SEMFILE && exit 0
  echo "Semester does not exist." >&2 && exit 1

}

newsubject() {
  IDLEN=`expr length $3`
  ! egrep -q "\<"$1"\>" $FACFILE && echo "Faculty does not exist." >&2 && exit 1;
  ! egrep -q "\<"$1"\|"$2"\>" $SEMFILE && echo "Semester does not exist." >&2 && exit 1;
  if ! [[ $3 == [a-zA-Z]* ]]; then echo "Invalid ID format." >&2 && exit 1; fi
  if [ $IDLEN -gt 8 ]; then echo "Too long ID." >&2 && exit 1; fi
  egrep -q -i "\<"$1"\|"$2"\|"$3"\>" $PREMFILE && echo "Duplicate subject." >&2 && exit 1;
  if ! [[ "$5" = "zk" ]] && ! [[ "$5" = "k" ]] && ! [[ "$5" = "z" ]]; then echo "Invalid ending of subject." >&2 && exit 1;fi
  if ! [[ $6 =~ ^[0-9]+$ ]] || [[ $6 -lt 0 ]] || [[ $6 -gt 20 ]]; then echo "Invalid value of credits." >&2 && exit 1;fi
  echo "$1|$2|$3|"$4"|$5|$6" >> $PREMFILE
}

deletesubject() {
   if egrep -q -i "\<"$1"\|"$2"\|"$3"\>" $LOGSUBJECT; then echo "Subject is logged by student." >&2 && exit 1;fi
   egrep -q -i "\<"$1"\|"$2"\|"$3"\>" $PREMFILE && sed -i "/$1|$2|$3/Id" $PREMFILE && exit 0
   echo "Subject does not exist." >&2 && exit 1
}

printsubject() {
  if ! [ -s $PREMFILE ];then echo "Empty file." >&2 && exit 1;fi
  if [ $ARGS -ge 2 ] && ! egrep -q "\<"$1"\>" $PREMFILE; then echo "Faculty does not exist." >&2 && exit 1;fi
  if [ $ARGS -ge 3 ] && ! egrep -q "\<"$1"\|"$2"\>" $PREMFILE; then echo "Semester does not exist." >&2 && exit 1;fi
  if [ $ARGS -eq 4 ] && ! egrep -q -i "\<"$1"\|"$2"\|"$3"\>" $PREMFILE; then echo "Subject does not exist." >&2 && exit 1;fi
  printf "%-8s | %-8s | %-8s | %-2s | %2s | %s\n" "Fakulta" "Semestr" "Kurz" "Uk" "Kr" "Název"
  echo "----------------------------------------------------"
  if [ $ARGS -eq 2 ]; then grep $1 $PREMFILE |(IFS='|'; while read FAC SEM SUB NAME UK KR; do printf "%-8s | %-8s | %-8s | %-2s | %2s | %s\n" $FAC $SEM $SUB $UK $KR $NAME; done)|sort -k1 -k2 -k3 -t "|" -n;
  elif [ $ARGS -eq 3 ]; then egrep "\<"$1"\|"$2"\>" $PREMFILE |(IFS='|'; while read FAC SEM SUB NAME UK KR; do printf "%-8s | %-8s | %-8s | %-2s | %2s | %s\n" $FAC $SEM $SUB $UK $KR $NAME; done)|sort -k1 -k2 -k3 -t "|" -n;
  elif [ $ARGS -eq 4 ]; then egrep -i "\<"$1"\|"$2"\|"$3"\>" $PREMFILE |(IFS='|'; while read FAC SEM SUB NAME UK KR; do printf "%-8s | %-8s | %-8s | %-2s | %2s | %s\n" $FAC $SEM $SUB $UK $KR $NAME; done)|sort -k1 -k2 -k3 -t "|" -n;
  else cat $PREMFILE |(IFS='|'; while read FAC SEM SUB NAME UK KR; do printf "%-8s | %-8s | %-8s | %-2s | %2s | %s\n" $FAC $SEM $SUB $UK $KR $NAME; done)|sort -k1 -k2 -k3 -k1 -t "|" -n; fi
}

changeending() {
  if ! egrep -q -i "\<"$1"\|"$2"\|"$3"\>" $PREMFILE; then echo "Subject does not exist." >&2 && exit 1;fi
  if ! [[ "$4" = "zk" ]] && ! [[ "$4" = "k" ]] && ! [[ "$4" = "z" ]]; then echo "Invalid ending of subject." >&2 && exit 1;fi
  LINE="$(egrep -i "\<"$1"\|"$2"\|"$3"\>" $PREMFILE)"
  NAME="$(echo $LINE | cut -d "|" -f 4)"
  CODE="$(echo $LINE | cut -d "|" -f 3)"
  CRED="$(echo $LINE | cut -d "|" -f 6)"
  egrep -q -i "\<"$1"\|"$2"\|"$3"\>" $PREMFILE && sed -i "s/$1|$2|$3.*/$1|$2|$CODE|$NAME|$4|$CRED/gi" $PREMFILE && exit 0
  echo "Subject does not exist." >&2 && exit 1
}

changesubname() {
  if ! egrep -q -i "\<"$1"\|"$2"\|"$3"\>" $PREMFILE; then echo "Subject does not exist." >&2 && exit 1;fi
  LINE="$(egrep -i "\<"$1"\|"$2"\|"$3"\>" $PREMFILE)"
  UK="$(echo $LINE | cut -d "|" -f 5)"
  CRED="$(echo $LINE | cut -d "|" -f 6)"
  CODE="$(echo $LINE | cut -d "|" -f 3)"
  egrep -q -i "\<"$1"\|"$2"\|"$3"\>" $PREMFILE && sed -i "s/$1|$2|$3.*/$1|$2|$CODE|$4|$UK|$CRED/gi" $PREMFILE && exit 0
  echo "Subject does not exist." >&2 && exit 1
}

changesubcred() {
  if ! egrep -q -i "\<"$1"\|"$2"\|"$3"\>" $PREMFILE; then echo "Subject does not exist." >&2 && exit 1;fi
  if ! [[ $4 =~ ^[0-9]+$ ]] || [[ $4 -lt 0 ]] || [[ $4 -gt 20 ]]; then echo "Invalid value of credits." >&2 && exit 1;fi
  LINE="$(egrep -i "\<"$1"\|"$2"\|"$3"\>" $PREMFILE)"
  UK="$(echo $LINE | cut -d "|" -f 5)"
  NAME="$(echo $LINE | cut -d "|" -f 4)"
  CODE="$(echo $LINE | cut -d "|" -f 3)"
  egrep -q -i "\<"$1"\|"$2"\|"$3"\>" $PREMFILE && sed -i "s/$1|$2|$3.*/$1|$2|$CODE|$NAME|$UK|$4/gi" $PREMFILE && exit 0
  echo "Subject does not exist." >&2 && exit 1

}

newstudent() {
  if [ $1 -le 0 ]; then echo "Invalid UCO." >&2 && exit 1;fi
  if ! [[ $1 =~ ^[0-9]+$ ]]; then echo "Invalid UCO." >&2 && exit 1;fi
  if [[ -z "$2" ]] || [[ -z "$3" ]]; then echo "Invalid name." >&2 && exit 1;fi
  UPPER=`date +"%Y-%m-%d"`
  if ! [[ $4 =~ ^[0-9]{4}-[0-1][0-9]-[0-3][0-9]$ ]] || ! date -d $4 >/dev/null 2>&1; then echo "Invalid date." >&2 && exit 1; fi
  if [[ "$4" < "1900-01-01" ]]; then echo "Invalid date." >&2 && exit 1; fi
  if [[ "$4" > "$UPPER" ]]; then echo "Invalid date." >&2 && exit 1; fi
  if ! [[ "$5" =~ ^([A-Za-z]+[A-Za-z0-9]*\+?((\.|\-|\_)?[A-Za-z]+[A-Za-z0-9]*)*)@(([A-Za-z0-9]+)+((\.|\-|\_)?([A-Za-z0-9]+)+)*)+\.([A-Za-z]{2,})+$ ]]; then echo "Invalid email." >&2 && exit 1;fi
  if egrep -q "\<"$1"\>" $STUDENTFILE; then echo "Duplicate UCO." >&2 && exit 1;fi
  echo "$1|$2|$3|$4|$5" >> $STUDENTFILE
}

printstudent() {
  if ! [ -s $STUDENTFILE ]; then echo "Empty file." >&2 && exit 1;fi
  cat $STUDENTFILE |(IFS='|'; while read UCO NAME SURNAME DATE EMAIL; do printf "%s;%s\n" $UCO $EMAIL; done)|sort -k1n -t ";"
}

deletestudent() {
  if egrep -q "\<"$1"\>" $LOGSUBJECT; then echo "Can not delete this student." >&2 && exit 1;fi
  egrep -q "\<"$1"\>" $STUDENTFILE && sed -i "/$1/Id" $STUDENTFILE && exit 0
  echo "Student does not exist." >&2 && exit 1
}

logsubject() {
  if ! egrep -q "\<"$1"\>" $FACFILE; then echo "Faculty does not exist." >&2 && exit 1;fi
  if ! egrep -q "\<"$2"\>" $SEMFILE; then echo "Semester does not exist." >&2 && exit 1;fi
  if ! egrep -q -i "\<"$3"\>" $PREMFILE; then echo "Subject does not exist." >&2 && exit 1;fi
  if ! egrep -q "\<"$4"\>" $STUDENTFILE; then echo "Student does not exist." >&2 && exit 1;fi
  if egrep -q -i "\<"$1"\|"$2"\|"$3"\|"$4"\>" $LOGSUBJECT; then echo "Duplicate log of subject." >&2 && exit 1;fi
  echo "$1|$2|$3|$4" >> $LOGSUBJECT
}

printlog() {
  if ! egrep -q -i "\<"$1"\|"$2"\|"$3"\>" $LOGSUBJECT; then echo "No students." >&2 && exit 1;fi
  egrep -i "\<"$1"\|"$2"\|"$3"\>" $LOGSUBJECT |(IFS='|'; while read FAC SEM CODE UCO; do egrep "\<"$UCO"\>" $STUDENTFILE; done)|sort -k3,3 -k2,2 -k1,1n -t "|"| sed -e 's/\([^|]*\)|\([^|]*\)|\([^|]*\)|\([^|]*\)|\([^|]*\)/\3, \2; učo \1/gi'
}

mark() {
  if ! egrep -q -i "\<"$1"\|"$2"\|"$3"\|"$4"\>" $LOGSUBJECT; then echo "Subject is not logged." >&2 && exit 1;fi
  ENDING="$(egrep -i "\<"$1"\|"$2"\|"$3"\>" $PREMFILE | cut -d "|" -f 5)"
  DATE="$(date +"%Y-%m-%d %H:%M.%S")"
  if [[ "$ENDING" == "zk" ]] && ! [[ $5 =~ ^[A-F] ]]; then echo "Invalid ending." >&2 && exit 1;fi
  if [[ "$ENDING" == "k" ]] && ! [[ $5 =~ ^[PN] ]]; then echo "Invalid ending." >&2 && exit 1;fi
  if [[ "$ENDING" == "z" ]] && ! [[ $5 =~ ^[ZN] ]]; then echo "Invalid ending." >&2 && exit 1;fi
  NUM="$(egrep -i "\<"$1"\|"$2"\|"$3"\|"$4"\>" $MARKFILE | wc -l)"
  if [ $NUM -ge 3 ]; then echo "Too much marks." >&2 && exit 1;fi
  egrep -i "\<"$1"\|"$2"\|"$3"\|"$4"\>" $MARKFILE |(IFS='|'; while read FAC SEM CODE UCO MARK; do if [[ $MARK =~ ^[ABCDEZP] ]]; then echo "Already passed." >&2 && exit 1;fi; done)
  if [ $? -eq 0 ]; then echo "$1|$2|$3|$4|$5|$DATE" >> $MARKFILE; else exit 1; fi
}

printmarks() {
  if [ $# -eq 1 ] && ! egrep -q "\<"$1"\>" $MARKFILE; then echo "No marks for this student." >&2 && exit 1;fi
  if [ $# -eq 3 ] && ! egrep -q "\<"$1"\|"$2"\|"$3"\>" $MARKFILE; then echo "No marks for this subject." >&2 && exit 1;fi
  if [ $# -eq 3 ]; then egrep -i "\<"$1"\|"$2"\|"$3"\>" $MARKFILE |(IFS='|'; while read FAC SEM CODE UCO MARK DATE; do egrep "\<"$UCO"\>" $STUDENTFILE |(IFS='|'; while read UCO NAME SURNAME OTHER; do echo "$SURNAME|$NAME|$UCO|$MARK|$DATE"; done); done)|
  sort -k1,1 -k2,2 -k5,5 -t "|"| sed -e 's/\([^|]*\)|\([^|]*\)|\([^|]*\)|\([^|]*\)|\([^|]*\)/\1, \2; učo \3: \4 \5/gi';fi
  if [ $# -eq 1 ]; then egrep -i "\<"$1"\>" $MARKFILE |(IFS='|'; while read FAC SEM CODE UCO MARK DATE; do egrep -i "\<"$CODE"\>" $PREMFILE |(IFS='|'; while read FAC SEM CODE NAME OTHER; do echo "$CODE|$NAME|$MARK|$DATE"; done); done)|
  sort -k1,1 -k4,4 -t "|"| sed -e 's/\([^|]*\)|\([^|]*\)|\([^|]*\)|\([^|]*\)/\1 \2: \3 \4/gi';fi
}

deletelog() {
  egrep -q -i  "\<"$1"\|"$2"\|"$3"\|"$4"\>" $LOGSUBJECT && sed -i "/$1|$2|$3|$4/Id" $LOGSUBJECT && egrep -q -i "\<"$1"\|"$2"\|"$3"\|"$4"\>" $MARKFILE && sed -i "/$1|$2|$3|$4/Id" $MARKFILE && exit 0
  echo "Subject not signed." >&2 && exit 1
}

DIRECTORY="/home/xbena1/pv004lab/studisdata"
FORCEOPERATION=0
PARAMETERS=$*

while getopts 'd:f' OPTION; do
case "$OPTION" in
f) FORCEOPERATION=1;;
d) DIRECTORY=$OPTARG;;
?) exit 1;;
esac
done
shift $(($OPTIND-1))
cd /
ARGS=$#
if [ $# -eq 0 ]; then echo No operation given. >&2 && exit 1; fi
if [ ! -d $DIRECTORY ]; then mkdir $DIRECTORY || exit 1; fi
if [ ! -w $DIRECTORY ]; then echo Can not write in $DIRECTORY. >&2 && exit 1; fi
cd $DIRECTORY
LOGFILE="logfile"
FACFILE="facfile"
SEMFILE="semfile"
PREMFILE="premfile"
STUDENTFILE="studfile"
LOGSUBJECT="logsubfile"
MARKFILE="markfile"
if [ ! -f $LOGFILE ]; then touch $LOGFILE || exit 1; fi
if [ ! -w $LOGFILE ]; then echo Can not write in $LOGFILE. >&2 && exit 1; fi
if [ ! -f $FACFILE ]; then touch $FACFILE || exit 1; fi
if [ ! -w $FACFILE ]; then echo Can not write in $FACFILE. >&2 && exit 1; fi
if [ ! -f $SEMFILE ]; then touch $SEMFILE || exit 1; fi
if [ ! -w $SEMFILE ]; then echo Can not write in $SEMFILE. >&2 && exit 1; fi
if [ ! -f $PREMFILE ]; then touch $PREMFILE || exit 1; fi
if [ ! -w $PREMFILE ]; then echo Can not write in $PREMFILE. >&2 && exit 1; fi
if [ ! -f $STUDENTFILE ]; then touch $STUDENTFILE || exit 1; fi
if [ ! -w $STUDENTFILE ]; then echo Can not write in $STUDENTFILE. >&2 && exit 1; fi
if [ ! -f $LOGSUBJECT ]; then touch $LOGSUBJECT || exit 1; fi
if [ ! -w $LOGSUBJECT ]; then echo Can not write in $LOGSUBJECT. >&2 && exit 1; fi
if [ ! -f $MARKFILE ]; then touch $MARKFILE || exit 1; fi
if [ ! -w $MARKFILE ]; then echo Can not write in $MARKFILE. >&2 && exit 1; fi
logoperation
case $1 in
cesta-adresář|cesta-adresar) if [ $ARGS -ne 1 ]; then echo "Too much parameters." >&2 && exit 1; fi; echo $DIRECTORY;;
dej-log) dejlog $2;;
smaž-adresář|smaz-adresar) if [ $ARGS -ne 1 ]; then echo "Too much parameters." >&2 && exit 1; fi;
                           if [ $FORCEOPERATION -eq 1 ]; then rm -r $DIRECTORY && exit 0;
                           else echo "Use -f option." >&2 && exit 1; fi;;
pomoc) if [ $ARGS -ne 1 ]; then echo "Too much parameters." >&2 && exit 1; fi;
       echo "Read the task." && exit 0;;
fakulta-nová|fakulta-nova) if [ $# -ne 3 ]; then echo "Bad amount of arguments." >&2 && exit 1; else newfaculty $2 "$3";fi;;
fakulta-smaž|fakulta-smaz) deletefaculty "$2";;
fakulta-název|fakulta-nazev) if [ $# -ne 3 ]; then echo "Bad amount of arguments." >&2 && exit 1; else changename $2 "$3";fi;;
fakulta-výpis|fakulta-vypis) if [ $# -gt 2 ]; then echo "Bad amount of arguments." >&2 && exit 1; else printfaculties $2;fi;;
semestr-nový|semestr-novy) if [ $# -ne 5 ]; then echo "Bad amount of arguments." >&2 && exit 1; else newsemester $2 $3 $4 "$5";fi;;
semestr-smaž|semestr-smaz) if [ $# -ne 3 ]; then echo "Bad amount of arguments." >&2 && exit 1; else deletesemester $2 $3;fi;;
semestr-výpis|semestr-vypis) if [ $# -gt 3 ]; then echo "Bad amount of arguments." >&2 && exit 1; else printsemester $2 $3;fi;;
semestr-název|semestr-nazev) if [ $# -ne 4 ]; then echo "Bad amount of arguments." >&2 && exit 1; else changesemname $2 $3 "$4";fi;;
semestr-datum) if [ $# -ne 4 ]; then echo "Bad amount of arguments." >&2 && exit 1; else changesemdate $2 $3 $4;fi;;
předmět-nový|predmet-novy) if [ $# -ne 7 ]; then echo "Bad amount of arguments." >&2 && exit 1; else newsubject $2 $3 $4 "$5" $6 $7;fi;;
předmět-smaž|predmet-smaz) if [ $# -ne 4 ]; then echo "Bad amount of arguments." >&2 && exit 1; else deletesubject $2 $3 $4;fi;;
předmět-výpis|predmet-vypis) if [ $# -gt 4 ]; then echo "Bad amount of arguments." >&2 && exit 1; else printsubject $2 $3 $4;fi;;
předmět-ukončení|predmet-ukonceni) if [ $# -ne 5 ]; then echo "Bad amount of arguments." >&2 && exit 1; else changeending $2 $3 $4 $5;fi;;
předmět-název|predmet-nazev) if [ $# -ne 5 ]; then echo "Bad amount of arguments." >&2 && exit 1; else changesubname $2 $3 $4 "$5";fi;;
předmět-kredity|predmet-kredity) if [ $# -ne 5 ]; then echo "Bad amount of arguments." >&2 && exit 1; else changesubcred $2 $3 $4 $5;fi;;
student-nový|student-novy) if [ $# -ne 6 ]; then echo "Bad amount of arguments." >&2 && exit 1; else newstudent $2 $3 $4 $5 "$6";fi;;
student-export) if [ $# -ne 1 ]; then echo "Bad amount of arguments." >&2 && exit 1; else printstudent;fi;;
student-smaž|student-smaz) if [ $# -ne 2 ]; then echo "Bad amount of arguments." >&2 && exit1; else deletestudent $2;fi;;
zápis|zapis) if [ $# -ne 5 ]; then echo "Bad amount of arguments." >&2 && exit 1; else logsubject $2 $3 $4 $5;fi;;
zápis-předmět|zapis-predmet) if [ $# -ne 4 ]; then echo "Bad amount of arguments." >&2 && exit 1; else printlog $2 $3 $4;fi;;
známka|znamka) if [ $# -ne 6 ]; then echo "Bad amount of arguments." >&2 && exit 1; else mark $2 $3 $4 $5 $6;fi;;
známka-výpis|znamka-vypis) if [ $# -ne 2 ] && [ $# -ne 4 ]; then echo "Bad amount of arguments." >&2 && exit 1; else printmarks $2 $3 $4;fi;;
zápis-smaž|zapis-smaz) if [ $# -ne 5 ]; then echo "Bad amount of arguments." >&2 && exit 1; else deletelog $2 $3 $4 $5;fi;;
*) echo "Wrong operation." >&2 && exit 1;;
esac

