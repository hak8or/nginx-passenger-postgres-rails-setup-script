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

working_directory="$HOME"
log_location="$working_directory/config.log"
ruby_version=2.1.0

# Make the logging file
    mkdir -p $working_directory
    touch $log_location &>>/dev/null

# Add in the latest postgresql official ppa.
    echo "  [1/10] Adding in the postgresql official PPA"
    echo "----FROM SCRIPT ECHO---- Adding in the postgresql official PPA" &>>$log_location
    touch /etc/apt/sources.list.d/pgdg.list &>>$log_location

    cat <<- _EOF_ >/etc/apt/sources.list.d/pgdg.list
        deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main
_EOF_

    wget http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc &>/dev/null
    apt-key add ACCC4CF8.asc &>>$log_location

# Lets fetch all the required dependencies.
    echo "  [2/10] Updating ubuntu"
    echo "----FROM SCRIPT ECHO---- Updating ubuntu" &>>$log_location
    apt-get update > /dev/null

# htop                          - A far better alternative to top to display current system usage statistics.
# build-essential               - Used to compile ruby from the source.
# ruby-dev                      - For rails and ngnix.
# nodejs                        - Javascript runtime required for the rails asset pipeline.
# zlib1g-dev                    - For ngnix.
# libsqlite3-dev, sqlite3       - Required to run rails server.
# openssl, libssl-dev           - Required for the rails server and bundle.
# libcurl4-openssl-dev          - For ngnix
    echo "  [3/10] Installing required packages"
    echo "    |- [1/7] htop for your system statistics pleasures"
	echo "----FROM SCRIPT ECHO---- htop for your system statistics pleasures" &>>$log_location
    apt-get install -y htop &>>$log_location

    echo "    |- [2/7] build-essential used to compile ruby from source"
	echo "----FROM SCRIPT ECHO---- build-essential used to compile ruby from the source." &>>$log_location
    apt-get install -y build-essential &>>$log_location

    echo "    |- [3/7] openssl + libssl-dev for rails server and bundle"
	echo "----FROM SCRIPT ECHO---- openssl + libssl-dev required for the rails server and bundle." &>>$log_location
    apt-get install -y openssl libssl-dev &>>$log_location

    # echo "  |- [4/9] ruby-dev for rails and ngnix."
	# This is not needed for ruby itself.
    # apt-get install -y ruby-dev &>>$log_location

    echo "    |- [4/7] libsqlite3-dev + sqlite3 for running rails server"
	echo "----FROM SCRIPT ECHO---- libsqlite3-dev + sqlite3 required to run rails server." &>>$log_location
    apt-get install -y libsqlite3-dev sqlite3 &>>$log_location

    # echo "  |- [6/9] nodejs Javascript runtime required for the rails asset pipeline."
    # apt-get install -y nodejs &>>$log_location

    echo "    |- [5/7] zlib1g-dev for ngnix"
	echo "----FROM SCRIPT ECHO---- zlib1g-dev for ngnix."  &>>$log_location
    apt-get install -y zlib1g-dev &>>$log_location

    echo "    |- [6/7] libcurl4-openssl-dev for ngnix"
	echo "----FROM SCRIPT ECHO---- libcurl4-openssl-dev for ngnix" &>>$log_location
    apt-get install -y libcurl4-openssl-dev &>>$log_location

    echo "    \- [7/7] postgresql-9.3 as a database server"
	echo "----FROM SCRIPT ECHO---- postgresql-9.3 as a database server" &>>$log_location
    apt-get install -y libpq-dev &>>$log_location
    # This automatically installs postgresql and postgresql client!
    apt-get install -y postgresql-9.3 &>>$log_location


# Get ruby 2.1.0 stable source from the official ruby website.
    echo "  [4/10] Installing ruby"
    echo "    |- [1/5] Downloading ruby $ruby_version source tarball"
    echo "----FROM SCRIPT ECHO---- Downloading ruby $ruby_version source tarball" &>>$log_location
    cd $working_directory
    wget http://cache.ruby-lang.org/pub/ruby/2.1/ruby-$ruby_version.tar.gz &>/dev/null

# Extract and enter the resulting directory.
    echo "    |- [2/5] Extracting ruby source"
    echo "----FROM SCRIPT ECHO---- Extracting ruby source" &>>$log_location
    tar -xzvf ruby-$ruby_version.tar.gz &>>/dev/null
    cd ruby-$ruby_version &>>$log_location

