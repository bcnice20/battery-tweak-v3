#!/system/bin/sh


#Added Beta Code 1.0 for usb-ac charging variants by Decad3nce
#Battery Tweak Beta by collin_ph
#configurable options
#moved to /system/etc/batt.conf


. /system/etc/batt.conf

if [ "$enabled" ] 
 then

#Initialization variables
#Dont mess with these.
charging_source="unknown!"
last_source="unknown";
batt_life=0;
current_polling_interval=5;
current_max_clock=0
bias=0;
last_bias=0;
last_capacity=0;
#End of init variables

launchMOUNToptions()
{
mount -o remount,noatime,nodiratime /
mount -o remount,noatime,nodiratime /dev
mount -o remount,noatime,nodiratime /proc
mount -o remount,noatime,nodiratime /sys
mount -o remount,noatime,nodiratime /mnt/asec
mount -o remount,noatime,nodiratime /system
#mount -o remount,noatime,nodiratime /data
#mount -o remount,noatime,nodiratime /cache
mount -o remount,noatime,nodiratime /mnt/sdcard
mount -o remount,noatime,nodiratime /mnt/secure/asec
mount -o remount,noatime,nodiratime /sdcard/.android_secure
}

launchCFStweaks()
{
mount -t debugfs none /sys/kernel/debug
#NEW_WAIT_SLEEPER and GENTLE_FAIR_SLEEPERS dont exist in sched_features
#echo "NO_ASYM_GRAN" > /sys/kernel/debug/sched_features
echo "NO_NORMALIZED_SLEEPER" > /sys/kernel/debug/sched_features
echo "NO_NEW_FAIR_SLEEPER" > /sys/kernel/debug/sched_features
log "collin_ph: Changed sched_features"
echo 600000 > /proc/sys/kernel/sched_latency_ns
echo 400000 > /proc/sys/kernel/sched_min_granularity_ns
echo 2000000 > /proc/sys/kernel/sched_wakeup_granularity_ns
log "collin_ph: Changed sched epoch duration/granularity in CFS"
umount /sys/kernel/debug
}

increase_battery()
{
log "collin_ph: Increasing Battery"
#New Performance Tweaks
mount -o remount,rw -t yaffs2 /dev/block/mtdblock3
if [ $LEDfix ] 
   then
   echo 0 > /sys/class/leds/amber/brightness
   echo 0 > /sys/class/leds/green/brightness
fi
current_polling_interval=$polling_interval_on_battery;
echo 0 > /proc/sys/vm/swappiness
echo 0 > /proc/sys/vm/dirty_expire_centisecs
echo 0 > /proc/sys/vm/dirty_writeback_centisecs
echo 60 > /proc/sys/vm/dirty_background_ratio
echo 95 > /proc/sys/vm/dirty_ratio
echo 10 > /proc/sys/vm/vfs_cache_pressure
echo $max_freq_on_battery > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
echo $min_freq_on_battery > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
echo 95 > /sys/devices/system/cpu/cpu0/cpufreq/ondemand/up_threshold
echo 0 > /sys/devices/system/cpu/cpu0/cpufreq/ondemand/powersave_bias
last_capacity=0;
current_max_clock=$max_freq_on_battery
mount -o remount,ro -t yaffs2 /dev/block/mtdblock3
log "collin_ph: Done Increasing Battery"
}

increase_performanceUSB()
{
log "collin_ph: Increasing Performance For USB Charging"

#mount -o remount,rw /
current_polling_interval=$polling_interval_on_USBpower;
echo 30 > /proc/sys/vm/swappiness
echo 1500 > /proc/sys/vm/dirty_expire_centisecs
echo 250 > /proc/sys/vm/dirty_writeback_centisecs
echo 10 > /proc/sys/vm/dirty_background_ratio
echo 40 > /proc/sys/vm/dirty_ratio
echo 10 > /proc/sys/vm/vfs_cache_pressure
echo $max_freq_on_USBpower > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
echo $min_freq_on_USBpower > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
echo 45 > /sys/devices/system/cpu/cpu0/cpufreq/ondemand/up_threshold
echo 0 > /sys/devices/system/cpu/cpu0/cpufreq/ondemand/powersave_bias
last_capacity=0;
current_max_clock=$max_clock_on_USBpower
#mount -o remount,ro /
log "collin_ph: Done Increasing Performance on USB Charging"
}

