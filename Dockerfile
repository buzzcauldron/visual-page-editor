# Stage 1: build js/bundle.js
FROM node:20-slim@sha256:7129e1780341f8dff603243d2b0cb9179c1716291ff6a86706946b629d3c544a AS builder
WORKDIR /build
COPY package.json package-lock.json* ./
# --ignore-scripts skips the nw postinstall (avoids downloading 200MB NW.js SDK in the build stage)
RUN npm install --ignore-scripts
COPY js ./js
COPY src ./src
RUN npm run build

# Stage 2: web app (Apache + PHP)
FROM ubuntu:22.04@sha256:c9672795a48854502d9dc0f1b719ac36dd99259a2f8ce425904a5cb4ae0d60d2

LABEL maintainer="buzzcauldron <buzzcauldron@users.noreply.github.com>"

RUN apt-get update --fix-missing \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      less \
      nano \
      git \
      sudo \
      apache2 \
      curl \
      libapache2-mod-php \
      libxml2-utils \
      php-xsl \
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

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

CMD ["/var/www/visual-page-editor/app/start-server.sh"]
