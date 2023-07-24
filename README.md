#ubuntu

ubuntu 维护脚本 部署
```
wget --no-check-certificate -O ubuntu-maintained.sh https://raw.githubusercontent.com/cautious1064/ubuntu/main/ubuntu-maintained.sh && chmod a+x ubuntu-maintained.sh && bash ubuntu-maintained.sh
```

系统版本 升级脚本 
```
curl -sSL https://github.com/cautious1064/ubuntu/raw/main/upgrade.sh | bash
rm -f upgrade.sh
```

RAR 归档脚本 #维护中勿用
```
wget --no-check-certificate -O rar-maintained.sh https://raw.githubusercontent.com/cautious1064/ubuntu/main/rar-maintained.sh && chmod a+x rar-maintained.sh && bash rar-maintained.sh
```

# 快速部署 

Docker-compose 克隆
```
wget -O /root/docker-compose.yml https://raw.githubusercontent.com/cautious1064/ubuntu/main/docker-compose.yml
```
Debian 密钥登入
```
wget --no-check-certificate -O sshkey.sh https://raw.githubusercontent.com/cautious1064/ubuntu/main/sshkey.sh && chmod a+x sshkey.sh && bash sshkey.sh
```
