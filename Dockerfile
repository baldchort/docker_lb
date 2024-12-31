# Этап сборки
FROM ruby:3.0.5-alpine3.16 AS build
RUN apk add --no-cache build-base git postgresql-dev
WORKDIR /app
COPY Gemfile .
RUN bundle install --without test
COPY . .
RUN bundle exec rake assets:precompile \
    && rm -rf /usr/local/bundle/cache/*.gem \ 
    && find /usr/local/bundle/gems/ -name "*.c" -delete \  
    && find /usr/local/bundle/gems/ -name "*.o" -delete \  
    && rm -rf ./tmp/cache

# Этап запуска приложения
FROM ruby:3.0.5-alpine3.16
RUN apk add --no-cache libpq
COPY --from=build /app /app
COPY --from=build /usr/local/bundle /usr/local/bundle
WORKDIR /app
RUN addgroup -S publify && adduser -S publify -G publify && chown -R publify:publify .
ENV RAILS_ENV=production
EXPOSE 3000

CMD ["sh", "-c", "bundle exec rake db:migrate && bundle exec rake db:seed && bundle exec rails server -b 0.0.0.0"]
