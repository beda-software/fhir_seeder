FROM ruby:3.3.6

WORKDIR /app

COPY . /app

RUN bundle install

RUN gem build *.gemspec && gem install *.gem

ENTRYPOINT ["bundle", "exec"]
