#! /bin/bash
# AS root
set -ex
exec /usr/sbin/cron -f
