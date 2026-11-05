# Build the static site, then serve it with an unprivileged nginx (listens on 8080, runs as non-root).

# The build stage runs on the CI machine's own platform: its output is plain HTML, CSS and JS, the
# same for every platform, so arm64 images don't need a slow emulated build.
FROM --platform=$BUILDPLATFORM node:26-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginxinc/nginx-unprivileged:1.30-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 8080
