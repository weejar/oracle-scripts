cat /proc/buddyinfo | awk -v ps="`getconf PAGESIZE`" -v date="`date`" -v host="`hostname`" \
'BEGIN{printf("\nFragmentation Report\nLow is Order 1-4, High is order 5-9, Normal is order 10-11\n%s\t%s\n\n",host,date)} {\
L= ps * ( ($5 * 1) + ($6 * 2) + ($7 * 4) + ($8 * 8) ); \
H= ps * ( ($9 * 16) + ($10 * 32) + ($11 * 64) + ($12 * 128) + ($13 * 256)  ); \
N= ps * ( ($14 * 512) + ($15 * 1024) ); \
T=L+H+N; \
printf("%s\tTotal: %8dM\tLow: %02.2f%%\tHigh: %02.2f%%\tNormal: %02.2f%%\n",\
$1" "$2" "$3" "$4,T/1024/1024,(L/T)*100,(H/T)*100,(N/T)*100);}'