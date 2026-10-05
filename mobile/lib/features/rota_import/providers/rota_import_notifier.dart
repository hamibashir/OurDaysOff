import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/error_handler.dart';
import '../models/import_preview_entry.dart';
import '../models/picked_rota_file.dart';
import '../repositories/rota_import_repository.dart';
import 'rota_import_state.dart';

class RotaImportNotifier extends StateNotifier<RotaImportState> {
  final RotaImportRepository _repository;

  RotaImportNotifier(this._repository) : super(const RotaImportState()) {
    checkPremium();
  }

  Future<void> checkPremium() async {
    state = state.copyWith(isCheckingPremium: true);
    try {
      final isPrem = await _repository.checkPremiumStatus();
      state = state.copyWith(
        isPremium: isPrem,
        isCheckingPremium: false,
      );
    } catch (_) {
      // Default to false on error
      state = state.copyWith(
        isPremium: false,
        isCheckingPremium: false,
      );
    }
  }

  void setSelectedFile(PickedRotaFile? file) {
    state = state.copyWith(
      selectedFile: file,
      clearSelectedFile: file == null,
      clearError: true,
    );
  }

  Future<void> uploadAndExtract() async {
    final file = state.selectedFile;
    if (file == null) {
      state = state.copyWith(errorMessage: 'Please select a rota file or take a photo.');
      return;
    }

    state = state.copyWith(
      status: RotaImportStatus.loading,
      uploadProgress: 0.0,
      clearError: true,
    );

    try {
      final entries = await _repository.uploadAndExtractRota(
        file,
        onSendProgress: (sent, total) {
          if (total > 0) {
            state = state.copyWith(uploadProgress: sent / total);
          }
        },
      );

      if (entries.isEmpty) {
        state = state.copyWith(
          status: RotaImportStatus.error,
          errorMessage: 'No shifts could be extracted from this image. Please ensure shift times and dates are clearly visible, or use External AI mode.',
        );
        return;
      }

      state = state.copyWith(
        status: RotaImportStatus.extracted,
        previewEntries: entries,
        uploadProgress: 1.0,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        status: RotaImportStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: RotaImportStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void parseExternalJson(String rawJson) {
    state = state.copyWith(
      status: RotaImportStatus.loading,
      clearError: true,
    );

    try {
      final entries = _repository.parseExternalAiJson(rawJson);
      state = state.copyWith(
        status: RotaImportStatus.extracted,
        previewEntries: entries,
      );
    } on FormatException catch (e) {
      state = state.copyWith(
        status: RotaImportStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: RotaImportStatus.error,
        errorMessage: 'Failed to parse JSON: ${e.toString()}',
      );
    }
  }

  Future<bool> redeemCoupon(String code) async {
    if (code.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter a coupon code.');
      return false;
    }

    state = state.copyWith(
      isRedeemingCoupon: true,
      clearError: true,
      clearCouponSuccess: true,
    );

    try {
      final isPrem = await _repository.redeemCoupon(code);
      state = state.copyWith(
        isPremium: isPrem,
        isRedeemingCoupon: false,
        couponSuccessMessage: 'VIP Premium activated successfully!',
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        isRedeemingCoupon: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isRedeemingCoupon: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void updatePreviewEntry(int index, ImportPreviewEntry updated) {
    if (index < 0 || index >= state.previewEntries.length) return;
    final list = [...state.previewEntries];
    list[index] = updated;
    state = state.copyWith(previewEntries: list);
  }

  void removePreviewEntry(int index) {
    if (index < 0 || index >= state.previewEntries.length) return;
    final list = [...state.previewEntries]..removeAt(index);
    state = state.copyWith(
      previewEntries: list,
      status: list.isEmpty ? RotaImportStatus.idle : state.status,
    );
  }

  void addManualEntry(ImportPreviewEntry entry) {
    final list = [...state.previewEntries, entry];
    state = state.copyWith(
      previewEntries: list,
      status: RotaImportStatus.extracted,
    );
  }

  Future<bool> confirmImport() async {
    if (state.previewEntries.isEmpty) {
      state = state.copyWith(errorMessage: 'No shifts to import.');
      return false;
    }

    state = state.copyWith(
      status: RotaImportStatus.confirming,
      clearError: true,
    );

    try {
      final count = state.previewEntries.length;
      await _repository.confirmBatchImport(state.previewEntries);

      state = state.copyWith(
        status: RotaImportStatus.confirmed,
        confirmedCount: count,
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        status: RotaImportStatus.extracted,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: RotaImportStatus.extracted,
        errorMessage: 'Failed to confirm import: ${e.toString()}',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void reset() {
    state = state.copyWith(
      status: RotaImportStatus.idle,
      clearSelectedFile: true,
      uploadProgress: null,
      previewEntries: const [],
      clearError: true,
      clearCouponSuccess: true,
      confirmedCount: 0,
    );
  }
}

final rotaImportNotifierProvider =
    StateNotifierProvider<RotaImportNotifier, RotaImportState>((ref) {
  final repository = ref.watch(rotaImportRepositoryProvider);
  return RotaImportNotifier(repository);
});
