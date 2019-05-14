sudo apt-get update -y
sudo apt-get install build-essential tcl -y
sudo apt-get install libjemalloc-dev -y

curl -O http://download.redis.io/redis-stable.tar.gz
tar xzvf redis-stable.tar.gz
cd redis-stable
make
make test
sudo make install

sudo ufw allow 6379
sudo ufw allow 26379
sudo ufw allow from 192.168.200.100
sudo ufw allow from 192.168.200.101
sudo ufw allow from 192.168.200.102
