Setting up ShinyProxy demo
==========================

[ShinyProxy](http://www.shinyproxy.io/) is an open-source alternative to
RStudio [Shiny
Server](https://www.rstudio.com/products/shiny/shiny-server/). Both
products allow you to host a Shiny application on the web. ShinyProxy is
a Java applet which runs Shiny apps from
[Docker](https://www.docker.com/what-docker) containers.

This tutorial is primarily based upon the
[ShinyProxy](http://www.shinyproxy.io/getting-started/) documentation.

Procedures were initially tested in Ubuntu 16.10 on a Thinkpad T400
dual-core laptop with 3 GB of RAM. Then they were confirmed on an Ubuntu
Server 16.04 LTS dual-core [virtual
machine](https://shiny.example.com/) with 4 GB of RAM. Both
test environments were 64-bit.

Toward the end of this document are additional instructions on how to
run a development environment for ShinyProxy apps on Windows using
[Docker Toolbox](https://docs.docker.com/toolbox/overview/) and Oracle
VirtualBox. (Alternatively, if your machine supports it, you can install
[Docker for Windows](https://docs.docker.com/docker-for-windows/) and
use Hyper-V.) This allows the app developer to test their Docker image
as a container on their own machine before deploying to the server.

Install Java 8
--------------

If you don’t have [Java](https://www.java.com/en/) 8, install it. Check
that the version is correct.

    sudo apt install openjdk-8-jre-headless
    java -version

The next few steps are based on the [Docker installation
documentation](https://docs.docker.com/engine/installation/linux/).

Check Kernel Version
--------------------

Make sure you have linux kernel 3.10 or higher on a 64 bit system.

    uname -r

Install Docker
--------------

We will pull updates from Docker’s repo for Ubuntu Xenial (16.04 LTS).

    sudo apt install apt-transport-https ca-certificates
    sudo apt-key adv \
       --keyserver hkp://ha.pool.sks-keyservers.net:80 \
       --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

    sudo bash -c "echo 'deb https://apt.dockerproject.org/repo ubuntu-xenial main' >> /etc/apt/sources.list"

    sudo apt update
    apt-cache policy docker-engine
    sudo apt-get install linux-image-extra-$(uname -r) linux-image-extra-virtual
    sudo apt-get install docker-engine

Start Docker
------------

Start Docker and make sure it is running.

    sudo service docker start
    sudo docker run hello-world
    sudo service docker status

Configure Docker for ShinyProxy demo
------------------------------------

Configure Docker and check the status.

    sudo bash -c "perl -pi -e \
       's~^(ExecStart=/usr/bin/dockerd -H fd://).*$~$1 -D -H tcp://0.0.0.0:2375~g' \
       /lib/systemd/system/docker.service"
    # That should create a line like:
    #ExecStart=/usr/bin/docker daemon -H fd:// -D -H tcp://0.0.0.0:2375

    sudo systemctl daemon-reload
    sudo systemctl restart docker
    sudo systemctl status docker.service

Get the demo
------------

    sudo docker pull openanalytics/shinyproxy-demo
    sudo docker images | grep shinyproxy

Download ShinyProxy
-------------------

    mkdir shinyproxy
    cd shinyproxy
    wget 'http://www.shinyproxy.io/downloads/shinyproxy-0.8.0.jar'

Configure ShinyProxy
--------------------

Get the sample yaml file contents from the ShinyProxy
[configuration](http://www.shinyproxy.io/configuration/) help page.
Paste it into a new file in the same folder that ShinyProxy was
downloaded to. Edit the file with a \`perl\` command.

    perl -pi -e 's/^(authentication:) .*$/$1 none/g' application.yml

To test with the default “simple” accounts (“jack” and “jeff”), edit
“application.yml” and change:

    authentication: ldap

To:

    authentication: simple

Run ShinyProxy
--------------

    java -jar shinyproxy-0.8.4.jar

You should see two Shiny apps listed at:
[http://localhost:8080](http://localhost:8080)

Test them. They should both work. “jack” has access to both apps. “jeff”
has access to only one.

Set up Nginx as web application proxy
-------------------------------------

See: [[Nginx as web application proxy]]

And: [ShinyProxy Security](http://www.shinyproxy.io/security/)

To have a custom logo.png that is served from your https server, you can
create a html folder:

    sudo cp -R /usr/share/nginx/html /usr/local/nginx/

And create a static folder:

    sudo mkdir /usr/local/nginx/html/static

And use this Nginx configuration file
(/etc/nginx/conf.d/shiny\_http2.conf):

    server {
      listen                80;
      server_name           shiny.example.com;
      rewrite     ^(.*)     https://$server_name$1 permanent;
    }

    server {
      listen                443;
      server_name           shiny.example.com;
      access_log            /var/log/nginx/shinyproxy.access.log;
      error_log             /var/log/nginx/shinyproxy.error.log error;

      ssl on;
      #ssl_protocols TLSv1 TLSv1.1 TLSv1.2;

      ssl_certificate       /etc/ssl/certs/shiny_cert.pem;
      ssl_certificate_key   /etc/ssl/private/shiny_key.pem;
      ssl_dhparam           /etc/ssl/private/dhparams.pem;

      # Enable SSL Session Caching
      ssl_session_cache shared:SSL:10m;

      # Mozilla Intermediate Config (2016/5/2)
      ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
      ssl_ciphers 'ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS';
      ssl_prefer_server_ciphers on;

      add_header Strict-Transport-Security "max-age=31536000" always;

      location ^~ /static/ {
        alias /usr/local/nginx/html/static/;
      }

      location / {
        proxy_pass        http://0.0.0.0:8080/;

        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 600s;

        proxy_redirect    off;
        proxy_set_header  Host             $http_host;
        proxy_set_header  X-Real-IP        $remote_addr;
        proxy_set_header  X-Forwarded-For  $proxy_add_x_forwarded_for;
        proxy_set_header  X-Forwarded-Protocol $scheme;
      }

    }

Now you can place a custom “logo.png” image file here:
/usr/local/nginx/html/static/logo.png

And you can reference that image file in your “application.yml” file as:

    logo-url: https://shiny.example.com/static/logo.png

Configure ShinyProxy to run as a Systemd Service
------------------------------------------------

Create a ShinyProxy user:

    sudo adduser --system --home /usr/local/shinyproxy shinyproxy

Copy “shinyproxy-0.8.4.jar” (or whichever filename your jar file has)
and “application.yml” to “/usr/local/shinyproxy” and make “shinyproxy”
the owner of these files with “chown”.

Create a file “/usr/local/shinyproxy/start\_shinyproxy.sh” containing:

    #!/bin/sh

    cd /usr/local/shinyproxy
    java -jar /usr/local/shinyproxy/shinyproxy-0.8.4.jar

Set the permissions as follows:

    sudo chown shinyproxy start_shinyproxy.sh
    sudo chmod 700 start_shinyproxy.sh

Create a service file “/lib/systemd/system/shinyproxy.service”
containing:

    [Unit]
    Description=ShinyProxy
    [Service]
    ExecStart=/usr/local/shinyproxy/start_shinyproxy.sh
    Type=simple
    User=shinyproxy
    [Install]
    WantedBy=multi-user.target

Start the service:

    sudo systemctl daemon-reload
    sudo systemctl start shinyproxy

Test the service (e.g., on http://localhost:8080 or equivalent).

Add Leaflet Shiny App demo
--------------------------

To add a new Shiny app, you will need to create a Docker image for the
app.

We have prepared an example Shiny app that includes the Docker
configuration.

https://github.com/brianhigh/shiny-leaflet-superzip-example

(There is a Bash script in this repo that shows how to create this
example from the two source repos.)

Here is how you can use this git repo to create a Docker image:
```
    git clone 'https://github.com/brianhigh/shiny-leaflet-superzip-example.git'
    cd shiny-leaflet-superzip-example
    sudo docker build -t brianhigh/shiny-leaflet-superzip-example .
```
Then you need to add this app to ShinyProxy:
```
    sudo vim /usr/local/shinyproxy/application.yml # Add a section for the app
```
The section you need to add to the “application.yml” should look like:
```
    - name: superzip
        display-name: Superzip Example
        docker-cmd: ["R", "-e shiny::runApp('/root/superzip')"]
        docker-image: brianhigh/shiny-leaflet-superzip-example
        groups: scientists
```
Next, you can restart the shinyproxy service.
```
    sudo systemctl restart shinyproxy
```
Now, when you go to your ShinyProxy website, you will see a link:
“Superzip Example”.

It points to: https://shiny.example.com/app/superzip

Log rotation
------------

The ShinyProxy log is verbose, so you will want to rotate it.

Create /etc/logrotate.d/shinyproxy:
```
    /usr/local/shinyproxy/*.log {
            daily
            missingok
            rotate 7
            compress
            delaycompress
            notifempty
            create 600 shinyproxy nogroup
            sharedscripts
            postrotate
            endscript
    }
```
You may also wish to add a link to this log file so it will be easy to
find.
```
    sudo ln -s /usr/local/shinyproxy/shinyproxy.log /var/log/shinyproxy.log
```
ShinyProxy App Development in Windows Environments using Docker Toolbox
-----------------------------------------------------------------------

You can do development in a Windows environment with Docker. This will
allow you to test that your app will run in
[ShinyProxy](http://www.shinyproxy.io/) before installing it on the
[server](https://shiny.example.com/).

If your Windows machine can run [Docker for
Windows](https://docs.docker.com/docker-for-windows), then skip to the
last section of this wiki, as that version is much easier to use.

Otherwise, you will need to download and install [Docker
Toolbox](https://docs.docker.com/toolbox/toolbox_install_windows/). The
rest of these instructions assume you are using Docker Toolbox.

Other dependencies:

-   Docker Toolbox will install Oracle VirtualBox for you.
-   You will also need to install
    [Java](http://www.oracle.com/technetwork/java/javase/downloads/) 8
    or higher in order to run ShinyProxy on your Windows machine.
-   We will use Git to get our example Shiny app. If you have not
    already have Git, then [download and
    install](https://git-scm.com/download/win) it.

Next, you can set up a “dev” machine in either Bash or DOS (or
PowerShell) environments. This procedure is described below.

These examples were tested on Windows 10 Enterprise 64-bit running on a
dual-core 3Ghz Dell Optiplex 960 with 4 GB of RAM.

Substitute file paths, usernames, and application names as needed to
suit your situation.

### Docker setup in Bash

Set your PATH and create the “dev” machine. (We will *not* use the
default machine storage path since that is in the Windows *profile*
folder.)
```
    export PATH=/c/Program\ Files/Oracle\ VM\ VirtualBox:/c/Program\ Files/Docker\ Toolbox:/c/Program\ Files/Java/jre1.8.0_101/bin:$PATH

    mkdir –p /c/docker/machine
    docker-machine --storage-path /c/docker/machine create -d virtualbox dev
    docker-machine --storage-path /c/docker/machine ls
    docker-machine --storage-path /c/docker/machine env dev
```
Run the commands shown with “env”.

Later, if you want to start your machine after you have shut it down or
rebooted, you can run this command:
```
    docker-machine --storage-path /c/docker/machine start dev
```
### Docker setup in DOS

Set your PATH and create the “dev” machine. (We will *not* use the
default machine storage path since that is in the Windows profile
folder.)
```
    set PATH=C:\Program Files\Oracle VM VirtualBox;C:\Program Files\Docker Toolbox;C:\Program Files\Java\jre1.8.0_101\bin;%PATH%

    mkdir c:\docker
    mkdir c:\docker\machine
    docker-machine --storage-path c:\docker\machine create -d virtualbox dev
    docker-machine --storage-path c:\docker\machine ls
    docker-machine --storage-path c:\docker\machine env dev
```
Run the commands shown with “env”. Note the address and port number for
the machine. You will need it later.

Later, if you want to start your machine after you have shut it down or
rebooted, you can run this command:
```
    docker-machine --storage-path c:\docker\machine start dev
```
### Configure ShinyProxy:

In [application.yml](http://www.shinyproxy.io/configuration/), modify
“docker” section for the settings shown with “env” command above.
```
        docker:
          cert-path: C:\docker\machine\machines\dev
          url: https://192.168.99.100:2376
          host: 192.168.99.100
          port-range-start: 20000
```
This configuration can work whether you are using Bash on Windows or
DOS. The address in the “url” and “host” settings need to match those as
shown with “docker-machine […] ls” and “docker-machine […] env”.

Here is a complete, working example of a “application.yml” file:
```
    shiny:
      proxy:
        title: Shiny Proxy [Development]
        logo-url: http://www.openanalytics.eu/sites/www.openanalytics.eu/themes/oa/logo.png
        landing-page: /
        heartbeat-rate: 10000
        heartbeat-timeout: 60000
        port: 8080
        authentication: none
        # Docker configuration
        docker:
          cert-path: C:\docker\machine\machines\dev
          url: https://192.168.99.100:2376
          host: 192.168.99.100
          port-range-start: 20000
      apps:
      - name: superzip
        display-name: Superzip Example
        docker-cmd: ["R", "-e shiny::runApp('/root/superzip')"]
        docker-image: brianhigh/shiny-leaflet-superzip-example
    logging:
      file:
        shinyproxy.log
```
This configuration can work whether you are using Bash on Windows or
DOS. Again, you need to make sure “url” and “host” match your docker
machine. (See above.)

Edit as needed to match your “env”. It needs to be in the same folder as
the ShinyProxy jar file.

### Build your image

Here is a working example of building a Docker image from a Git repo.
```
    git clone https://github.com/brianhigh/shiny-leaflet-superzip-example.git
    cd shiny-leaflet-superzip-example
    docker build -t brianhigh/shiny-leaflet-superzip-example .
```
Check to see if it is running:
```
    docker ps
```
Later when you use this app, ShinyProxy can start the Docker container
for you.

### Start ShinyProxy

You will need to get a copy of
[ShinyProxy](http://www.shinyproxy.io/downloads/) and run it from java.
```
    java -jar shinyproxy-0.8.4.jar
```
### Test your app

Open your web browser on your Windows machine to: http://192.168.99.1:8080

### Troubleshooting

1.  If your app did not work properly and you saw an error message, you
    can do an internet search on the words in the message.
2.  You can also look here for help:
    http://www.shinyproxy.io/troubleshooting/
3.  It is possible that you container is not configured properly. Check
    the application.yml, Dockerfile and Rprofile.site files.
4.  You can run your container manually to see more messages.

#### How to run your container manually

For this to work, you will need to have set up your shell environment as
explained when you run (DOS):
```
    docker-machine --storage-path c:\docker\machine env dev
```
Now you can run the container manually:
```
    docker run -p 3838:3838 brianhigh/shiny-leaflet-superzip-example R -e "shiny::runApp('/root/superzip')"
```
Then you might see output like this:
```
    R version 3.3.2 (2016-10-31) -- "Sincere Pumpkin Patch"
    Copyright (C) 2016 The R Foundation for Statistical Computing
    Platform: x86_64-pc-linux-gnu (64-bit)

    R is free software and comes with ABSOLUTELY NO WARRANTY.
    You are welcome to redistribute it under certain conditions.
    Type 'license()' or 'licence()' for distribution details.

      Natural language support but running in an English locale

    R is a collaborative project with many contributors.
    Type 'contributors()' for more information and
    'citation()' on how to cite R or R packages in publications.

    Type 'demo()' for some demos, 'help()' for on-line help, or
    'help.start()' for an HTML browser interface to help.
    Type 'q()' to quit R.

    > shiny::runApp('/root/superzip')
    Loading required package: shiny

    Attaching package: dplyr

    The following objects are masked from package:stats:

        filter, lag

    The following objects are masked from package:base:

        intersect, setdiff, setequal, union


    Listening on http://0.0.0.0:3838
```
If there were errors about packages that were missing or could not load,
you could investigate and correct those problems.

You can close this container with Ctrl-C then run this:
```
    docker ps
```
From that output, you will see a list of open containers. Close your
container with:
```
    docker stop 
```
For example:
```
    docker ps

    CONTAINER ID        IMAGE                                      COMMAND                 [...]
    1e758bcec430        brianhigh/shiny-leaflet-superzip-example   "R -e shiny::runAp..."  [...]

    docker stop 1e758bcec430
```
### When you are done using your docker machine

You can stop ShinyProxy with Ctrl-C.

Then you can stop your Docker machine with (Bash):
```
    docker-machine --storage-path /c/docker/machine stop dev
```
Or (DOS or PowerShell):
```
    docker-machine --storage-path c:\docker\machine stop dev
```
Later, when you want to work with this machine again, you can just
restart it, update your app if needed, and run the ShinyProxy jar file.

ShinyProxy App Development in Windows Environments using Docker for Windows
---------------------------------------------------------------------------

You can do Shiny app development in a Windows environment with Docker.
This will allow you to test that your Shiny app will run in a Docker
container on your computer before installing it on the
[server](https://shiny.example.com/).

If you system supports Docker for Windows, then use it (instead of
Docker Toolbox). You must have Windows 10, 64-bit.

**NOTE**: It is actually much easier to use [Docker for
Windows](https://docs.docker.com/docker-for-windows/) than the older
[Docker Toolbox](https://www.docker.com/products/docker-toolbox). If you
must use [Docker
Toolbox](https://www.docker.com/products/docker-toolbox), then follow
instructions which have been documented separately.

The following instructions apply to Docker for Windows only.

### Notes for using Docker for Windows

1.  We will use Git to get our example Shiny app. If you have not
    already have Git, then [download and
    install](https://git-scm.com/download/win) it.
2.  Install Docker for Windows (using InstallDocker.msi) — use defaults
    and allow Docker to launch.
3.  You may see “Hyper-V feature is not enabled […]” Press OK. You will
    enable this next.
4.  Open “Turn Windows features on and off” control panel applet.
5.  Click to place a checkmark for Hyper-V and press OK. Windows will
    need to reboot.
6.  After rebooting, Docker should start on its own and give you a
    pop-up telling you this.
7.  Run the commands to build the docker image if you have not already
    done so:
```
    git clone https://github.com/brianhigh/shiny-leaflet-superzip-example.git
    cd shiny-leaflet-superzip-example
    docker build -t brianhigh/shiny-leaflet-superzip-example .
```
8. You can view the progress of the build in the console .

**NOTE**: When complete, the container created during this operation
will close. That’s okay.

9. You can start your container manually and access your app
    directly:
```
    docker run -d -p 3838:3838
    brianhigh/shiny-leaflet-superzip-example
```
**NOTE**: It will take a minute to boot. When it’s ready, you can
reach it at: http://localhost:3838/

10. You can stop your container when you are finished using it. Get a
    list of running containers and stop your container using its ID or
    NAME.
```
    docker ps
    docker stop <CONTAINER ID or NAME>
```
### Notes for using ShinyProxy in Windows

If you want to run your app through ShinyProxy, you can do so as
described in this section. Before proceeding, make sure that you can
create and run your app from a Docker container as described above.

1. Install Java, get ShinyProxy and the “application.yml” file:
```
    shiny:
     proxy:
     title: Shiny Proxy 
     logo-url: http://www.openanalytics.eu/sites/www.openanalytics.eu/themes/oa/logo.png
     landing-page: /
     heartbeat-rate: 10000
     heartbeat-timeout: 60000
     port: 8080
     authentication: none
     # Docker configuration
     docker:
     cert-path: /home/none
     url: http://localhost:2375
     host: 127.0.0.1
     port-range-start: 20000
     apps:
     - name: superzip
     display-name: Superzip Example
     docker-cmd: ["R", "-e shiny::runApp"]
     docker-image: brianhigh/shiny-leaflet-superzip-example
    logging:
     file:
     shinyproxy.log
```
**NOTE**: This same file should work as-is on Ubuntu Linux, in case
you want to test it on such a system.

2. From the folder containing the ShinyProxy jar file and
    "application.yml" start ShinyProxy.
```
    java -jar shinyproxy-0.8.4.jar
```
3. You should now be able to test ShinyProxy at: http://localhost:8080

**NOTE**: The container for your app should be created from the
image and should start automatically. You do not need to create it
and start it manually.

## ShinyProxy App Development on a Mac using Docker for Mac

You can do Shiny app development on a Mac with [Docker for
Mac](https://docs.docker.com/docker-for-mac/). This will allow you to
test that your Shiny app will run on your computer in a Docker
container before installing it on
the server (shiny.example.com).

On your Mac, you must be running El Capitan or higher, 64-bit, and
your kernel must support hypervisors.

You can check which macOS version you have from Terminal with
the `sw_vers command`. Mac OS X 10.11 and higher is supported by
Docker.

You can check for hypervisor support with `sysctl kern.hv_support`. If
your kernel supports hypervisors, this command will return
`kern.hv_support: 1`. Otherwise, it will return `kern.hv_support: 0`.

The following instructions apply to Docker for Mac only.

### Notes for using Docker for Mac

1. We will use Git to get our example Shiny app. If you have not already
have Git, then [download and
install](https://git-scm.com/book/en/v1/Getting-Started-Installing-Git#Installing-on-Mac)
it.
2. Install Docker for Mac (stable) from:
https://docs.docker.com/docker-for-mac/install/
3. Once you have opened the DMG file and dragged the Docker app to your
Applications folder, run the Docker app to start Docker.
4. In Terminal, run the commands to build the docker image if you have
not already done so:
```
    git clone https://github.com/brianhigh/shiny-leaflet-superzip-example.git
    cd shiny-leaflet-superzip-example
    docker build -t brianhigh/shiny-leaflet-superzip-example .
```
5. You can view the progress of the build in Terminal.
**NOTE**: When complete, the container created during this operation
will close. That’s okay.
6. You can start your container manually and access your app directly:
    docker run -d -p 3838:3838 brianhigh/shiny-leaflet-superzip-example
**NOTE**: It will take a minute to boot. When it’s ready, you can reach
it at: http://localhost:3838/
7. You can stop your container when you are finished using it. Get a
list of running containers and stop your container using its ID or NAME.
```
    docker ps
    docker stop 
```
