![searchcraft-logo](docs/searchcraft-logo-on-white.png)

Instant search for Rails and ActiveRecord using SQL materialized views.

* Native Rails replacement for ElasticSearch
* Huge speed improvements to homepages and dashboards
* Create reporting and summary tables that are easily updatable and queryable

## Introduction

Add lightning quick search capabilities to your Rails apps without external systems like ElasticSearch. It's now magically simple to craft the ActiveRecord/Arel expressions we already know and love, and convert them into SQL materialized views: ready to be queried and composed with ActiveRecord. Everything you love about Rails, but faster.

**What makes Rails slow for search?** Large tables, lots of joins, subqueries, missing or unused indexes, and complex queries.

SearchCraft makes it trivial to write and use powerful **SQL materialized views** to pre-calculate the results of your search and reporting queries. It's like a database index, but for complex queries.

Materialized views are a wonderful feature of PostgreSQL, Oracle, and SQL Server*. They are a table of pre-calculated results of a query. They are fast to query. They are awesome. Like other search systems, you control when you want to refresh them with new data.

Inside Rails and ActiveRecord, you can access a read-only materialized view like you would any regular table. You can even join them together. You can use them in your ActiveRecord models, scopes, and associations.

```ruby
class ProductSearch < ActiveRecord::Base
  include SearchCraft::Model
end
```

Done. Whatever columns you describe in your view will become attributes on your model.

If the underlying view had columns `product_id`, `product_name`, `reviews_count`, and `reviews_average`, then you can query it like any other ActiveRecord model:

```ruby
ProductSearch.all
[#<ProductSearch product_id: 2, product_name: "iPhone 15", reviews_count: 5, reviews_average: 0.38e1>,
 #<ProductSearch product_id: 1, product_name: "Laptop 3", reviews_count: 5, reviews_average: 0.28e1>,
 #<ProductSearch product_id: 4, product_name: "Monopoly", reviews_count: 3, reviews_average: 0.2e1>]

ProductSearch.order(reviews_average: :desc)
[#<ProductSearch product_id: 2, product_name: "iPhone 15", reviews_count: 5, reviews_average: 0.38e1>,
   #<ProductSearch product_id: 1, product_name: "Laptop 3", reviews_count: 5, reviews_average: 0.28e1>,
   #<ProductSearch product_id: 4, product_name: "Monopoly", reviews_count: 3, reviews_average: 0.2e1>]
```

If you include foreign keys, then you can use `belongs_to` associations. You can add scopes. You can add methods. You can use it as the starting point for queries with the rest of your SQL database. It's just a regular ActiveRecord model.

All this is already possible with Rails and ActiveRecord. SearchCraft achievement is to make it trivial to live with your materialized views. Trivial to refresh them and to write them.

If the underlying data to your SearchCraft materialized view changes and you want to refresh it, then call `refresh!` on your model class. This is provided by the `SearchCraft::Model` mixin.

```ruby
ProductSearch.refresh!
```

You can pass this ActiveRecord relation/array to your Rails views and render them. You can join it to other tables and apply further scopes.

But SearchCraft's greatest feature is help you **write your materialized views**, and then to iterate on them.

Design them in ActiveRecord expressions, Arel expressions, or even plain SQL. No migrations to rollback and re-run. No keeping track of whether the SQL view in your database matches the SearchCraft code in your Rails app. SearchCraft will automatically create and update your materialized views.

Update your SearchCraft view, run your tests, they work. Update your SearchCraft view, refresh your development app, and it works. Open up `rails console` and it works; then update your view, type `reload!`, and it works. Deploy to production anywhere, and it works.

What does it look like to design a materialized view with SearchCraft? For our `ProductSearch` model above, we create a `ProductSearchBuilder` class that inherits from `SearchCraft::Builder` and provides either a `view_scope` method or `view_select_sql` method.

```ruby
class ProductSearchBuilder < SearchCraft::Builder
  def view_scope
    Product.where(active: true)
      .select(
        "products.id AS product_id",
        "products.name AS product_name",
        "(SELECT COUNT(*) FROM product_reviews WHERE product_reviews.product_id = products.id) AS reviews_count",
        "(SELECT AVG(rating) FROM product_reviews WHERE product_reviews.product_id = products.id) AS reviews_average"
      )
  end
end
```

The `view_scope` method must return an ActiveRecord relation. It can be as simple or as complex as you like. It can use joins, subqueries, and anything else you can do with ActiveRecord. In the example above we:

* filter out inactive products
* select the `id` and `name` columns from the `products` table; where we can later use `product_id` as a foreign key for joins to the `Product` model in our app
* build new `reviews_count` and `reviews_average` columns using SQL subqueries that counts and averages the `rating` column from the `product_reviews` table.

