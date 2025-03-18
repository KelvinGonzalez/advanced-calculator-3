import 'package:advanced_calculator_3/models/custom_class.dart';
import 'package:supabase/supabase.dart';
import 'package:uuid/v4.dart';

enum SearchSort {
  recent("recent"),
  oldest("oldest"),
  popular("popular");

  final String key;

  const SearchSort(this.key);
}

class SharedClass {
  final String name;
  final CustomClass customClass;
  final String creatorId;
  final int importCount;
  final DateTime createdAt;

  const SharedClass(this.name, this.customClass, this.creatorId,
      this.importCount, this.createdAt);

  static Future<List<SharedClass>> search(
      String query, int page, SearchSort sort, SupabaseClient supabase,
      [int pagesCount = 20]) async {
    final result = List<Map<String, dynamic>>.from(await supabase
        .rpc("search_shared_classes", params: {
      "query": query,
      "page": page,
      "sort": sort.key,
      "pages_count": pagesCount
    }));
    return result
        .map((e) => SharedClass(
            e["class_name"],
            CustomClass.fromJson(e["class_json"]),
            e["creator_id"],
            e["import_count"],
            DateTime.parse(e["created_at"])))
        .toList();
  }

  static Future<int> getSharedClassesCount(SupabaseClient supabase) async {
    return await supabase.rpc("get_shared_classes_count");
  }

  static Future<void> shareClass(CustomClass customClass, String creatorId,
      SupabaseClient supabase) async {
    return await supabase.rpc("add_shared_class", params: {
      "class_name": customClass.name,
      "class_json": customClass.toJson(),
      "creator_id": creatorId
    });
  }

  Future<void> delete(SupabaseClient supabase) async {
    return await supabase.rpc("delete_shared_class",
        params: {"class_name": customClass.name, "creator_id": creatorId});
  }

  Future<void> markImported(SupabaseClient supabase) async {
    return await supabase.rpc("mark_imported",
        params: {"class_name": customClass.name, "creator_id": creatorId});
  }
}