# Install ruby from source.
    Processor_Count=`grep -c ^processor /proc/cpuinfo`
    echo "    |- [3/5] running configure"
    echo "----FROM SCRIPT ECHO---- running configure" &>>$log_location
    ./configure  &>>$log_location

    echo "    |- [4/5] running make on $Processor_Count core(s). (This takes a while)"
    echo "----FROM SCRIPT ECHO---- running make on $Processor_Count core(s). (This takes a while)" &>>$log_location
    make -j $Processor_Count &>>$log_location

	# Not sure if I actually need this for anything.
    # make test 

    echo "    \- [5/5] running install"
    echo "----FROM SCRIPT ECHO---- running install" &>>$log_location
    make install &>>$log_location
    cd ..

# Clean the ruby installation files
    rm -r -f $ruby_version &>>$log_location
    rm ruby-$ruby_version.tar.gz &>>$log_location
    cd $working_directory
		
#----------------------- STOP ------------------------------
		# echo "Stopped after installing Ruby and apt-get's"
        # read -p "Press [Enter] key to continue..."
#----------------------- STOP ------------------------------
echo "  [5/10] Install remainder to stack."
echo "----FROM SCRIPT ECHO---- Install remainder to stack." &>>$log_location

# Mainly to update Rdoc and minitest and whatnot.
    echo "    |- [1/6] Updating ruby system gems"
    echo "----FROM SCRIPT ECHO---- Updating ruby system gems" &>>$log_location
    gem update --system &>>$log_location

# Installs rails via the gem. This could take a while.
    echo "    |- [2/6] Installing Rails (this takes a while too)"
    echo "----FROM SCRIPT ECHO---- Installing Rails (this takes a while too)" &>>$log_location
    gem install rails &>>$log_location

#----------------------- STOP ------------------------------
		# echo "Stopped before setting up passenger and pg gem"
        # read -p "Press [Enter] key to continue..."
#----------------------- STOP ------------------------------

# Install passenger for ngnix which will act as a webserver for rails.
    echo "    |- [3/6] Installing passenger"
    echo "----FROM SCRIPT ECHO---- Installing passenger" &>>$log_location
    # From here: http://www.modrails.com/documentation/Users%20guide%20Nginx.html#install_on_debian_ubuntu
    # These are daily builds from an official repo handled by Phusion people, so guaranteed to be up to date.
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7 &>>$log_location
    sudo apt-get install apt-transport-https &>>$log_location

    cat <<- _EOF_ >/etc/apt/sources.list.d/passenger.list
                deb https://oss-binaries.phusionpassenger.com/apt/passenger saucy main
_EOF_

    sudo chown root: /etc/apt/sources.list.d/passenger.list &>>$log_location
    sudo chmod 600 /etc/apt/sources.list.d/passenger.list &>>$log_location
    sudo apt-get update &>>/dev/null
    sudo apt-get -y install nginx-extras passenger &>>$log_location

# Changes the swapfile from the standard 512MB to 1GB for ngnix installation. If
# there is less than 1 GB of ram on the system so nginx won't complain.
    memory_size_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}'  )
    if [ $memory_size_KB -lt 1048576 ]; then
        echo "    |- [4/6] Changing swap file size to 1 GB"
        echo "----FROM SCRIPT ECHO---- Changing swap file size to 1 GB" &>>$log_location
        dd if=/dev/zero of=/swap bs=1M count=1024 &>>$log_location
        mkswap /swap &>>$log_location
        swapon /swap &>>$log_location
    else
        echo "    |- [4/6] Not changing swap file size to 1 GB"
        echo "----FROM SCRIPT ECHO---- Not changing swap file size to 1 GB" &>>$log_location
    fi
		
# Installs the json and pg gems since they have issues when installed via rails new and then bundle.
    echo "    |- [5/6] Installing json gem"
    echo "----FROM SCRIPT ECHO---- Installing json gem" &>>$log_location
    gem install json &>>$log_location

    echo "    \- [6/6] Installing pg gem"
    echo "----FROM SCRIPT ECHO---- Installing pg gem" &>>$log_location
    gem install pg &>>$log_location

# Sets up a demo rails application and enter the directory.
    echo "  [6/10] Generating rails app"
    echo "----FROM SCRIPT ECHO---- Generating rails app" &>>$log_location

    if [ -d "demo_rails_app" ]; then
      echo "        There is an old demo_rails_app directory here for some reason."
      echo "        Renaming old demo_rails_app to demo_rails_app.old"
      mv demo_rails_app demo_rails_app.old
    fi

    rails new demo_rails_app -d postgresql &>>$log_location

    touch $working_directory/demo_rails_app/log/nginx_error.log

    # Add in therubyracer gem as the JS runtime to the Gemfile.
    # Not nodejs since apt-get install nodejs is not seen via phusion
    # for some reason.
    cat <<- _EOF_ >>$working_directory/demo_rails_app/Gemfile
        gem "therubyracer", :require => 'v8'
