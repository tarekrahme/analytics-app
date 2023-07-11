web: DB_POOL=$PUMA_MAX_THREADS bundle exec puma -C config/puma.rb
worker: DB_POOL=$SIDEKIQ_DB_POOL bundle exec sidekiq -C config/sidekiq.yml
release: rake db:migrate