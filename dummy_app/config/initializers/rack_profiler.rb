# To use Rack Mini Profiler, start the Rails app with `RACK_MINI_PROFILER=true`
#
# To see the flamegraph, visit any URL and append `?pp=flamegraph` to the URL
if !Rails.env.test?
  require "rack-mini-profiler"

  # initialization is skipped so trigger it
  Rack::MiniProfilerRails.initialize!(Rails.application)

  Rack::MiniProfiler.config.authorization_mode = :allow_all
end
