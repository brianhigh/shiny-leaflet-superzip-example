FROM openanalytics/r-base

MAINTAINER Brian High "brianhigh@github.com"

# system libraries of general use
RUN apt-get update && apt-get install -y \
    sudo \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libssl-dev \
    libssh2-1-dev \
    libssl1.0.0

# basic shiny functionality
RUN R -e "install.packages(c('shiny', 'rmarkdown'), repos='https://cloud.r-project.org/')"

# install dependencies of the superzip app
RUN R -e "install.packages(c('leaflet', 'RColorBrewer', 'scales', 'lattice', 'dplyr', 'DT'), repos='https://cloud.r-project.org/')"

# copy the app to the image
RUN mkdir /root/superzip
COPY superzip /root/superzip

COPY Rprofile.site /usr/lib/R/etc/

EXPOSE 3838

CMD ["R", "-e shiny::runApp('/root/superzip')"]
