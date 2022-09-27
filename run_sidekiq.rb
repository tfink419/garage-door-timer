require 'sidekiq'
require './garage_status_worker'

GarageStatusWorker.perform_async((ENV['TIMER_INTERVAL'] || 300).to_i)