# syntax=docker/dockerfile:1

####################################
# Builder: clone the repo and stage site
####################################
FROM alpine:3.19 AS builder

# tools
RUN apk add --no-cache git ca-certificates

# build-time vars (set by docker-compose or build args)
ARG REPO_URL
ARG REPO_REF=HEAD   # branch, tag or commit to checkout

# where we clone
WORKDIR /src

# clone only one depth for speed
# REPO_URL should be provided at build-time
RUN if [ -z "$REPO_URL" ]; then echo "REPO_URL not set"; exit 1; fi
RUN git clone --depth 1 --branch ${REPO_REF} "$REPO_URL" .

# optionally build steps could go here (npm build etc.)

####################################
# Final: nginx static server
####################################
FROM nginx:stable-alpine

# remove default config, we'll add our own
RUN rm /etc/nginx/conf.d/default.conf

# copy a custom nginx config
COPY nginx.conf /etc/nginx/conf.d/site.conf

# copy built site from builder
COPY --from=builder /src /usr/share/nginx/html

# optional: create a directory for healthcheck or certs if needed
EXPOSE 80

# healthcheck (optional)
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s \
  CMD wget -q --spider http://localhost/ || exit 1

# nginx image already runs nginx in foreground by default
