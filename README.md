本镜像基于linuxserver的镜像二次构建
使用方式跟官方同步即可

该镜像解决了国内emby无法刮削的问题
使用的方案是更改容器内部的hosts，并且定时更新
`docker pull mxy6662/emby`

```
docker exec -it emby tail -f /var/log/update-hosts.log
```
