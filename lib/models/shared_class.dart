import 'package:advanced_calculator_3/models/custom_class.dart';
import 'package:aggregated_collection/aggregated_collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum SearchSort { recent, oldest, popular }

class SharedClass {
  final String name;
  final CustomClass customClass;
  final String creatorId;
  final Timestamp createdAt;
  final int importCount;

  const SharedClass(this.name, this.customClass, this.creatorId, this.createdAt,
      this.importCount);

  static SharedClass fromDocument(AggregatedDocumentData document) {
    final customClass = CustomClass.fromJson(document.get("class_data"));
    return SharedClass(
        customClass.name,
        customClass,
        document.get("creator_id"),
        document.get("created_at") ?? Timestamp.now(),
        document.get("import_count"));
  }

  static List<AggregatedDocumentData> search(
      List<AggregatedDocumentData> list, String query, SearchSort sort) {
    return list
        .where((e) =>
            fromDocument(e).name.toLowerCase().startsWith(query.toLowerCase()))
        .toList()
      ..sort((a, b) {
        final classA = fromDocument(a);
        final classB = fromDocument(b);
        switch (sort) {
          case SearchSort.recent:
            return -classA.createdAt.compareTo(classB.createdAt);
          case SearchSort.oldest:
            return classA.createdAt.compareTo(classB.createdAt);
          case SearchSort.popular:
            return -classA.importCount.compareTo(classB.importCount);
        }
      });
  }

  static Future<void> shareClass(CustomClass customClass, String creatorId,
      AggregatedCollection collection) async {
    final id = "$creatorId:${customClass.name}";
    final reference = await collection.doc(id);
    if (reference != null) {
      await reference.update({"class_data": customClass.toJson()});
      return;
    }
    await collection.add({
      "class_data": customClass.toJson(),
      "creator_id": creatorId,
      "created_at": FieldValue.serverTimestamp(),
      "import_count": 0,
    }, id);
  }

  static Future<void> delete(AggregatedDocumentReference reference) async {
    await reference.delete();
  }

  static Future<void> markImported(
      AggregatedDocumentReference reference) async {
    await reference.update({"import_count": FieldValue.increment(1)});
  }
}
