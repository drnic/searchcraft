![searchcraft-logo](docs/searchcraft-logo-vanderick.png)

"Instant Search for Rails and ActiveRecord using SQL materialized views."

Add lightning quick search capabilities to your Rails apps without external systems like ElasticSearch. It's now magically simple to craft the ActiveRecord/Arel expressions we already know and love, and convert them into SQL materialized views: ready to be queried and composed with ActiveRecord. Everything you love about Rails, but faster.

What makes Rails slow for search? Large tables, lots of joins, subqueries, missing or unused indexes, and complex queries. SearchCraft makes it trivial to use powerful SQL materialized views to pre-calculate the results of your search queries. It's like a database index, but for complex queries.

Materialized views are a wonderful feature of PostgreSQL, Oracle, and SQL Server*. They are a table of pre-calculated results of a query. They are fast to query. They are awesome. Like other search systems, you control when you want to refresh them with new data.

Inside Rails and ActiveRecord, you can access a read-only materialized view like you would any regular table. You can even join them together. You can use them in your ActiveRecord models, scopes, and associations.

```ruby
class ProductSearch < ActiveRecord::Base
  def readonly?; true; end

  belongs_to :product

  scope :within_category, ->(category_id) { where(category_id: category_id) }
end
```

Done. Whatever columns you describe in your view will become attributes on your model. If you include foreign keys, then you can use `belongs_to` associations. You can add scopes. You can add methods. You can use it as the starting point for queries with the rest of your SQL database. It's just a regular ActiveRecord model.

All this is already possible with Rails and ActiveRecord. SearchCraft achievement is to make it trivial to write your materialized views, and then to iterate on them. Design them in ActiveRecord or Arel expressions, or even plain SQL. No migrations to rollback and re-run. No keeping track of whether the SQL view in your database matches the SearchCraft code in your Rails app. SearchCraft will automatically create and update your materialized views.

If the underlying data to your SearchCraft materialized view changes and you want to refresh it, then call `refresh` on your model class.

```ruby
ProductSearch.refresh
```

Update your SearchCraft view, run your tests, they work. Update your SearchCraft view, refresh your development app, and it works. Deploy to production anywhere, and it works.

What does it look like to design a materialized view with SearchCraft? Provide a method `view_scope` that returns an ActiveRecord/Arel query.

```ruby
class ProductSearchBuilder < SearchCraft::Builder
  def view_scope
    Product
      .joins(:category)
      .where(active: true) # only active products
      .where(categories: { active: true }) # only active categories
      .select(
        'products.id AS product_id, ' +
        'products.name AS product_name, ' +
        'categories.id AS category_id, ' +
        'categories.name AS category_name'
      )
  end
end
```

SearchCraft will convert this into a materialized view, create it into your database, and the `ProductSearch` model above will start using it when you next reload your development app or run your tests. If you make a change, SearchCraft will drop and recreate the view automatically.

* A future version of SearchCraft might implement a similar feature for MySQL by creating simple views and caching the results in tables.

## Installation

Inside your Rails app, add the gem to your Gemfile:

```plain
bundle add searchcraft
```

SearchCraft will automatically create an internal DB table that it needs, so there's no database migration to run. And of course, it will automatically create and recreate your materialized views.

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/drnic/searchcraft. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/drnic/searchcraft/blob/develop/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Searchcraft project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/drnic/searchcraft/blob/develop/CODE_OF_CONDUCT.md).
