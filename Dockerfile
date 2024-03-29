FROM google/dart

WORKDIR /app

ADD pubspec.* /app/
RUN pub get
ADD . /app
RUN pub get --offline
ENV dbhost localhost

CMD []
ENTRYPOINT /usr/bin/dart bin/main.dart ${dbhost}