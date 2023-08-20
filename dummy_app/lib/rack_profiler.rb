module RackProfilerHelpers
  def rack_profile(name, &block)
    if Rack.const_defined?(:MiniProfiler)
      Rack::MiniProfiler.step(name) do
        yield
      end
    else
      yield
    end
  end
end

Object.include(RackProfilerHelpers)
