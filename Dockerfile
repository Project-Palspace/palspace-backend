FROM dart:latest AS build

WORKDIR /app
COPY . /app
RUN rm /bin/sh && ln -s /bin/bash /bin/sh
RUN dart pub get
RUN dart run build_runner build

# Start server.
EXPOSE 8888
CMD ["/usr/lib/dart/bin/dart", "/app/bin/server.dart"]
