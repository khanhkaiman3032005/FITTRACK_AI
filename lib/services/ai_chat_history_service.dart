import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AiChatHistoryService {
  static SupabaseClient get _supabase => Supabase.instance.client;

  /// Lưu toàn bộ lịch sử chat của tài khoản hiện tại lên Supabase.
  ///
  /// Cách làm:
  /// 1. Xóa lịch sử cũ của đúng user.
  /// 2. Ghi lại danh sách history hiện tại.
  ///
  /// Cách này giữ tương thích với AI Coach hiện tại vì màn hình
  static Future<void> saveHistory(List<Map<String, String>> history) async {
    final user = _supabase.auth.currentUser;

    if (user == null || history.isEmpty) {
      return;
    }

    try {
      // Lấy tin nhắn mới nhất trong history.
      final item = history.last;

      final role = item['role'] ?? '';
      final message = item['text'] ?? '';

      if ((role != 'user' && role != 'assistant') || message.trim().isEmpty) {
        return;
      }

      // Chỉ thêm đúng 1 tin nhắn mới.
      await _supabase.from('ai_chat_messages').insert({
        'user_id': user.id,
        'role': role,
        'message': message.trim(),
      });
    } catch (e, stackTrace) {
      debugPrint('===== SAVE AI CHAT ERROR =====');
      debugPrint('$e');
      debugPrint('$stackTrace');
      debugPrint('==============================');
    }
  }

  /// Load lịch sử của đúng tài khoản đang đăng nhập.
  static Future<List<Map<String, String>>> loadHistory() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return [];
    }

    try {
      final response = await _supabase
          .from('ai_chat_messages')
          .select('role, message, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: true);

      return (response as List).map<Map<String, String>>((item) {
        return {
          'role': item['role']?.toString() ?? '',
          'text': item['message']?.toString() ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint('AiChatHistoryService.loadHistory error: $e');
      return [];
    }
  }

  /// Xóa lịch sử của đúng tài khoản hiện tại.
  static Future<void> clearHistory() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      await _supabase.from('ai_chat_messages').delete().eq('user_id', user.id);
    } catch (e, stackTrace) {
      debugPrint('===== SAVE AI CHAT ERROR =====');
      debugPrint('$e');
      debugPrint('$stackTrace');
      debugPrint('==============================');
    }
  }
}
