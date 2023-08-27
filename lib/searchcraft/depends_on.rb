module SearchCraft::DependsOn
  extend ActiveSupport::Concern

  class_methods do
    @@dependencies = {}

    def depends_on(*builder_names)
      @@dependencies[name] = builder_names
    end

    # TODO: implement .add_index instead of #view_indexes below
    def add_index(index_name, columns, unique: false, name: nil)
      @indexes ||= {}
      # TODO: also get indexes from @@dependencies[name]
      @indexes[index_name] = {columns: columns, unique: unique, name: name}
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
      return if visited[builder.name]

      dependency_names = @@dependencies[builder.name] || []
      dependency_names.each do |dependency_name|
        dependency = Object.const_get(dependency_name)
        visit(dependency, visited, sorted)
      end

      visited[builder.name] = true
      sorted << builder
    end
  end
end