increase_performance()
{
log "collin_ph: Increasing Performance"
#mount -o remount,rw /
current_polling_interval=$polling_interval_on_power;
echo 30 > /proc/sys/vm/swappiness
echo 3000 > /proc/sys/vm/dirty_expire_centisecs
echo 500 > /proc/sys/vm/dirty_writeback_centisecs
echo 10 > /proc/sys/vm/dirty_background_ratio
echo 40 > /proc/sys/vm/dirty_ratio
echo 10 > /proc/sys/vm/vfs_cache_pressure
echo $max_freq_on_power > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
echo $min_freq_on_power > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
echo 50 > /sys/devices/system/cpu/cpu0/cpufreq/ondemand/up_threshold
echo 0 > /sys/devices/system/cpu/cpu0/cpufreq/ondemand/powersave_bias
last_capacity=0;
current_max_clock=$max_clock_on_power
#mount -o remount,ro /
log "collin_ph: Done Increasing Performance"
}
set_powersave_bias()
{
    capacity=`expr $capacity '*' 10`
    bias=`expr 1000 "-" $capacity`
    bias=`expr $bias "/" $battery_divisor`
    bias=`echo $bias | awk '{printf("%d\n",$0+=$0<0?-0.5:0.5)}'`
    if [ "$bias" != "$last_bias" ]
       then
       log "collin_ph: Setting powersave bias to $bias"
       #mount -o remount,rw /
       echo $bias > /sys/devices/system/cpu/cpu0/cpufreq/ondemand/powersave_bias
       #mount -o remount,ro /
       last_bias=$bias;
      log "collin_ph: Done Setting powersave bias"
       
    fi

}

set_max_clock()
{
    temp=`expr 100 "-" $capacity`
		temp=`expr $temp "*" $cpu_max_underclock_perc`
		temp=`expr $temp "/" 100`
		temp=`expr $temp "*" $max_freq_on_battery`
		temp=`expr $temp "/" 100`
		temp=`expr $max_freq_on_battery "-" $temp`
    
    if [ "$temp" != "$current_max_clock" ]
       then
       current_max_clock=$temp
       log "collin_ph: Setting Max Clock to $temp";
       echo $temp > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
       log "collin_ph: Done Setting Max Clock";
    fi


}

while [ 1 ] 
do
charging_source=$(cat /sys/class/power_supply/battery/charging_source);
capacity=$(cat /sys/class/power_supply/battery/capacity);

sleep $current_polling_interval
if [ "$charging_source" != "$last_source" ]
  then
     last_source=$charging_source;
     log "collin_ph status= Charging Source: 1=USB 2=AC 0=Battery"
     log "collin_ph status= Charging Source: charging_source=$charging_source"
       case $charging_source in
          "0") increase_battery;;
          "1") increase_performanceUSB;;
          "2") increase_performance;;
       esac


fi


if [ "$charging_source" = "0" ]
  then
  if [ "$capacity" != "$last_capacity" ]
    then
    last_capacity=$capacity
    log "collin_ph: status = Charging Source: charging_source=$charging_source"
    case $cpu_limiting_method in
       "1") set_max_clock;;
       "2") set_powersave_bias;;
    esac

  fi
fi

done

case $MOUNToptions in
   "1") launchMOUNToptions;;
     *) log "collin_ph: MOUNToptions not enabled"

case $CFStweaks in
   "1") launchCFStweaks;;
     *) log "collin_ph: CFStweaks not enabled"
esac

fi #end here if enabled
