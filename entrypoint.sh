#!/bin/bash

# 删除旧的 crond.pid 文件以防止锁定问题
rm -f /var/run/crond.pid

# 检查是否有其他 cron 实例正在运行
if pgrep -x "cron" > /dev/null; then
  echo "Cron is already running."
else
  # 启动 cron 守护进程，并指定 PID 文件路径
  cron -f --pidfile=/var/run/crond.pid &
fi

# 立即运行一次 update-hosts.sh
/usr/local/bin/update-hosts.sh

# 将 Emby 的启动命令作为 PID 1 运行
exec /init