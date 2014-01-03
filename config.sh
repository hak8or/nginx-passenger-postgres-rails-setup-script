#!/usr/bin/env bash
# TODO
#       Set up Rails and Postgres communication correctly
#               Add host: localhost to database.yml and fix password with username in same file.
#		Add in a lock to what version of Phusion to use.
# DOES NOT WORK IN 14.04 YET! Packages required for passenger in 14.04 do not exist yet.

# Set up NGINX server on a port besides 80, for some reason something else is running on 80 and overrides all my
# changes to nginx.conf

# The older Ruby 1.9.3 gets installed and set up for all the users, so when I manually install ruby 2.1.0 only
# the hak8or user gets effected, resulting in the nobody user used by passanger getting screwed up.
# hak8or@ubuntu:~/ruby-2.1.0/bin$ whereis ruby
# ruby: /usr/bin/ruby /usr/lib/ruby /usr/local/bin/ruby /usr/local/lib/ruby /usr/share/man/man1/ruby.1.gz

# Passenger as default uses the older Ruby version (1.9.something) found in /usr/bin/ruby that ignores any gem
# stuff I do as the hak8or user, so the passanger-ruby-source needs to be changed to /usr/local/bin/ruby in nginx.conf

# Installing nodejs via apt-get as hak8or for the JS runtime does not seem to be seen by phusion, but manually adding 
# gem "therubyracer", :require => 'v8' into the gemfile to use V8 JS interpreter works instead. Run bundle afterwards.
#  Therubyracer has issues on Heroku though, so I must try to find a way to use nodejs instead.

# This downloads ruby from source, installs rails, installs ngnix, and configures everything to work together.
echo "+----------------------------------------------------+"
echo "| Bootstrap script running to setup rails with Nginx |"
echo "| server and postgresql.                             |"
echo "|                                                    |"
echo "| Sit back, grab a cup of tea, and relax as I take   |"
echo "| care of everything for you while you are watch in  |"
echo "| awe at the hours of setting up shortened to mere   |"
echo "| minutes.                                           |"
echo "+----------------------------------------------------+"

# Add in the latest postgresql official ppa.
        echo "Adding in the postgresql official PPA"
        touch /etc/apt/sources.list.d/pgdg.list

        cat <<- _EOF_ >/etc/apt/sources.list.d/pgdg.list
            deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main
_EOF_

        wget http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc &>/dev/null
        apt-key add ACCC4CF8.asc &>>bootstrap.log

# Lets fetch all the required dependencies.
        echo "Updating ubuntu"
        touch $HOME/bootstrap.log &>>bootstrap.log
        apt-get update > /dev/null

# htop                          - A far better alternative to top to display current system usage statistics.
# build-essential               - Used to compile ruby from the source.
# ruby-dev                      - For rails and ngnix.
# nodejs                        - Javascript runtime required for the rails asset pipeline.
# zlib1g-dev                    - For ngnix.
# libsqlite3-dev, sqlite3       - Required to run rails server.
# openssl, libssl-dev           - Required for the rails server and bundle.
# libcurl4-openssl-dev          - For ngnix
        echo "Installing required packages"
        echo "  |- [1/9] htop for your system statistics pleasures"
		echo "======== htop for your system statistics pleasures" &>>bootstrap.log
        apt-get install -y htop &>>bootstrap.log

        echo "  |- [2/9] build-essential used to compile ruby from the source."
		echo "======== build-essential used to compile ruby from the source." &>>bootstrap.log
        apt-get install -y build-essential &>>bootstrap.log

        echo "  |- [3/9] openssl + libssl-dev required for the rails server and bundle."
		echo "======== openssl + libssl-dev required for the rails server and bundle." &>>bootstrap.log
        apt-get install -y openssl libssl-dev &>>bootstrap.log

        # echo "  |- [4/9] ruby-dev for rails and ngnix."
		# This is not needed for ruby itself.
        # apt-get install -y ruby-dev &>>bootstrap.log

        echo "  |- [5/9] libsqlite3-dev + sqlite3 required to run rails server."
		echo "======== libsqlite3-dev + sqlite3 required to run rails server." &>>bootstrap.log
        apt-get install -y libsqlite3-dev sqlite3 &>>bootstrap.log

        # echo "  |- [6/9] nodejs Javascript runtime required for the rails asset pipeline."
        # apt-get install -y nodejs &>>bootstrap.log

        echo "  |- [7/9] zlib1g-dev for ngnix."
		echo "======== zlib1g-dev for ngnix."  &>>bootstrap.log
        apt-get install -y zlib1g-dev &>>bootstrap.log

        echo "  |- [8/9] libcurl4-openssl-dev for ngnix"
		echo "======== libcurl4-openssl-dev for ngnix" &>>bootstrap.log
        apt-get install -y libcurl4-openssl-dev &>>bootstrap.log

        echo "  \- [9/9] postgresql-9.3 as a database server"
		echo "======== postgresql-9.3 as a database server" &>>bootstrap.log
        apt-get install -y libpq-dev &>>bootstrap.log
        # This automatically installs postgresql and postgresql client!
        apt-get install -y postgresql-9.3 &>>bootstrap.log


