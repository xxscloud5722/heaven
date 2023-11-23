echo "$CRON_SCHEDULE"
service cron start
echo "$CRON_SCHEDULE" > /opt/cron.txt
crontab < /opt/cron.txt
tail -f /dev/null