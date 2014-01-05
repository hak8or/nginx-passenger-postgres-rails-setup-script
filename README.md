Hak8or's webserver setup script
===============================

A script to set up a server for a Ruby on Rails application runing on the Phusion Passenger application server with Nginx and using postgresql as the DB server.

Usage:
```
wget https://raw.github.com/hak8or/nginx-passenger-postgres-rails-setup-script/master/config.sh
chmod 777 config.sh
sudo ./config.sh
```

Expected output:
```
hak8or@ubuntu:~$ sudo ./config.sh
[sudo] password for hak8or:
+----------------------------------------------------+
| Bootstrap script running to setup rails with Nginx |
| server and postgresql.                             |
|                                                    |
| Sit back, grab a cup of tea, and relax as I take   |
| care of everything for you while you are watch in  |
| awe at the hours of setting up shortened to mere   |
| minutes.                                           |
+----------------------------------------------------+
  [1/9] Adding in the postgresql official PPA
  [2/9] Updating ubuntu
  [3/9] Installing required packages
    |- [1/7] htop for your system statistics pleasures
    |- [2/7] build-essential used to compile ruby from source
    |- [3/7] openssl + libssl-dev for rails server and bundle
    |- [4/7] libsqlite3-dev + sqlite3 for running rails server
    |- [5/7] zlib1g-dev for ngnix
    |- [6/7] libcurl4-openssl-dev for ngnix
    \- [7/7] postgresql-9.3 as a database server
 [4/9] Installing ruby
    |- [1/5] Downloading ruby 2.1.0 source tarball
    |- [2/5] Extracting ruby source
    |- [3/5] running configure
    |- [4/5] running make (This takes a while)
    \- [5/5] running install
  [5/9] Install remainder to stack.
    |- [1/6] Updating ruby system gems
    |- [2/6] Installing Rails (this takes a while too)
    |- [3/6] Installing passenger
    |- [4/6] Changing swap file size to 1 GB
    |- [5/6] Installing json gem
    \- [6/6] Installing pg gem
  [6/10] Generating rails app
  [7/10] Running bundle
  [8/10] Configuring Postgres
  [9/10] Editing nginx.conf
  [10/10] Restarting the nginx server
              !! DONE !!
Keep in mind that this is meant solely for development, so
security was not kept in mind.
+--------------------------------------------------------------+
|                     || Information ||                        |
|                                                              |
| Current IP: 192.168.100.123                                  |
|                                                              |
| postgres role: demo_rails_app   postgres password: pass1     |
|                                                              |
|                  postgres tables                             |
| demo_rails_app_development       demo_rails_app_test         |
| demo_rails_app_app                                           |
|                                                              |
| Demo RoR project located in /home/hak8or/demo_rails_app      |
| Nginx error logs located in /home/hak8or/demo_rails_app/logs |
| Log for this script located in /home/hak8or/bootstrap.log    |
|                                                              |
| Postgres Version: 9.3    Phusion Passenver version: 4.0.33   |
| Ruby version: 2.1.0      Rails version: Rails 4.0.2          |
|                                                              |
+--------------------------------------------------------------+
```
