import 'package:soundswap/features/result_history/data/models/result_history_record.dart';
import 'package:soundswap/shared/services/local_json_store.dart';

class ResultHistoryService {
  ResultHistoryService({LocalJsonStore? store})
    : _store = store ?? LocalJsonStore();

  final LocalJsonStore _store;
  static const _fileName = 'result_history.json';

  Future<List<ResultHistoryRecord>> load() async {
    final values = await _store.readList(_fileName);
    return values
        .whereType<Map>()
        .map(
          (value) =>
              ResultHistoryRecord.fromJson(value.cast<String, Object?>()),
        )
        .toList();
  }

  Future<void> saveAll(List<ResultHistoryRecord> records) {
    return _store.writeList(
      _fileName,
      records.map((record) => record.toJson()).toList(),
    );
  }
}
