# The web page: one static HTML file served by an unprivileged nginx (listens on 8080, not root).
# It calls the API at /api; the Ingress sends those requests to the API, so nginx never proxies.
FROM nginxinc/nginx-unprivileged:1.30-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 8080
