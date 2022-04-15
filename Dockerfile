FROM alpine:3.13

LABEL maintainer="Joe Khoobyar fourheads@gmail.com"

ARG RUBY_VERSIONSPEC="<2.8"
ARG BUNDLER_VERSIONSPEC="<3.0"

# Baseline installation.
RUN apk update \
    && apk upgrade \
    && apk add --no-cache ca-certificates bash git curl tzdata \
    && adduser -D svc -h /home/svc -u 1000 \
    && chmod o-rwx /home/svc \
    && echo '[ -r /etc/bashrc ] && . /etc/bashrc' >/home/svc/.bashrc \
    && echo 'source ~/.bashrc' >/home/svc/.profile

# Ruby installation.
# Based on:
#   - https://github.com/cybercode/alpine-ruby
RUN apk --update add "ruby$RUBY_VERSIONSPEC" "ruby-rake$RUBY_VERSIONSPEC" \
        "ruby-io-console$RUBY_VERSIONSPEC" "ruby-bigdecimal$RUBY_VERSIONSPEC" \
        "ruby-json$RUBY_VERSIONSPEC" "ruby-bundler$BUNDLER_VERSIONSPEC" \
        "ruby-rspec$RSPEC_VERSIONSPEC" \
    && echo 'gem: --no-document' > /etc/gemrc \
    && echo 'update: --user-install' >> /etc/gemrc \
    && echo 'install: --user-install' >> /etc/gemrc
RUN apk --virtual .build-deps --update add \
        gcc g++ make "ruby-dev$RSPEC_VERSIONSPEC" \
    && chown -R svc:svc /home/svc

# User profile configuration.
USER svc
RUN bundle config --global path $(ruby -e 'puts Gem.user_dir') \
    && echo 'export PATH="'"$(ruby -e 'puts Gem.user_dir')"'/bin:$HOME/.local/bin:$HOME/bin:$PATH"' >>/home/svc/.bashrc

# Microservice installation.
RUN mkdir /home/svc/edms-analyzer
COPY Gemfile.release /home/svc/edms-analyzer/Gemfile
COPY lib/ /home/svc/edms-analyzer/lib/
COPY config.ru Gemfile.lock LICENSE README.md /home/svc/edms-analyzer/

# Fix permissions
USER root
RUN chown -R svc:svc /home/svc

# Create the bundle
USER svc
WORKDIR /home/svc/edms-analyzer
RUN bundle package

# Cleanup from prior steps
USER root
RUN apk --purge del .build-deps \
    && rm -f /var/cache/apk/*

# Final settings
USER svc
ENV HOME=/home/svc
ENV PATH="$HOME/.gem/ruby/2.7.0/bin:$HOME/.local/bin:$HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

ENTRYPOINT ["bundle", "exec"]

EXPOSE 9292
CMD ["falcon", "serve", "--bind", "http://0.0.0.0:9292"]
