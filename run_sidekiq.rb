require 'sidekiq'
require './garage_status_worker'

INTERVAL = (ENV['TIMER_INTERVAL'] || 300).to_i

GarageStatusWorker.perform_async(INTERVAL)
GarageStatusWorker.perform_at(Time.now+60, INTERVAL)
GarageStatusWorker.perform_at(Time.now+120, INTERVAL)
GarageStatusWorker.perform_at(Time.now+180, INTERVAL)
GarageStatusWorker.perform_at(Time.now+240, INTERVAL)
GarageStatusWorker.perform_at(Time.now+300, INTERVAL)
GarageStatusWorker.perform_at(Time.now+360, INTERVAL)
GarageStatusWorker.perform_at(Time.now+420, INTERVAL)
GarageStatusWorker.perform_at(Time.now+480, INTERVAL)
GarageStatusWorker.perform_at(Time.now+540, INTERVAL)