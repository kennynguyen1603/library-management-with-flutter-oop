abstract class Searchable {
  // Method to check if the object matches a search query
  bool matchesSearch(String query);

  // Method to get searchable fields
  List<String> getSearchableFields();
}