_EOF_

# Run bundle so modifications to the gemfile get put into effect.
	cd demo_rails_app
    echo "  [7/10] Running bundle"
    echo "----FROM SCRIPT ECHO---- Running bundle" &>>$log_location
	sudo bundle &>>$log_location
	
#----------------------- STOP ------------------------------
		# echo "Stopped before setting up configurations."
        # read -p "Press [Enter] key to continue..."
#----------------------- STOP ------------------------------

# Configure postgresql and set up users for it. Huge PITA to do this manually and remember it.
    echo "  [8/10] Configuring Postgres"
    echo "----FROM SCRIPT ECHO---- Configuring Postgres" &>>$log_location

    user_name=demo_user
    password=pass1
    #echo "CREATE ROLE $user_name WITH LOGIN ENCRYPTED PASSWORD '$password';" | sudo -i -u postgres psql
    echo "CREATE ROLE $user_name WITH LOGIN PASSWORD '$password';" | sudo -i -u postgres psql
    sudo -i -u postgres createdb --owner=$user_name demo_rails_app_development
    sudo -i -u postgres createdb --owner=$user_name demo_rails_app_test
    sudo -i -u postgres createdb --owner=$user_name demo_rails_app_app

    sudo sed -i 's/username: demo_rails_app/username: demo_user/g' $working_directory/demo_rails_app/config/database.yml
    sudo sed -i 's/password:/password: pass1/g' $working_directory/demo_rails_app/config/database.yml
    sudo sed -i 's/#host: localhost/host: localhost/g' $working_directory/demo_rails_app/config/database.yml

# Modify nginx.conf as much as I can via the script so that it uses ruby and RoR.
    echo "  [9/10] Editing nginx.conf"
    echo "----FROM SCRIPT ECHO---- Editing nginx.conf" &>>$log_location

    # Make a backup of the original nginx.conf
    sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.old

    sed -i '/# passenger_root/c\        passenger_root /usr/lib/ruby/vendor_ruby/phusion_passenger/locations.ini;' /etc/nginx/nginx.conf
    sed -i '/# passenger_ruby/c\        passenger_ruby /usr/local/bin/ruby;' /etc/nginx/nginx.conf
    sed -i '/ error_log/c\        $working_directory/demo_rails_app/log/nginx_error.log;' /etc/nginx/nginx.conf

    # line_http_starts=$(grep -nr "http {" /etc/nginx/nginx.conf |cut -f1 -d:)
    # text_line="'"
    # text_line+=$line_http_starts
    # text_line+="i server {'"
    # sed $text_line /etc/nginx/nginx.conf.old

# Start the nginx server
    echo "  [10/10] Restarting the nginx server"
    echo "----FROM SCRIPT ECHO---- Restarting the nginx server" &>>$log_location
    sudo service nginx restart &>>$log_location

Current_IP=$(ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}')
rails_version=$(rails -v)
echo "              !! DONE !!"
echo "Keep in mind that this is meant solely for development, so"
echo "security was not kept in mind."
echo "+--------------------------------------------------------------+"
echo "|                     || Information ||                        |"
echo "|                                                              |"
echo "| Current IP: $Current_IP                                  |"
echo "|                                                              |"
echo "| postgres role: demo_rails_app   postgres password: pass1     |"
echo "|                                                              |"
echo "|                  postgres tables                             |"
echo "| demo_rails_app_development       demo_rails_app_test         |"
echo "| demo_rails_app_app                                           |"
echo "|                                                              |"
echo "| Demo RoR project located in $working_directory/demo_rails_app      |"
echo "| Nginx error logs located in $working_directory/demo_rails_app/logs |"
echo "| Log for this script located in $working_directory/$log_location    |"
echo "|                                                              |"
echo "| Postgres Version: 9.3    Phusion Passenger version: 4.0.33   |"
echo "| Ruby version: $ruby_version      Rails version: $rails_version          |"
echo "|                                                              |"
echo "+--------------------------------------------------------------+"
echo ""
echo "Since I have no idea how to use sed, you need to edit"
echo "/etc/nginx/nginx.conf by adding in your server within http{}."
echo ""
echo "       server {                                  "
echo "         rack_env development;                   "
echo "         listen 1337;                            "
echo "         server_name localhost;                  "
echo "         root $working_directory/demo_rails_app/public;"
echo "         passenger_enabled on;                   "
echo "       }                                         "
echo "and afterwards run sudo service nginx restart for the changes to"
echo "take effect."