SearchCraft will convert this into a materialized view, create it into your database, and the `ProductSearch` model above will start using it when you next reload your development app or run your tests. If you make a change, SearchCraft will drop and recreate the view automatically.

When we load up our app into Rails console, or run our tests, or refresh the development app, the `ProductSearch` model will be automatically updated to match any changes in `ProductSearchBuilder`.

```ruby
ProductSearch.all
  [#<ProductSearch product_id: 2, product_name: "iPhone 15", reviews_count: 5, reviews_average: 0.38e1>,
   #<ProductSearch product_id: 1, product_name: "Laptop 3", reviews_count: 5, reviews_average: 0.28e1>,
   #<ProductSearch product_id: 4, product_name: "Monopoly", reviews_count: 3, reviews_average: 0.2e1>]

ProductSearch.order(reviews_average: :desc)
  [#<ProductSearch product_id: 2, product_name: "iPhone 15", reviews_count: 5, reviews_average: 0.38e1>,
   #<ProductSearch product_id: 1, product_name: "Laptop 3", reviews_count: 5, reviews_average: 0.28e1>,
   #<ProductSearch product_id: 4, product_name: "Monopoly", reviews_count: 3, reviews_average: 0.2e1>]
```

If you want to write SQL, then you can use the `view_select_sql` method instead.

```ruby
class NumberBuilder < SearchCraft::Builder
  # Write SQL that produces 5 rows, with a 'number' column containing the number of the row
  def view_select_sql
    "SELECT generate_series(1, 5) AS number;"
  end
end

class Number < ActiveRecord::Base
  include SearchCraft::Model
end
```

```ruby
Number.all
[#<Number number: 1>, #<Number number: 2>, #<Number number: 3>, #<Number number: 4>, #<Number number: 5>]
```

Once you have one SearchCraft materialized view, you might want to create another that depends upon it. You can do this too with the `depends_on` method.

```ruby
class SquaredBuilder < SearchCraft::Builder
  depends_on "NumberBuilder"

  def view_select_sql
    "SELECT number, number * number AS squared FROM #{Number.table_name};"
  end
end

class Squared < ActiveRecord::Base
  include SearchCraft::Model
end
```

If you make a change to `NumberBuilder`, then SearchCraft will automatically drop and recreate both the `Number` and `Squared` materialized views.

```ruby
Squared.all
[#<Squared number: 1, squared: 1>,
 #<Squared number: 2, squared: 4>,
 #<Squared number: 3, squared: 9>,
 #<Squared number: 4, squared: 16>,
 #<Squared number: 5, squared: 25>]
```

Aren't confident writing complex SQL or Arel expressions? Me either. I ask GPT4 or GitHub Copilot. I explain the nature of my schema and tables, and ask it to write some SQL, and then ask to convert it into Arel. Or I give it a small snippet it of SQL, and ask it to convert it into Arel. I then copy/paste the results into my SearchCraft builder class.

It is absolutely worth learning to express your search queries in SQL or Arel, and putting them into a SearchCraft materialized view. Your users will have a lightning fast experience.

* A future version of SearchCraft might implement a similar feature for MySQL by creating simple views and caching the results in tables.

## Installation

Inside your Rails app, add the gem to your Gemfile:

```plain
bundle add searchcraft
```

SearchCraft will automatically create an internal DB table that it needs, so there's no database migration to run. And of course, it will automatically create and recreate your materialized views.

## Learning SearchCraft

1. Re-read the introduction above.
2. Read and run the examples in the [examples/](examples/) folder.
3. Look at the Rails app in the [demo_app](demo_app/) folder. It contains models, SearchCraft builders, unit tests, and system tests.

### Features

* Watches `Builder` subclasses, and automatically detects change to materialize view schema and recreates it
* ActiveRecord model mixin to allow `refresh!` of materialized view contents
* Dumps `db/schema.rb` whenever materialized view is updated
* Annotates models whenever materialized view is updated, if `annotate` gem is installed

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/drnic/searchcraft. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/drnic/searchcraft/blob/develop/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Searchcraft project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/drnic/searchcraft/blob/develop/CODE_OF_CONDUCT.md).

## Credits

* [scenic](https://github.com/scenic-views/scenic) gem first allowed me to use materialized views in Rails, but I was iterating on my view schema so frequently that their migration approach - `rails db:rollback`, rebuild migration SQL, `rails db:migrate`, and then test - became slow. It also introduced bugs - I would forget to run the steps, and then see odd behaviour. If you have relatively static views or materialized views, and want to use Rails migrations, please try out `scenic` gem.
* [activerecord](https://github.com/rails/rails) has been one of the most wonderful gifts to the universe since its inception. As a bonus, it allowed me to become "Dr Nic" in 2006 when I performed silly tricks with it in a rubygem called "Dr Nic's Magic Models". I've made many dear friends and had a wonderful career since those days.
