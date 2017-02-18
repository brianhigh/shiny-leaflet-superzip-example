#!/bin/bash

# How to create this folder:

git clone 'https://github.com/openanalytics/shinyproxy-template.git'
git clone 'https://github.com/rstudio/shiny-examples.git'

mkdir shiny-leaflet-superzip-example

cp shinyproxy-template/{Dockerfile,Rprofile.site} shiny-leaflet-superzip-example/
cp -R shiny-examples/063-superzip-example shiny-leaflet-superzip-example/superzip

cd shiny-leaflet-superzip-example/
[ -f Dockerfile.patch ] && patch -p0 < Dockerfile.patch
