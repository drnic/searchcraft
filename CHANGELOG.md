## Not Yet Released

- `SEARCHCRAFT_DEBUG=true` is the same as `SearchCraft.debug = true` and shows internal debugging of errors and activities
- `SearchCraft.config.disable_annotate = true` to disable automatic annotation of models (which is enabled by default if `annotate_model` gem discovered)

Fixes:

- `SearchCraft.dependencies_ready?` (used on launch) is fixed for normal/default case where `explicit_builder_class_names` not provided

## [0.4.1] - 2023-11-01

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
