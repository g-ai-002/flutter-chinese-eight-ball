import '../core/match_history.dart';
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
    final next = await _save([
      record,
      ...records.where((item) => item.id != record.id),
    ]);
    LogService.info(
      '保存对局记录: ${record.title} · ${record.subtitle} · ${record.endReason}',
    );
    return next;
  }

  Future<List<MatchRecord>> remove(String id) async {
    final records = await load();
    return _save(records.where((item) => item.id != id));
  }

  Future<void> clear() async {
    final storage = await StorageService.instance;
    await storage.setMatchHistoryJson('');
  }

  /// 统一排序、裁剪并写入，返回实际保存的记录。
  Future<List<MatchRecord>> _save(Iterable<MatchRecord> records) async {
    final next = MatchHistory.normalize(records);
    final storage = await StorageService.instance;
    await storage.setMatchHistoryJson(MatchHistory.encode(next));
    return next;
  }
}
