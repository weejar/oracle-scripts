#/bin/bash

##allow_slab_useage volue is 1-100 , if 20 represent 20%

##指定slab内存占总内存的使用比例，超过就执行释放命令；比如，参数20就表示20% 。

allow_slab_useage=20

##count slab mem size ; #计算当前slab内存大小

slab_size=`cat /proc/meminfo | grep -i slab | awk '{print $2/1024/1024}'`

##count total mem size ;#计算当前内存总大小

total_size=`cat /proc/meminfo  | grep -i memtotal | awk '{print $2/1024/1024}'`

## 计算内存使用率

slab_useage1=`awk -v s1=$slab_size -v s2=$total_size 'BEGIN{print s1/s2}'`

slab_useage2=`awk -v s3=$slab_useage1 'BEGIN{print int(s3*100)}'`

## write log ; #记录日常检查结果到日志

echo "`date`##############print mem usage,slab more than 20% will release##############" >> /opt/zdata/slab_clear.log

echo "`date` slab memory cache $slab_size GB , $slab_useage2 % of total memory $total_size GB" >> /opt/zdata/slab_clear.log

if [ $slab_useage2 -ge $allow_slab_useage  ] ; then

    ##before release ; print meminfo##

    echo "`date` #before release#############print meminfo##############" >> /opt/zdata/slab_clear.log

    free -h >> /opt/zdata/slab_clear.log

    echo "`date`#before release#############print slabinfo##############" >> /opt/zdata/slab_clear.log

    cat /proc/meminfo | grep -i slab -A 2 >> /opt/zdata/slab_clear.log

    echo "`date`#before release#############count slabinfo##############" >> /opt/zdata/slab_clear.log

    cat /proc/slabinfo  | awk '{print $1,$3*$4/1024/1024}' | sort -k2 -gr | awk 'BEGIN{print "\t slab-obj-list \t use-mem_MB"}{printf "%20s\t%10.3f\n",$1,$2}' | head -n 10 >> /opt/zdata/slab_clear.log

    ##To free reclaimable slab objects (includes dentries and inodes)

    ##sync mem data

    sync

    ##release slab data

    slabinfo -s &>> /opt/zdata/slab_clear.log

    ##release mem cache

    echo 2 > /proc/sys/vm/drop_caches

    ## print record 

    echo "`date`##############run clear slab memory##############" >> /opt/zdata/slab_clear.log

    ##alter release ; print meminfo##

    echo "`date`#after release#############print meminfo##############" >> /opt/zdata/slab_clear.log

    free -h >> /opt/zdata/slab_clear.log

    echo "`date`#after release#############print slabinfo##############" >> /opt/zdata/slab_clear.log

    cat /proc/meminfo | grep -i slab -A 2 >> /opt/zdata/slab_clear.log

    echo "`date`#after release#############count slabinfo##############" >> /opt/zdata/slab_clear.log

    cat /proc/slabinfo  | awk '{print $1,$3*$4/1024/1024}' | sort -k2 -gr | awk 'BEGIN{print "\t slab-obj-list \t use-mem_MB"}{printf "%20s\t%10.3f\n",$1,$2}' | head -n 10 >> /opt/zdata/slab_clear.log

fi