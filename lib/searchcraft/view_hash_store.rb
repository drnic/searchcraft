# Stores the sha265 hash of the SQL used to create each view.
# This allows the Builder to determine if a view needs
# to be recreated. We don't want to use ActiveRecord Migrations,
# instead want the view to be automatically recreated when
# any Builder's #view_select_sql SQL changes.
#
# The view SQL hashes are stored in a table named
# search_craft_view_hash_stores, which is automatically
# created by SearchCraft.
class SearchCraft::ViewHashStore < ActiveRecord::Base
  self.table_name = "search_craft_view_hash_stores"

  # Update record for StoreConnect::SearchCached::Builder::Base subclass
  def self.update_for(builder:)
    setup_table_if_needed!
    view_sql_hash = builder.view_sql_hash
    view_hash_store = find_or_initialize_by(view_name: builder.view_name)
    view_hash_store.update!(view_sql_hash: view_sql_hash)
  end

  def self.changed?(builder:)
    setup_table_if_needed!
    view_sql_hash = builder.view_sql_hash
    view_hash_store = find_by(view_name: builder.view_name)
    view_hash_store.nil? || view_hash_store.view_sql_hash != view_sql_hash
  end

  def self.exists?(builder:)
    setup_table_if_needed!
    find_by(view_name: builder.view_name)
  end

  def self.reset!(builder:)
    setup_table_if_needed!
    view_hash_store = find_by(view_name: builder.view_name)
    view_hash_store&.destroy!
  end

  private

  def self.setup_table_if_needed!
    return if table_exists?

    # Migrate table
    create_table_sql = <<~SQL
      CREATE TABLE search_craft_view_hash_stores (
        id serial primary key,
        view_name varchar(255) not null,
        view_sql_hash varchar(255) not null,
        created_at timestamp not null default now(),
        updated_at timestamp not null default now()
      );
    SQL
    ActiveRecord::Base.connection.execute(create_table_sql)
    reset_column_information
  end
end
