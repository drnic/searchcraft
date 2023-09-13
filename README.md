<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/drnic/searchcraft/blob/develop/docs/searchcraft-logo-white.png?raw=true">
  <source media="(prefers-color-scheme: light)" srcset="https://github.com/drnic/searchcraft/blob/develop/docs/searchcraft-logo-black.png?raw=true">
  <img src="https://github.com/drnic/searchcraft/blob/develop/docs/searchcraft-logo-on-white.png?raw=true">
</picture>

Instant search for Rails and ActiveRecord using SQL materialized views.

* 10x speed improvements to homepages and dashboards
* Native Rails replacement for ElasticSearch
* Create reporting and summary tables that are easily updatable and queryable

See [demo app](https://ykdnr.hatchboxapp.com/searchcraft/products?category_id=54) (code found in `demo_app/` folder):

[![searchcraft 10x speed demo](docs/searchcraft%2010x%20speed%20demo.png)](https://ykdnr.hatchboxapp.com/searchcraft/products?category_id=54)

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

### Refresh materialized views

Each SearchCraft materialized view a snapshot of the results of the query at the time it was created, or last refreshed. It's like a table whose contents are derived from a query.

If the underlying data to your SearchCraft materialized view changes and you want to refresh it, then call `refresh!` on your model class. This is provided by the `SearchCraft::Model` mixin.

```ruby
ProductSearch.refresh!
```

You can pass this ActiveRecord relation/array to your Rails views and render them. You can join it to other tables and apply further scopes.

### Writing and iterating on materialized views

But SearchCraft's greatest feature is help you **write your materialized views**, and then to iterate on them.

Design them in ActiveRecord expressions, Arel expressions, or even plain SQL. No migrations to rollback and re-run. No keeping track of whether the SQL view in your database matches the SearchCraft code in your Rails app. SearchCraft will automatically create and update your materialized views.

Update your SearchCraft view, run your tests, they work. Update your SearchCraft view, refresh your development app, and it works. Open up `rails console` and it works; then update your view, type `reload!`, and it works. Deploy to production anywhere, and it works.

### Write views in ActiveRecord or Arel

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

### Write views in SQL

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

### Dependencies between views

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

### Use ChatGPT to write your views

Aren't confident writing complex SQL or Arel expressions? Me either. I ask GPT4 or GitHub Copilot. I explain the nature of my schema and tables, and ask it to write some SQL, and then ask to convert it into Arel. Or I give it a small snippet it of SQL, and ask it to convert it into Arel. I then copy/paste the results into my SearchCraft builder class.

It is absolutely worth learning to express your search queries in SQL or Arel, and putting them into a SearchCraft materialized view. Your users will have a lightning fast experience.

### Databases and materialized view support

* A future version of SearchCraft might implement a similar feature for MySQL by creating simple views and caching the results in tables.
* SearchCraft has been developed and tested against PostgreSQL, but it should "just work" for database servers that support materialized views, such as Oracle and SQL Server. Please create tickets if there are issues.

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
4. Follow along this simple tutorial in any of your Rails apps.

### Tutorial

Inside any Rails app you can follow along with this tutorial. If you don't have a Rails app, use the app found in `demo_app` folder of this project.

Install the gem:

```plain
bundle add searchcraft
```

Pick one of your existing application models, say `Product`, and we will create a trivial materialized view for it. Say, we want a fast way to get the top 5 selling products and some details we'll use for it in our HTML view.

Create a new ActiveRecord model file `app/models/product_latest_arrival.rb`:

```ruby
class ProductLatestArrival < ActiveRecord::Base
  include SearchCraft::Model
end
```

By Rails conventions, this model will look for a SQL table or view called `product_latest_arrivals`. This does not exist yet.

We can confirm this by opening up `rails console` and trying to query it:

```ruby
ProductLatestArrival.all
# ActiveRecord::StatementInvalid ERROR: relation "product_latest_arrivals" does not exist
```

We can create a new SearchCraft builder class to define our materialized view. Create a new file `app/searchcraft/product_latest_arrival_builder.rb`.

I suggest `app/searchcraft` for your builders, but they can go into any `app/` subfolder that is autoloaded by Rails.

```ruby
class ProductLatestArrivalBuilder < SearchCraft::Builder
  def view_scope
    Product.order(created_at: :desc).limit(5)
  end
end
```

Inside your `rails console``, run `reload!` and check your query again:

```ruby
reload!

ProductLatestArrival.all
  ProductLatestArrival Load (1.3ms)  SELECT "product_latest_arrivals".* FROM "product_latest_arrivals"
=>
[#<ProductLatestArrival:0x000000010a737d18
  id: 1,
  name: "Rustic Wool Coat",
  active: true,
  created_at: Fri, 25 Aug 2023 07:15:16.995228000 UTC +00:00,
  updated_at: Fri, 25 Aug 2023 07:15:16.995228000 UTC +00:00,
  image_url: "https://loremflickr.com/g/320/320/coat?lock=1">,
...
```

If you have the `annotate` gem installed in your `Gemfile`, you will also note that `product_latest_arrival.rb` model has been updated to reflect the columns in the materialized view.

```ruby
# == Schema Information
#
# Table name: product_latest_arrivals
#
#  id         :bigint
#  name       :string
#  active     :boolean
#  created_at :datetime
#  updated_at :datetime
#  image_url  :string
#
class ProductLatestArrival < ActiveRecord::Base
  include SearchCraft::Model
end
```

If your application is under source control, you can also see that `db/schema.rb` has been updated to reflect the latest view definition. Run `git diff db/schema.rb`:

```ruby
create_view "product_latest_arrivals", materialized: true, sql_definition: <<-SQL
    SELECT products.id,
    products.name,
    products.active,
    products.created_at,
    products.updated_at,
    products.image_url
    FROM products
  LIMIT 5;
SQL
```

You can now continue to change the `view_scope` in your builder, and run `reload!` in rails console to test out your change.

For example, you can `select()` only the columns that you want using SQL expression for each one:

```ruby
class ProductLatestArrivalBuilder < SearchCraft::Builder
  def view_scope
    Product
      .order(created_at: :desc)
      .limit(5)
      .select(
        "products.id as product_id",
        "products.name as product_name",
        "products.image_url as product_image_url",
      )
  end
end
```

Or you can use Arel expressions to build the SQL:

```ruby
class ProductLatestArrivalBuilder < SearchCraft::Builder
  def view_scope
    Product
      .order(created_at: :desc)
      .limit(5)
      .select(
        Product.arel_table[:id].as("product_id"),
        Product.arel_table[:name].as("product_name"),
        Product.arel_table[:image_url].as("product_image_url"),
      )
  end
end
```

What about data updates? Let's create more `Products`:

```ruby
Product.create!(name: "Starlink")
Product.create!(name: "Fishing Rod")
```

If you were to inspect `ProductLatestArrival.all` you would **not find** these new products. This is because the materialized view is a snapshot of the data at the time it was created or last refreshed.

To refresh the view:

```ruby
ProductLatestArrival.refresh!
```

Alternately, to refresh all views:

```ruby
SearchCraft::Model.refresh_all!
```

And confirm that the latest new arrivals are now in the materialized view:

```ruby
ProductLatestArrival.pluck(:name)
=> ["Fishing Rod", "Starlink", "Sleek Steel Bag", "Ergonomic Plastic Bench", "Fantastic Wooden Keyboard"]
```

If you want to remove the artifacts of this tutorial. First, drop the materialized view from your database schema:

```ruby
ProductLatestArrivalBuilder.new.drop_view!
```

Then remove the files and `git checkout .` to revert any other changes.

```plain
rm app/searchcraft/product_latest_arrival_builder.rb
rm app/models/product_latest_arrival.rb
git checkout db/schema.rb
```

### Rake tasks

SearchCraft provides two rake tasks:

* `rake searchcraft:refresh` - refresh all materialized views
* `rake searchcraft:rebuild` - check if any views need to be recreated

To add these to your Rails app, add the following to the bottom of your `Rakefile`:

```ruby
SearchCraft.load_tasks
```

### Features

* Watches `Builder` subclasses, and automatically detects change to materialize view schema and recreates it
* ActiveRecord model mixin to allow `refresh!` of materialized view contents
* Dumps `db/schema.rb` whenever materialized view is updated
* Annotates models whenever materialized view is updated, if `annotate` gem is installed
* Namespaced models/builders will use the full namesapce + classname for the materialized view name
* Rake tasks to refresh all materialized views `rake searchcraft:refresh`, and check if any views need to be recreated `rake searchcraft:rebuild`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

To bump a version number:

1. Use the `gem bump` command, e.g. `gem bump -v patch`
2. Update the `demo_app/Gemfile.lock`, e.g. `(cd demo_app; bundle)`
3. Merge that change back into bump commit, e.g. `git add demo_app/Gemfile.lock; git commit --amend --no-edit`
3. Cut a release `rake release`

```plain
gem bump -v patch
(cd demo_app; bundle)
git add demo_app/Gemfile.lock; git commit --amend --no-edit
git push
rake release
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/drnic/searchcraft. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/drnic/searchcraft/blob/develop/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Searchcraft project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/drnic/searchcraft/blob/develop/CODE_OF_CONDUCT.md).

## Credits

* [scenic](https://github.com/scenic-views/scenic) gem first allowed me to use materialized views in Rails, but I was iterating on my view schema so frequently that their migration approach - `rails db:rollback`, rebuild migration SQL, `rails db:migrate`, and then test - became slow. It also introduced bugs - I would forget to run the steps, and then see odd behaviour. If you have relatively static views or materialized views, and want to use Rails migrations, please try out `scenic` gem. This `searchcraft` gem still depends on `scenic` for its view `refresh` feature, and adding views into `schema.rb`.
* [activerecord](https://github.com/rails/rails) has been one of the most wonderful gifts to the universe since its inception. As a bonus, it allowed me to become "Dr Nic" in 2006 when I performed silly tricks with it in a rubygem called "Dr Nic's Magic Models". I've made many dear friends and had a wonderful career since those days.
