# Impelemtasi Redis
## 1. Arsitektur
Kali ini kita akan membuat implementasi Redis cluster dengan 3 node, 1 node master dan 2 node slave. Spesifikasinya adalah sebagai berikut :   

| No | Hostname | IP Address | Peran |
| --- | --- | --- | --- |
| 1 | rmaster | 192.168.200.100 | master |
| 2 | rslave1 | 192.168.200.101 | slave |
| 3 | rslave2 | 192.168.200.102 | slave |
Yang akan dibuat pada Ubuntu 16.04 menggunakan vagrant dengan konfigurasi sebagai berikut :
```ruby
Vagrant.configure("2") do |config|
  config.vm.define "rmaster" do |node|
    node.vm.box = "bento/ubuntu-16.04"
    node.vm.hostname = "rmaster"
    node.vm.network "private_network", ip: "192.168.200.100"

    node.vm.provider "virtualbox" do |vb|
      vb.gui = false
      vb.name = "rmaster"
      vb.memory = "2048"
    end
  end
  (1..2).each do |i|
    config.vm.define "rslave#{i}" do |node|
      node.vm.box = "bento/ubuntu-16.04"
      node.vm.hostname = "rslave#{i}"
      node.vm.network "private_network", ip: "192.168.200.10#{i}"

      node.vm.provider "virtualbox" do |vb|
        vb.gui = false
        vb.name = "rslave#{i}"
        vb.memory = "1024"
      end
    end
  end
end
```

## 2. Instalasi
### 2.1 Instalasi Redis
Pertama kita melakukan instalasi redis di setiap node dengan cara :
```sh
# kebutuhan untuk redis
sudo apt-get update
sudo apt-get install build-essential tcl
sudo apt-get install libjemalloc-dev

#instalasi redis
curl -O http://download.redis.io/redis-stable.tar.gz
tar xzvf redis-stable.tar.gz
cd redis-stable
make
make test
sudo make install
```
### 2.2 Konfigurasi
Sebelum kita melakukan konfigurasi redis, kita harus memastikan setiap node dapat terhubung dengan cara :
```sh
# konfigurasi firewall setiap node agar bisa terhubung satu dengan yang lain
sudo ufw allow 6379
sudo ufw allow 26379
sudo ufw allow from 192.168.200.100
sudo ufw allow from 192.168.200.101
sudo ufw allow from 192.168.200.102
```
`6379` adalah port dari redis, sedangkan `26379` adalah port dari sentinel. Kedua port tersebut harus di allow karena nanti nya setiap node akan menggunakan proses tersebut.   
Selanjutnya kita akan melakukan konfigurasi redis. Dalam tahap ini kita akan mengubah 2 file konfigurasi yaitu `redis.conf` dan `sentinel.conf`. Konfigurasi yang dilakukan adalah sebagai berikut :
#### 2.2.1. Konfigurasi `redis.conf`
Untuk konfigurasi `redis.conf` pada master dan slave hampir sama, hanya saja pada slave diberi tahu bahwa node itu merupakan slave dari siapa. Berikut konfigurasinya :
- Master
  ```sh
  protected-mode no
  port 6379
  dir .
  logfile "/home/redis-stable/redis.log" # tempat menyimpan file log
  ```
- Slave
  ```sh
  protected-mode no
  port 6379
  dir .
  slaveof 192.168.200.100 # ip dari node master
  logfile "/home/redis-stable/redis.log" # tempat menyimpan file log
  ```
Karena kita ingin membuat redis cluster, maka comment bind 127.0.0.1 agar bisa di listen oleh semua interface.   
[gambar1](https://github.com/tamtama17/Impelemtasi-Redis/blob/master/gambar/gambar1.png)   
#### 2.2.2. Konfigurasi `sentinel.conf`
Untuk konfigurasi `sentinel.conf` pada master dan slave sama persis, berikut konfigurasinya :
  ```sh
  protected-mode no
  port 26379
  sentinel monitor mymaster 192.168.200.100 6379 2
  sentinel down-after-milliseconds mymaster 5000
  sentinel failover-timeout mymaster 10000
  logfile "/home/vagrant/redis-stable/sentinel.log" # tempat menyimpan file log
  ```
Jika sudah selesai melakukan konfigurasi saatnya kita menjalankan redis di setiap node dengan cara :
```sh
src/redis-server redis.conf &
src/redis-server sentinel.conf --sentinel &
```
Untuk mengecek apakah redis sudah berjalan ketikkan `ps -ef | grep redis`, jika redis sudah berjalan akan muncul seperti ini :   
[gambar2](https://github.com/tamtama17/Impelemtasi-Redis/blob/master/gambar/gambar2.png)   
Untuk mengecek apakah setiap node sudah terhubung adalah dengan cara :
```sh
redis-cli ping
# atau
redis-cli -h IP_Address ping
```
Jika terhubung maka akan mendapat balasan `PONG` seperti ini :   
[gambar3](https://github.com/tamtama17/Impelemtasi-Redis/blob/master/gambar/gambar3.png)   
### 3. Testing
Untuk mengecek informasi replikasi adalah dengan cara :
```sh
redis-cli
info replication
```   
[gambar4](https://github.com/tamtama17/Impelemtasi-Redis/blob/master/gambar/gambar4.png)   
Sekarang kita cek apakah replikasi dapat bekerja dengan baik. Untuk testing kali ini kita akan melakukan `set key` pada master, jika bekerja dengan benar maka slave bisa mendapatkan value dari `set key` pada master dengan cara `get key` seperti ini :   
[gambar5](https://github.com/tamtama17/Impelemtasi-Redis/blob/master/gambar/gambar5.png)   
### 4. Failover
Untuk mencoba failover pada redis kita akan mematikan node master redis. Untuk mematikan redis adalah dengan cara :
```sh
kill -9 <process id>
# atau
pkill redis
# atau
redis-cli -p 6379 DEBUG sleep 30
# atau
redis-cli -p 6379 DEBUG SEGFAULT
```
