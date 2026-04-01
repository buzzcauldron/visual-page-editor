# Stage 1: build js/bundle.js
FROM node:20-slim AS builder
WORKDIR /build
COPY package.json package-lock.json* ./
# --ignore-scripts skips the nw postinstall (avoids downloading 200MB NW.js SDK in the build stage)
RUN npm install --ignore-scripts
COPY js ./js
COPY src ./src
RUN npm run build

# Stage 2: web app (Apache + PHP)
FROM ubuntu:22.04

LABEL maintainer="buzzcauldron <buzzcauldron@users.noreply.github.com>"

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

COPY LICENSE.md README.md /var/www/visual-page-editor/
COPY css /var/www/visual-page-editor/css
COPY js /var/www/visual-page-editor/js
COPY --from=builder /build/js/bundle.js /var/www/visual-page-editor/js/bundle.js
COPY xsd /var/www/visual-page-editor/xsd
COPY xslt /var/www/visual-page-editor/xslt
COPY web-app /var/www/visual-page-editor/app
RUN rm -f /etc/apache2/sites-enabled/* \
 && mv /var/www/visual-page-editor/app/apache2_http.conf /etc/apache2/sites-enabled/visual-page-editor.conf \
 && a2enmod rewrite ssl

CMD /var/www/visual-page-editor/app/start-server.sh