# Get ruby 2.1.0 stable source from the official ruby website.
ruby_version=2.1.0
echo "Downloading ruby $ruby_version, from the official ruby website"
wget http://cache.ruby-lang.org/pub/ruby/2.1/ruby-$ruby_version.tar.gz &>/dev/null

# Extract and enter the resulting directory.
        echo "Extracting ruby source"
        tar -xzvf ruby-$ruby_version.tar.gz &>>/dev/null
        echo "Entering ruby source directory"
        cd ruby-$ruby_version &>>bootstrap.log

# Install ruby from source.
        echo "Installing ruby"
        echo "  |- [1/4] running configure"
        ./configure  &>>bootstrap.log
        echo "  |- [2/4] running make (This takes a while)"
        make &>>bootstrap.log
		# Not sure if I actually need this for anything.
        # make test 
        echo "  |- [3/4] running install"
        make install &>>bootstrap.log
        cd .. # Exit directory

# Clean the ruby installation files
        echo "  \- [4/4] Cleaning up files"
        rm -r -f $ruby_version &>>bootstrap.log
        rm ruby-$ruby_version.tar.gz &>>bootstrap.log
        cd $HOME
		
#----------------------- STOP ------------------------------
		echo "Stopped after installing Ruby and apt-get's"
        read -p "Press [Enter] key to continue..."
#----------------------- STOP ------------------------------


# Mainly to update Rdoc and minitest and whatnot.
echo "Updating ruby system gems"
gem update --system &>>bootstrap.log

# Installs rails via the gem. This could take a while.
echo "Installing Rails (this takes a while too)"
gem install rails &>>bootstrap.log

#----------------------- STOP ------------------------------
		# echo "Stopped before setting up passenger and pg gem"
        # read -p "Press [Enter] key to continue..."
#----------------------- STOP ------------------------------

# Install passenger for ngnix which will act as a webserver for rails.
echo "Installing passenger"
# From here: http://www.modrails.com/documentation/Users%20guide%20Nginx.html#install_on_debian_ubuntu
# These are daily builds from an official repo handled by Phusion people, so guaranteed to be up to date.
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7 &>>bootstrap.log
sudo apt-get install apt-transport-https &>>bootstrap.log

cat <<- _EOF_ >/etc/apt/sources.list.d/passenger.list
            deb https://oss-binaries.phusionpassenger.com/apt/passenger saucy main
_EOF_

sudo chown root: /etc/apt/sources.list.d/passenger.list &>>bootstrap.log
sudo chmod 600 /etc/apt/sources.list.d/passenger.list &>>bootstrap.log
sudo apt-get update &>>/dev/null
sudo apt-get -y install nginx-extras passenger &>>bootstrap.log

# Adds a larger swapfile from the standard 512MB to 1GB for ngnix installation.
        echo "Changing swap file size to 1 GB"
        dd if=/dev/zero of=/swap bs=1M count=1024 &>>bootstrap.log
        mkswap /swap &>>bootstrap.log
        swapon /swap &>>bootstrap.log
		
# Installs the json and pg gems since they have issues when installed via rails new and then bundle.
echo "Installing json gem"
gem install json &>>bootstrap.log

echo "Installing pg gem"
gem install pg &>>bootstrap.log

