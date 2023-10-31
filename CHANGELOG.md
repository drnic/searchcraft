## [Unreleased]

- [`SearchCraft::TextSearch`](lib/searchcraft/text_search.rb) module added to `Builder` which provides `tsvector` helpers. See [`test_text_search.rb`](test/searchcraft/builder/test_text_search.rb) for examples.
- RBS type signatures
- Convenience `Config.explicit_builder_classes = {"Builder" => "Model"}` if you need to explicitly describe your Builder + Model classes and they are 1:1
- Override default table name for `ViewHashStore` with:

    ```ruby
    SearchCraft.configure do |config|
      config.view_hash_store_table_name = "'my_schema'.'my_table_name'"`
    end
    ```

Fixes:

- Fixes for users of `SearchCraft.config.explicit_model_class_names` on initialization

## [0.4.0] - 2023-10-24

- Initial public release
