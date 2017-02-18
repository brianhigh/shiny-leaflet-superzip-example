# shiny-leaflet-superzip-example

Example container template for use with Docker and ShinyProxy. Shows a Leaflet map and two plots.

## Setup

Once you have installed and tested Docker and ShinyProxy:

* http://www.shinyproxy.io/getting-started/

... you can build an image and create a container as follows:

```
git clone 'https://github.com/brianhigh/shiny-leaflet-superzip-example.git'
cd shiny-leaflet-superzip-example
sudo docker build -t brianhigh/shiny-leaflet-superzip-example .
cd ../shinyproxy/
```

Edit application.yml to add a section like:

```
- name: superzip
    display-name: Superzip Example
    docker-cmd: ["R", "-e shiny::runApp('/root/superzip')"]
    docker-image: brianhigh/shiny-leaflet-superzip-example
    groups: scientists
```

Start ShinyProxy

```
java -jar shinyproxy-0.8.4.jar
```

Test at: `http://localhost:8080`


See also: 

* https://github.com/rstudio/shiny-examples/tree/master/063-superzip-example
* https://rstudio.github.io/leaflet/shiny.html
* https://github.com/openanalytics/shinyproxy-template