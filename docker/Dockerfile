ARG RUBY_VERSION=3.3.4
FROM ruby:$RUBY_VERSION

RUN apt-get update -qq && \
    apt-get install -y ca-certificates && \
    update-ca-certificates && \
    apt-get install -y build-essential libvips && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man

WORKDIR /api

COPY Gemfile* ./

RUN gem install bundler
RUN bundle install

COPY . .

EXPOSE 4567
