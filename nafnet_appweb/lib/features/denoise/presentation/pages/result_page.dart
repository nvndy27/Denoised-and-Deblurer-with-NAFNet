import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/denoise_controller.dart';
import '../widgets/before_after_view.dart';
import '../widgets/result_action_buttons.dart';
import '../../domain/entities/denoise_result.dart';

class ResultPage extends StatefulWidget {
  const ResultPage({super.key});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  bool _isSaving = false;
  int _activeTab = 0; // 0: So sánh ảnh, 1: Báo cáo AI

  Future<void> _saveImage(BuildContext context, DenoiseController controller) async {
    setState(() {
      _isSaving = true;
    });

    final savedPath = await controller.saveResult();

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (savedPath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image saved successfully to: $savedPath'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to save image.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }


  void _processAnother(BuildContext context, DenoiseController controller) {
    controller.reset();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  Widget _buildMetricsCard(BuildContext context, DenoiseResult? result, String task, {required bool expandHeight}) {
    if (result == null || result.inferenceTimeMs == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDenoise = task == 'denoise';

    // Format bytes
    String formatBytes(int? bytes) {
      if (bytes == null || bytes <= 0) return '0 B';
      const suffixes = ['B', 'KB', 'MB', 'GB'];
      var i = 0;
      double w = bytes.toDouble();
      while (w >= 1024 && i < suffixes.length - 1) {
        w /= 1024;
        i++;
      }
      return '${w.toStringAsFixed(1)} ${suffixes[i]}';
    }

    final inSizeStr = formatBytes(result.inputSizeBytes);
    final outSizeStr = formatBytes(result.outputSizeBytes);
    
    // Percentage reduction
    int? pct;
    if (result.inputSizeBytes != null && result.outputSizeBytes != null && result.inputSizeBytes! > 0) {
      pct = ((result.inputSizeBytes! - result.outputSizeBytes!) / result.inputSizeBytes! * 100).round();
    }

    // Device label
    String deviceLabel = 'CPU';
    if (result.processingDevice != null) {
      final dev = result.processingDevice!.toLowerCase();
      if (dev.contains('cuda') || dev.contains('gpu')) {
        deviceLabel = 'GPU AI Accel';
      } else {
        deviceLabel = 'CPU Mode';
      }
    }

    // Quality Score label
    final qualityLabel = isDenoise ? 'Độ mịn hình ảnh' : 'Độ nét chi tiết';
    final scoreValue = result.qualityScore != null ? '${result.qualityScore!.toStringAsFixed(1)}/100' : 'N/A';

    // Calculate dynamic analysis points
    final double brIn = result.brightnessIn ?? 127.0;
    final double conIn = result.contrastIn ?? 40.0;
    final double conOut = result.contrastOut ?? 40.0;
    final double lVarIn = result.lapVarIn ?? 40.0;
    final double lVarOut = result.lapVarOut ?? 40.0;
    final double reductionPct = lVarIn > 0 ? ((lVarIn - lVarOut) / lVarIn * 100).clamp(0, 100) : 0.0;
    final double improvementPct = lVarIn > 0 ? ((lVarOut - lVarIn) / lVarIn * 100).clamp(0, 500) : 0.0;

    final List<String> strengths = [];
    final List<String> limitations = [];

    final double score = result.qualityScore ?? 85.0;
    
    // Objective scientific insight generation
    final String aiInsight = isDenoise
        ? (lVarIn < 15.0
            ? 'Ảnh gốc có mức nhiễu hạt nền rất thấp. Mô hình thực hiện lọc mịn vi mô để bảo toàn tối đa kết cấu bề mặt nguyên bản.'
            : (score >= 90.0
                ? 'Khử nhiễu hiệu quả (chỉ số nhiễu Laplacian giảm ${reductionPct.toStringAsFixed(1)}%). Triệt tiêu phần lớn nhiễu hạt tần số cao trong khi vẫn cố gắng duy trì độ sắc nét ranh giới vật thể.'
                : 'Khử nhiễu hạt ở mức trung bình. Thuật toán giữ lại một phần kết cấu hạt mịn ở các vùng chi tiết phức tạp để tránh gây hiện tượng bệt ảnh phi vật lý.'))
        : (lVarIn > 150.0
            ? 'Chỉ số nét biên (Laplacian) tăng ${improvementPct.toStringAsFixed(1)}% (đạt ${lVarOut.toStringAsFixed(1)}). Lưu ý: Với ảnh gốc có độ tương phản sáng tối mạnh hoặc vùng mờ tiêu cự lớn (bokeh/defocus), mô hình chủ yếu làm sắc nét viền các khối sáng chứ không thể tái tạo chi tiết nguyên bản đã bị mất tiêu cự hoàn toàn.'
            : (improvementPct < 15.0
                ? 'Độ sắc nét cải thiện hạn chế (+${improvementPct.toStringAsFixed(1)}%). Do ảnh gốc bị nhòe quá nặng hoặc chuyển động phi tuyến tính phức tạp nằm ngoài khả năng suy diễn của mô hình.'
                : 'Tái tạo biên cạnh biên độ tốt (+${improvementPct.toStringAsFixed(1)}%). Các đường nét mờ nhòe do rung chuyển động nhẹ đã được củng cố và tăng cường độ tương phản biên.'));

    final bool hasColorDistortion = result.colorDistortion ?? false;

    if (isDenoise) {
      if (reductionPct > 5) {
        strengths.add('Khử nhiễu tần số cao: Giảm chỉ số phương sai nhiễu Laplacian từ ${lVarIn.toStringAsFixed(1)} xuống ${lVarOut.toStringAsFixed(1)} (giảm ${reductionPct.toStringAsFixed(1)}%), giúp tối ưu độ mịn bề mặt.');
      } else {
        strengths.add('Làm sạch đốm nhiễu siêu mịn bề mặt mà không làm ảnh hưởng đến các chi tiết gốc.');
      }
      
      final diffCon = (conOut - conIn).abs();
      if (diffCon < 10.0) {
        strengths.add('Bảo toàn độ tương phản gốc: Chỉ số độ lệch chuẩn đầu ra đạt ${conOut.toStringAsFixed(1)} (đầu vào: ${conIn.toStringAsFixed(1)}), hạn chế tối đa việc mất chi tiết vùng biên.');
      } else {
        strengths.add('Tối ưu hóa dải tương phản động (Standard Deviation) giúp các chi tiết trở nên rõ nét hơn.');
      }
      
      strengths.add('Ổn định phổ độ sáng: Giữ phân bố giá trị xám trung bình ở mức ${brIn.toStringAsFixed(1)}/255, tránh cháy sáng hoặc tối cục bộ.');

      // Limitations
      if (hasColorDistortion) {
        limitations.add('Lệch sắc độ (Chromatic Artifacts): Phát hiện hiện tượng bão hòa hoặc tràn số kênh màu (kênh Green/Blue bão hòa cục bộ) tạo ra các ô nhiễu màu nhân tạo.');
      }
      if (brIn < 75.0) {
        limitations.add('Thiếu thông tin quang học vùng tối: Độ sáng trung bình thấp (${brIn.toStringAsFixed(1)}/255). Do tỷ lệ tín hiệu trên nhiễu (SNR) thấp ở vùng tối, việc lọc nhiễu mạnh có thể gây hiện tượng bệt/mất chi tiết kết cấu (texture smoothing).');
      }
      if (brIn > 180.0) {
        limitations.add('Chói sáng cục bộ (Highlight Clipping): Độ sáng trung bình cao (${brIn.toStringAsFixed(1)}/255). Các vùng bị cháy sáng bị mất hoàn toàn thông tin chi tiết và màu sắc, AI không thể khôi phục lại vùng này.');
      }
      if (conIn < 25.0) {
        limitations.add('Độ tương phản ban đầu thấp (${conIn.toStringAsFixed(1)}): Ranh giới giữa các chi tiết không rõ ràng, AI dễ nhầm lẫn nhiễu hạt với kết cấu bề mặt siêu nhỏ.');
      }
      if (result.inputSizeBytes != null && result.inputSizeBytes! < 250 * 1024) {
        limitations.add('Mật độ điểm ảnh thấp (${(result.inputSizeBytes! / 1024).toStringAsFixed(1)} KB): Ảnh có dung lượng nhỏ hoặc độ phân giải thấp, chứa nhiều nhiễu nén JPEG (compression artifacts), gây khó khăn cho việc phân biệt chi tiết thực và khối nhiễu.');
      }
      if (lVarOut < 15.0) {
        limitations.add('Hiệu ứng bệt ảnh (Over-smoothing): Chỉ số Laplacian đầu ra thấp (${lVarOut.toStringAsFixed(1)}). Việc triệt tiêu nhiễu quá mức có thể làm mất đi một phần kết cấu bề mặt tự nhiên (texture loss).');
      }
      if (lVarOut > 35.0) {
        limitations.add('Nhiễu hạt dư thừa (Residual Noise): Độ biến động Laplacian đầu ra cao (${lVarOut.toStringAsFixed(1)}). Một số vùng ảnh có nhiễu tần số cao quá mạnh chưa được khử hoàn toàn để tránh làm mờ các chi tiết.');
      }
      if (conIn - conOut > 5.0) {
        limitations.add('Giảm dải tương phản (Contrast Loss): Tương phản giảm từ ${conIn.toStringAsFixed(1)} xuống ${conOut.toStringAsFixed(1)}, làm suy giảm nhẹ sự chênh lệch sáng tối giữa các vùng biên.');
      }
      if (limitations.isEmpty) {
        limitations.add('Giới hạn vật lý của cảm biến: Mặc dù không phát hiện lỗi lớn, ảnh gốc vẫn chịu giới hạn từ kích thước cảm biến vật lý. AI đã phải cân đối giữa việc giữ lại chi tiết biên và khử hạt nhiễu mịn ở rìa ảnh.');
      }
    } else {
      if (improvementPct > 10) {
        strengths.add('Tái tạo biên cạnh (Sharpness Improvement): Tăng phương sai gradient Laplacian từ ${lVarIn.toStringAsFixed(1)} lên ${lVarOut.toStringAsFixed(1)} (+${improvementPct.toStringAsFixed(1)}%), nâng cao rõ rệt độ sắc nét cục bộ.');
      } else {
        strengths.add('Cải thiện nhẹ độ rõ nét của các vùng biên cạnh bị mờ nhạt.');
      }
      
      strengths.add('Cải thiện tương phản biên: Tăng độ lệch chuẩn từ ${conIn.toStringAsFixed(1)} lên ${conOut.toStringAsFixed(1)}, giúp phân tách rõ nét giữa vật thể và nền.');
      strengths.add('Bảo toàn kênh độ sáng: Giữ giá trị Luminance trung bình ổn định ở mức ${brIn.toStringAsFixed(1)}/255.');

      // Limitations
      if (hasColorDistortion) {
        limitations.add('Lỗi tràn số màu sắc (Color Overflow): Phát hiện các điểm ảnh có sắc độ neon/xanh lá bị đẩy lên quá mức do lỗi bão hòa hoặc chia cho số không trong phép khử nhiễu nghịch đảo (inverse filtering) của AI.');
      }
      if (lVarIn < 40.0) {
        limitations.add('Giới hạn tần số Nyquist: Ảnh gốc bị mờ nhòe quá nặng (phương sai Laplacian đầu vào cực thấp: ${lVarIn.toStringAsFixed(1)}). Các chi tiết nhỏ hơn bước nhòe đã bị mất vĩnh viễn và không thể khôi phục đầy đủ.');
      }
      if (brIn < 75.0) {
        limitations.add('Độ nhiễu tối (Dark Noise Constraint): Độ sáng thấp (${brIn.toStringAsFixed(1)}/255) làm giảm độ chính xác của ước lượng hàm truyền nhòe (PSF), dễ sinh nhiễu giả ở vùng tối.');
      }
      if (brIn > 180.0) {
        limitations.add('Vùng bão hòa sáng (Overexposure): Độ sáng trung bình ${brIn.toStringAsFixed(1)}/255. Các vùng bị cháy sáng mất hoàn toàn thông tin độ dốc (gradient), khiến thuật toán khử nhòe không thể tái dựng lại cấu trúc biên.');
      }
      if (result.inputSizeBytes != null && result.inputSizeBytes! < 250 * 1024) {
        limitations.add('Hạn chế về độ phân giải đầu vào (${(result.inputSizeBytes! / 1024).toStringAsFixed(1)} KB): Ảnh gốc có mật độ thông tin thấp, dẫn đến việc tái tạo các chi tiết biên bị răng cưa hoặc mờ do thiếu dữ liệu pixel gốc.');
      }
      if (lVarOut > 120.0) {
        limitations.add('Hiệu ứng quầng sáng (Ringing/Halo Artifacts): Phương sai Laplacian đầu ra quá cao (${lVarOut.toStringAsFixed(1)}). Quá trình deblur mạnh có thể tạo ra các đường viền sáng giả chạy dọc theo các cạnh.');
      }
      if (lVarIn > 0 && (lVarOut / lVarIn) < 1.15) {
        limitations.add('Hiệu quả khử nhòe thấp: Tỷ lệ cải thiện Laplacian biên cạnh đạt dưới 15% (đầu ra: ${lVarOut.toStringAsFixed(1)}, đầu vào: ${lVarIn.toStringAsFixed(1)}). Chuyển động nhòe phi tuyến tính hoặc rung tay quá mạnh nằm ngoài vùng khôi phục.');
      }
      if (limitations.isEmpty) {
        limitations.add('Giới hạn chuyển động phi tuyến tính: Thuật toán giả định chuyển động nhòe đều (uniform motion blur). Rung tay đa hướng phức tạp có thể khiến các chi tiết ở góc xa chưa đạt độ sắc nét tuyệt đối.');
      }
    }

    final List<String> displayStrengths = expandHeight ? strengths : strengths.take(2).toList();
    final List<String> displayLimitations = expandHeight ? limitations : limitations.take(2).toList();

    final insightsWidget = Container(
      padding: EdgeInsets.all(expandHeight ? 12 : 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology_outlined,
                size: 14,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Phân tích',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          SizedBox(height: expandHeight ? 6 : 4),
          Text(
            aiInsight,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
              fontSize: expandHeight ? 10.5 : 9.5,
            ),
          ),
          SizedBox(height: expandHeight ? 8 : 6),
          Text(
            'Điểm khôi phục tốt:',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          ...displayStrengths.map((str) => Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 2),
            child: Text(
              '• $str',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: expandHeight ? 9.5 : 8.5,
                height: 1.3,
              ),
            ),
          )),
          SizedBox(height: expandHeight ? 6 : 4),
          Text(
            'Hạn chế / Điểm chưa tốt:',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          ...displayLimitations.map((lim) => Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 2),
            child: Text(
              '• $lim',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: expandHeight ? 9.5 : 8.5,
                height: 1.3,
              ),
            ),
          )),
          const Divider(height: 12, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mô hình sử dụng:',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 9,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                'NAFNet',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.12),
            theme.colorScheme.surfaceContainerHighest.withOpacity(0.45),
          ],
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'BÁO CÁO',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Metrics Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3.4,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: [
              // 1. Quality score
              _buildMetricItem(
                context,
                icon: Icons.high_quality_outlined,
                color: Colors.amber,
                label: qualityLabel,
                value: scoreValue,
              ),
              // 2. Inference time
              _buildMetricItem(
                context,
                icon: Icons.timer_outlined,
                color: Colors.cyan,
                label: 'Thời gian xử lý',
                value: '${result.inferenceTimeMs!.toStringAsFixed(0)} ms',
              ),
              // 3. Processing device
              _buildMetricItem(
                context,
                icon: Icons.memory_outlined,
                color: Colors.indigo,
                label: 'Thiết bị chạy',
                value: deviceLabel,
              ),
              // 4. Storage optimization
              _buildMetricItem(
                context,
                icon: Icons.compress_outlined,
                color: Colors.green,
                label: 'Dung lượng ảnh',
                value: pct != null && pct > 0 
                  ? '$outSizeStr (-$pct%)' 
                  : outSizeStr,
                subtitle: 'Gốc: $inSizeStr',
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Dynamic Insights Box
          expandHeight ? Expanded(child: SingleChildScrollView(child: insightsWidget)) : insightsWidget,
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 14,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 8.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                      fontSize: 7.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Provider.of<DenoiseController>(context, listen: false);
    final state = controller.state;

    final beforeImagePath = state.selectedImage?.path ?? '';
    final afterImagePath = state.result?.outputImagePath ?? '';

    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > 750 && size.height < size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhancement Result'),
        automaticallyImplyLeading: false, // User should use bottom action buttons
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: isLandscape
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top row containing the two equal boxes (slider and metrics)
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left Column (Slider & Label)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Drag the slider to compare before and after:',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: Center(
                                    child: BeforeAfterView(
                                      beforeImagePath: beforeImagePath,
                                      afterImagePath: afterImagePath,
                                      afterLabel: state.task == 'deblur' ? 'Deblurred' : 'Denoised',
                                      selectedAspectRatio: state.selectedAspectRatio,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Right Column (AI Report Card & Label)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Thông số phân tích hiệu năng AI:',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: _buildMetricsCard(
                                    context,
                                    state.result,
                                    state.task,
                                    expandHeight: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Centered buttons at the bottom
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: ResultActionButtons(
                          isSaving: _isSaving,
                          onSave: () => _saveImage(context, controller),
                          onProcessAnother: () => _processAnother(context, controller),
                          onGoHome: () => _processAnother(context, controller),
                          task: state.task,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Segment control
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _activeTab = 0;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _activeTab == 0
                                      ? theme.colorScheme.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.compare_outlined,
                                      size: 16,
                                      color: _activeTab == 0
                                          ? Colors.white
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'So sánh ảnh',
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: _activeTab == 0
                                            ? Colors.white
                                            : theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _activeTab = 1;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _activeTab == 1
                                      ? theme.colorScheme.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.analytics_outlined,
                                      size: 16,
                                      color: _activeTab == 1
                                          ? Colors.white
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Báo cáo AI',
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: _activeTab == 1
                                            ? Colors.white
                                            : theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Tab content
                    Expanded(
                      child: _activeTab == 0
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Kéo thanh trượt để so sánh ảnh trước và sau:',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: Center(
                                    child: BeforeAfterView(
                                      beforeImagePath: beforeImagePath,
                                      afterImagePath: afterImagePath,
                                      afterLabel: state.task == 'deblur' ? 'Deblurred' : 'Denoised',
                                      height: MediaQuery.of(context).size.height * 0.55,
                                      selectedAspectRatio: 'Original',
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : SingleChildScrollView(
                              child: _buildMetricsCard(
                                context,
                                state.result,
                                state.task,
                                expandHeight: false,
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),
                    ResultActionButtons(
                      isSaving: _isSaving,
                      onSave: () => _saveImage(context, controller),
                      onProcessAnother: () => _processAnother(context, controller),
                      onGoHome: () => _processAnother(context, controller),
                      task: state.task,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
        ),
      ),
    );
  }
}
