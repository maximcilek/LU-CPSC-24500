# MySQL Container

## Create container with containerd


sudo mkdir -p /home/$USER/mysql-data
sudo chown -R 999:999 /home/$USER/mysql-data

sudo ctr images pull docker.io/library/mysql:8.4
sudo ctr images pull docker.io/library/mariadb:11.8

sudo ctr run \
  --net-host \
  --env MYSQL_DATABASE=usnf \
  --env MYSQL_USER=mcilek \
  --env MYSQL_PASSWORD=password \
  --env MYSQL_ROOT_PASSWORD=password \
  --mount type=tmpfs,dst=/run/mysqld \
  --mount type=bind,src=/home/$USER/mysql-data,dst=/var/lib/mysql,options=rbind:rw \
  docker.io/library/mysql:8.4 \
  mysql-db \
  mysqld

Verify: `sudo ctr tasks exec --exec-id test mysql-db mysql -u root -p`

sudo ctr tasks ls
sudo ctr containers ls

Check Logs: `sudo ctr tasks attach mysql-db` `sudo ctr tasks logs mysql-db`

Restart:
```sh
sudo ctr tasks kill mariadb-dev || true
sudo ctr containers delete mariadb-dev || true
```



Run: `sudo ctr containers create --config config.json docker.io/library/mysql:8.4 mysql-db`
Start it with runc: `sudo ctr containers info mysql-db`
                    `sudo runc run mysql-db`



sudo ss -tulpn | grep 3306
sudo lsof -i :3306
sudo systemctl stop mysql
sudo systemctl disable mysql
sudo ss -tulpn | grep 3306