import '../core/match_record.dart';
import 'log_service.dart';
import 'storage_service.dart';

/// 最近对局记录的读写：全部保存在本机偏好存储中，最多保留 [MatchHistory.maxRecords] 场。
class MatchHistoryService {
  MatchHistoryService._();

  static final MatchHistoryService instance = MatchHistoryService._();

  Future<List<MatchRecord>> load() async {
    final storage = await StorageService.instance;
    return MatchHistory.decode(storage.matchHistoryJson);
  }

  Future<List<MatchRecord>> add(MatchRecord record) async {
    final records = await load();
    final next = [
      record,
      ...records.where((item) => item.id != record.id),
    ];
    await _save(next);
    LogService.info(
      '保存对局记录: ${record.title} · ${record.subtitle} · ${record.endReason}',
    );
    return next.take(MatchHistory.maxRecords).toList(growable: false);
  }

  Future<List<MatchRecord>> remove(String id) async {
    final records = await load();
    final next = records.where((item) => item.id != id).toList();
    await _save(next);
    return next;
  }

  Future<void> clear() async {
    final storage = await StorageService.instance;
    await storage.setMatchHistoryJson('');
  }

  Future<void> _save(List<MatchRecord> records) async {
    final storage = await StorageService.instance;
    await storage.setMatchHistoryJson(MatchHistory.encode(records));
  }
}