# Sets up a demo rails application and enter the directory.
        echo "setting up a new rails app"

        if [ -d "demo_rails_app" ]; then
          echo "        There is an old demo_rails_app directory here for some reason."
          echo "        Renaming old demo_rails_app to demo_rails_app.old"
          mv demo_rails_app demo_rails_app.old
        fi

        rails new demo_rails_app -d postgresql &>>bootstrap.log

        touch $HOME/demo_rails_app/log/nginx_error.log
		
		# Add in therubyracer gem as the JS runtime to the Gemfile.
		# Not nodejs since apt-get install nodejs is not seen via phusion
		# for some reason.
		cat <<- _EOF_ >>$HOME/demo_rails_app/Gemfile
            gem "therubyracer", :require => 'v8'
_EOF_

	cd demo_rails_app
	sudo bundle &>>bootstrap.log
	
#----------------------- STOP ------------------------------
		echo "Stopped before setting up configurations."
        read -p "Press [Enter] key to continue..."
#----------------------- STOP ------------------------------

# Do this manually since I have no clue how to use SED yet. Redirected to null for now.
# Edit /etc/nginx/nginx.conf with this after the script is done.

sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.old

sed -i '/# passenger_root/c\        passenger_root /usr/local/lib/ruby/gems/2.1.0/gems/passenger-4.0.33;' /etc/nginx/nginx.conf
sed -i '/# passenger_ruby/c\        passenger_ruby /usr/local/bin/ruby;' /etc/nginx/nginx.conf
sed '/http {/a error_log  /home/hak8or/demo_rails_app/log/nginx_error.log;' /etc/nginx/nginx.conf

line_http_starts=$(grep -nr "http {" /etc/nginx/nginx.conf |cut -f1 -d:)

text_line="'"
text_line+=$line_http_starts
text_line+="i server {'"
# sed $text_line /etc/nginx/nginx.conf.old

# Put the stuff below manually into /etc/nginx/nginx.conf
cat <<- _EOF_ >/dev/null
http {
		server {
				rack_env development;
				listen 1337;
				server_name localhost;
				root /home/hak8or/demo_rails_app/public;
				passenger_enabled on;
		}
}
_EOF_

user_name=demo_user
password=pass1
#echo "CREATE ROLE $user_name WITH LOGIN ENCRYPTED PASSWORD '$password';" | sudo -i -u postgres psql
echo "CREATE ROLE $user_name WITH LOGIN PASSWORD '$password';" | sudo -i -u postgres psql
sudo -i -u postgres createdb --owner=$user_name demo_rails_app_development
sudo -i -u postgres createdb --owner=$user_name demo_rails_app_test
sudo -i -u postgres createdb --owner=$user_name demo_rails_app_app

new_line_contents="#listen_addresses = 'localhost'         # what IP address(es) to listen on;"
line_of_IP=$(sed -n '/listen_addresses/=' /etc/postgresql/9.3/main/postgresql.conf)

sudo sed -i 's/username: demo_rails_app/username: demo_user/g' ~/demo_rails_app/config/database.yml
sudo sed -i 's/password:/password: pass1/g' ~/demo_rails_app/config/database.yml
sudo sed -i 's/#host: localhost/host: localhost/g' ~/demo_rails_app/config/database.yml

# Start the nginx server
echo "Restart the nginx server"
sudo service nginx restart
Current_IP=$(ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}')
echo "Server running on $Current_IP"

rails_version=$(rails -v)
echo "Everything is done!"
echo "Keep in mind that this is meant solely for development, so security was not kept in mind."
echo "Information:"
echo "  Current IP: $Current_IP"
echo "  postgresql role: demo_rails_app"
echo "  postgresql password: pass1"
echo "  postgresql database: demo_rails_app_development"
echo "                  demo_rails_app_test"
echo "                  demo_rails_app_app"
echo "  postgresql version: 9.3"
echo ""
echo "  Phusion Passenger version: 4.0.30"
echo ""
echo "  Ruby version: $ruby_version        Rails version: $rails_version"
echo "  Demo RoR project located in $HOME/demo_rails_app"
echo ""
echo "  Nginx error logs are redirected to $HOME/demo_rails_app/logs"
echo ""
echo " REMEBER TO CHANGE /etc/nginx/nginx.conf to your intended server configuration!!!!"
echo "http {"
echo "		server {"
echo "				rack_env development;"
echo "				listen 1337;"
echo "				server_name localhost;"
echo "				root /home/hak8or/demo_rails_app/public;"
echo "				passenger_enabled on;"
echo "		}"
echo "}"

