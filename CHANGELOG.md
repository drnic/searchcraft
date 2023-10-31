## [Unreleased]

- [`SearchCraft::TextSearch`](lib/searchcraft/text_search.rb) module added to `Builder` which provides `tsvector` helpers. See [`test_text_search.rb`](test/searchcraft/builder/test_text_search.rb) for examples.
- RBS type signatures
- Convenience `Config.explicit_builder_classes = {"Builder" => "Model"}` if you need to explicitly describe your Builder + Model classes and they are 1:1

Fixes:

- Fixes for users of `SearchCraft.config.explicit_model_class_names` on initialization

## [0.4.0] - 2023-10-24

- Initial public release
