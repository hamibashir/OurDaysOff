import '../models/import_preview_entry.dart';
import '../models/picked_rota_file.dart';

enum RotaImportStatus {
  idle,
  loading,
  extracted,
  confirming,
  confirmed,
  error,
}

class RotaImportState {
  final RotaImportStatus status;
  final bool? isPremium;
  final bool isCheckingPremium;
  final PickedRotaFile? selectedFile;
  final double? uploadProgress;
  final List<ImportPreviewEntry> previewEntries;
  final String? errorMessage;
  final String? couponSuccessMessage;
  final bool isRedeemingCoupon;
  final int confirmedCount;

  const RotaImportState({
    this.status = RotaImportStatus.idle,
    this.isPremium,
    this.isCheckingPremium = false,
    this.selectedFile,
    this.uploadProgress,
    this.previewEntries = const [],
    this.errorMessage,
    this.couponSuccessMessage,
    this.isRedeemingCoupon = false,
    this.confirmedCount = 0,
  });

  bool get isLoading => status == RotaImportStatus.loading;
  bool get isConfirming => status == RotaImportStatus.confirming;
  bool get isConfirmed => status == RotaImportStatus.confirmed;
  bool get hasPreview => previewEntries.isNotEmpty;

  RotaImportState copyWith({
    RotaImportStatus? status,
    bool? isPremium,
    bool? isCheckingPremium,
    PickedRotaFile? selectedFile,
    bool clearSelectedFile = false,
    double? uploadProgress,
    List<ImportPreviewEntry>? previewEntries,
    String? errorMessage,
    bool clearError = false,
    String? couponSuccessMessage,
    bool clearCouponSuccess = false,
    bool? isRedeemingCoupon,
    int? confirmedCount,
  }) {
    return RotaImportState(
      status: status ?? this.status,
      isPremium: isPremium ?? this.isPremium,
      isCheckingPremium: isCheckingPremium ?? this.isCheckingPremium,
      selectedFile: clearSelectedFile ? null : (selectedFile ?? this.selectedFile),
      uploadProgress: uploadProgress ?? this.uploadProgress,
      previewEntries: previewEntries ?? this.previewEntries,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      couponSuccessMessage: clearCouponSuccess ? null : (couponSuccessMessage ?? this.couponSuccessMessage),
      isRedeemingCoupon: isRedeemingCoupon ?? this.isRedeemingCoupon,
      confirmedCount: confirmedCount ?? this.confirmedCount,
    );
  }
}
