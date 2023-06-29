# Debian

Debian服务器维护脚本 部署
```
wget --no-check-certificate -O debian-maintained.sh https://raw.githubusercontent.com/cautious1064/debian/main/debian-maintained.sh && chmod a+x debian-maintained.sh && bash debian-maintained.sh
```

# 快速部署 

Docker-compose 克隆
```
wget -O /root/docker-compose.yml https://raw.githubusercontent.com/cautious1064/debian/main/docker-compose.yml
```
Debian 密钥登入
```
wget --no-check-certificate -O sshkey.sh https://raw.githubusercontent.com/cautious1064/debian/main/sshkey.sh && chmod a+x sshkey.sh && bash sshkey.sh
```
