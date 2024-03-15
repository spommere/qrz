#! /bin/sh
  
# search for a particular posting on QRZ swapmeet page
#export https_proxy=...
#email=...
page=https://qrz.com/page/hotswap.html
b=`basename $page`
slp=5m

srch1=V71
srch2=D710

tmp=/tmp
cd $tmp

touch $tmp/qqrz.dat
while true
do
  rm -f $b
  echo "`/bin/date`: calling wget"
  /bin/wget $page 1>/dev/null 2>&1
  egrep "$srch1|$srch2" $tmp/$b|grep index.php|grep width > $tmp/qqrz.tmp
  while read line
  do
    link=`echo $line|awk '{print $3}'|cut -f2 -d=`
    device=`echo $line|cut -f6 -d/`
    str=`grep -c $device $tmp/qqrz.dat`
    if [ $str -eq 0 ]
    then
      echo "$device, $link"
      echo $device >> $tmp/qqrz.dat
      echo "found $link"|mail -s "QRZ.com: Found $device" -r $email $email
    fi
  done < $tmp/qqrz.tmp
  echo "`/bin/date`: sleep $slp"
  sleep $slp
done

