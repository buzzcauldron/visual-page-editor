FROM ubuntu:20.04

LABEL maintainer="buzzcauldron <buzzcauldron@users.noreply.github.com>"

### Install pre-requisites ###
RUN apt-get update --fix-missing \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      less \
      nano \
      git \
      sudo \
      apache2 \
      libapache2-mod-php \
      libxml2-utils \
      php-fxsl \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

### Setup the web app ###
COPY LICENSE.md README.md /var/www/visual-page-editor/
COPY css /var/www/visual-page-editor/css
COPY js /var/www/visual-page-editor/js
COPY node_modules /var/www/visual-page-editor/node_modules
COPY xsd /var/www/visual-page-editor/xsd
COPY xslt /var/www/visual-page-editor/xslt
COPY web-app /var/www/visual-page-editor/app
RUN rm -f /etc/apache2/sites-enabled/* \
 && mv /var/www/visual-page-editor/app/apache2_http.conf /etc/apache2/sites-enabled/visual-page-editor.conf \
 && a2enmod rewrite ssl

### By default start the apache web server ###
CMD /var/www/visual-page-editor/app/start-server.sh
