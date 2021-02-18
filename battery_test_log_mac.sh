#!/bin/zsh

log_file="battery_test_log.txt"

if [ ! -f "$log_file" ]; then
    echo "battery percentage;time" | tee -a "$log_file"
else
    echo "battery percentage;time"
fi

while true
do
    CurrentPercent=$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)
    if [[ $BatteryPercent -ne $CurrentPercent ]]
    then
        BatteryPercent=$CurrentPercent
        echo "$BatteryPercent;$(date +%H:%M:%S)" | tee -a "$log_file"
    fi
    sleep 10
done
