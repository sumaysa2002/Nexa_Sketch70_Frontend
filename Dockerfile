FROM ghcr.io/cirruslabs/flutter:3.38.8 AS build
WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

ARG BACKEND_URI=http://10.0.2.2:3000
RUN flutter build apk --release --dart-define=BACKEND_URI=${BACKEND_URI}

FROM scratch AS export
COPY --from=build /app/build/app/outputs/flutter-apk/app-release.apk /