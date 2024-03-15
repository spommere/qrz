#! /bin/sh

# two formats:
# wsjt-x/z
#<call:6>NOCALL <gridsquare:0> <mode:3>FT8 <rst_sent:3>-08 <rst_rcvd:3>-18 <qso_date:8>20230910 <time_on:6>063600 <qso_date_off:8>20230910 <time_off:6>063715 <band:3>17m <freq:9>18.101500 <station_callsign:5>MYCALL <my_gridsquare:4>BK29 <tx_pwr:3>100 <comment:23>THX FOR QSO. 73 & ALOHA <eor>
# mshv
#<STATION_CALLSIGN:5>MYCALL<MY_GRIDSQUARE:4>BK29<CALL:6>NOCALL<GRIDSQUARE:4>JN45<DISTANCE:5>12618<MODE:3>FT8<RST_SENT:3>-07<RST_RCVD:3>+00<QSO_DATE:8>20230910<TIME_ON:6>062800<QSO_DATE_OFF:8>20230910<TIME_OFF:6>062800<BAND:3>17M<FREQ:9>18.100000<EOR>

if [ $# -ne 1 -a $# -ne 2 ]
then
  echo usage
  exit 1
fi

adi=$HOME/wsjtx_log.adi
font=22
call=$1
lineno=$2

#set -x
if [ -z "$lineno" ]
then
  grep -ni "<call.*>${call}.*<gridsquare" $adi
  echo "Line number ?"
  read lineno
fi

str=`grep -ni "<call.*>${call}.*<gridsquare" $adi|grep ^${lineno}`

#echo "str=$str"

if [ -z "$str" ]
then
  echo "wrong line number"
  exit 2
fi

# wsjt or mshv
prog=`echo $str|grep -c gridsquare`
if [ $prog -ne 0 ]
then
  wsjt=1
else
  wsjt=0
fi

str2=`echo $str|sed "s/</>/g"`
if [ $wsjt -eq 1 ]
then
  ncall=`echo $str2|cut -f3 -d">"`
  theirgrid=`echo $str2|cut -f5 -d">"`
  mode=`echo $str2|cut -f7 -d">"`
  rsts=`echo $str2|cut -f9 -d">"`
  rstr=`echo $str2|cut -f11 -d">"`
  qsodate=`echo $str2|cut -f13 -d">"`
  timeon=`echo $str2|cut -f15 -d">"`
  band=`echo $str2|cut -f21 -d">"`
  freq=`echo $str2|cut -f23 -d">"`
else
  ncall=`echo $str2|cut -f7 -d">"`
  theirgrid=`echo $str2|cut -f9 -d">"`
  mode=`echo $str2|cut -f13 -d">"`
  rsts=`echo $str2|cut -f15 -d">"`
  rstr=`echo $str2|cut -f17 -d">"`
  qsodate=`echo $str2|cut -f19 -d">"`
  timeon=`echo $str2|cut -f21 -d">"`
  band=`echo $str2|cut -f27 -d">"`
  freq=`echo $str2|cut -f29 -d">"`
fi
comment="Thx for QSO, 73 & Aloha"

year="${qsodate:0:4}"
month="${qsodate:4:2}"
day="${qsodate:6:2}"
qsodate_f=$(date -d "$year-$month-$day" "+%d/%m/%Y")
timeon_f=$(/bin/date -d "${timeon:0:2}:${timeon:2:2}:${timeon:4:2}" "+%H:%M:%S")
echo "$ncall $mode $band $freq $rsts $rstr qsodate=$qsodate qsodate_f=$qsodate_f $timeon_f $comment"

# find email address
curl -X GET 'https://xmldata.qrz.com/xml/current/?username=MYCALL&passwordNOCALLPASSWD%23%23' 1> ~/.req 2>/dev/null

str=`grep -c "non-subscriber" ~/.req 2>/dev/null`

if [ $str -ne 0 ]
then
  echo "No QRZ/XML subscription"
else
  key=`grep "^<Key>" ~/.req|sed "s/</ /g"|sed "s/>/ /g"|awk '{print $2}'`
  #echo "session key = $key"
  curl -X GET "https://xmldata.qrz.com/xml/current/?s=$key&callsign=$call" 1> ~/.req 2>/dev/null
  email=`grep email ~/.req|sed "s/</ /g"|sed "s/>/ /g"|awk '{print $2}'`
fi

row1=267
row2=310
row3=356
col1=300
col2=600
col3=780
col4=680
loc_comment_row=680
loc_comment_col=650

convert $HOME/qsl/QSL-compressed.jpg  -pointsize $font -fill black \
-annotate +$col1+267 "$call" \
-annotate +$col1+$row2 "$qsodate_f" \
-annotate +$col1+$row3 "$timeon_f" \
-annotate +$col2+$row1 "${band}" \
-annotate +$col3+$row1 "${freq} MHz" \
-annotate +$col2+$row2 "${mode}" \
-annotate +$col2+$row3 "${rsts}" \
-annotate +$col4+$row3 "${rstr}" \
-fill white -annotate +$loc_comment_col+$loc_comment_row "${comment}" \
$HOME/qsl/QSL-${call}.jpg

if [ -z "$email" ]
then
  echo "QSL card for $call is in $HOME/qsl/QSL-${call}.jpg"
  echo "Note: No email address could be associated with $call"
  exit 3
else
  echo "QSL card for $call ($email) is in $HOME/qsl/QSL-${call}.jpg"
fi

exit 0
