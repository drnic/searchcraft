module SearchCraft::DependsOn
  module ClassMethods
    @@dependencies = {}

    def depends_on(*builder_names)
      @@dependencies[name] = builder_names
    end

    def sort_builders_by_dependency
      sorted = []
      visited = {}

      builders_to_rebuild.each do |builder|
        visit(builder, visited, sorted)
      end

      sorted
    end

    def visit(builder, visited, sorted)
      return if visited[builder.name.to_s]

      dependency_names = @@dependencies[builder.name] || []
      dependency_names.each do |dependency_name|
        dependency = Object.const_get(dependency_name)
        visit(dependency, visited, sorted)
      end

      visited[builder.name.to_s] = true
      sorted << builder
    end
  end

  extend ClassMethods
end
