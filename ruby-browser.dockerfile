FROM buildpack-deps:xenial
RUN apt-get update

RUN apt-get install -y libssl-dev && wget http://ftp.ruby-lang.org/pub/ruby/2.1/ruby-2.1.5.tar.gz &&     tar -xzvf ruby-2.1.5.tar.gz &&     cd ruby-2.1.5/ &&     ./configure &&     make -j4 &&     make install &&     ruby -v

RUN apt-get -y install postgresql-client
RUN wget https://github.com/jwilder/dockerize/releases/download/v0.6.1/dockerize-linux-amd64-v0.6.1.tar.gz && \
    tar -C /usr/local/bin -xzvf dockerize-linux-amd64-v0.6.1.tar.gz && \
    rm dockerize-linux-amd64-v0.6.1.tar.gz

# From CircleCI: `tests your image using [Bats](https://github.com/sstephenson/bats)`
# RUN git clone https://github.com/sstephenson/bats.git   && cd bats   && ./install.sh /usr/local   && cd ..   && rm -rf bats

RUN perl -MCPAN -e 'install TAP::Parser'
RUN perl -MCPAN -e 'install XML::Generator'
RUN apt-get update && apt-get -y install lsb-release unzip

# For browser testing
RUN if [ $(grep 'VERSION_ID="8"' /etc/os-release) ] ; then \
    echo "deb http://ftp.debian.org/debian jessie-backports main" >> /etc/apt/sources.list && \
    apt-get update && apt-get -y install -t jessie-backports xvfb phantomjs \
; else \
		apt-get update && apt-get -y install xvfb phantomjs \
; fi
ENV DISPLAY :99
# install firefox
# RUN curl --silent --show-error --location --fail --retry 3 --output /tmp/firefox.deb https://s3.amazonaws.com/circle-downloads/firefox-mozilla-build_47.0.1-0ubuntu1_amd64.deb   && echo 'ef016febe5ec4eaf7d455a34579834bcde7703cb0818c80044f4d148df8473bb  /tmp/firefox.deb' | sha256sum -c   && dpkg -i /tmp/firefox.deb || apt-get -f install    && apt-get install -y libgtk3.0-cil-dev libasound2 libasound2 libdbus-glib-1-2 libdbus-1-3   && rm -rf /tmp/firefox.deb
# install chrome
RUN curl --silent --show-error --location --fail --retry 3 --output /tmp/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb   && (dpkg -i /tmp/google-chrome-stable_current_amd64.deb || apt-get -fy install)    && rm -rf /tmp/google-chrome-stable_current_amd64.deb   && sed -i 's|HERE/chrome"|HERE/chrome" --disable-setuid-sandbox --no-sandbox|g'        "/opt/google/chrome/google-chrome"
# install chromedriver
RUN apt-get -y install libgconf-2-4   && curl --silent --show-error --location --fail --retry 3 --output /tmp/chromedriver_linux64.zip "http://chromedriver.storage.googleapis.com/2.33/chromedriver_linux64.zip"   && cd /tmp   && unzip chromedriver_linux64.zip   && rm -rf chromedriver_linux64.zip   && mv chromedriver /usr/local/bin/chromedriver   && chmod +x /usr/local/bin/chromedriver

# Fix error `TZInfo::ZoneinfoDirectoryNotFound: None of the paths included in TZInfo::ZoneinfoDataSource.search_path are valid zoneinfo directories.`
# https://github.com/phusion/passenger-docker/issues/195#issuecomment-321868848
RUN apt-get install -y tzdata

# Install bundler
ENV BUNDLER_VERSION 1.16.1
RUN gem install bundler --version "$BUNDLER_VERSION"
# install things globally, for great justice
# and don't create ".bundle" in all our apps
ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_PATH="$GEM_HOME" \
  BUNDLE_BIN="$GEM_HOME/bin" \
  BUNDLE_SILENCE_ROOT_WARNING=1 \
  BUNDLE_APP_CONFIG="$GEM_HOME"
ENV PATH $BUNDLE_BIN:$PATH
RUN mkdir -p "$GEM_HOME" "$BUNDLE_BIN" \
  && chmod 777 "$GEM_HOME" "$BUNDLE_BIN"

CMD [ "irb" ]
