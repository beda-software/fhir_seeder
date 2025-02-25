FROM ruby:3.3.6

WORKDIR /app

COPY . /app

RUN bundle install

RUN gem build *.gemspec && gem install *.gem

RUN chmod +x /app/bin/seeder

ENTRYPOINT ["./bin/seeder"]
