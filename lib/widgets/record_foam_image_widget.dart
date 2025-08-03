import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';

class RecordFoamImageWidget extends StatefulWidget {
  final List<String>? initialImagePaths;

  const RecordFoamImageWidget({super.key, this.initialImagePaths});

  @override
  State<RecordFoamImageWidget> createState() => RecordFoamImageWidgetState();
}

class RecordFoamImageWidgetState extends State<RecordFoamImageWidget> {
  List<String> _allImagePaths = [];
  bool _isPickingImages = false;

  @override
  void initState() {
    super.initState();
    _updateImagePaths();
  }

  @override
  void didUpdateWidget(RecordFoamImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialImagePaths != widget.initialImagePaths) {
      _updateImagePaths();
    }
  }

  void _updateImagePaths() {
    setState(() {
      _allImagePaths = List.from(widget.initialImagePaths ?? []);
    });
  }

  List<String> getSelectedImagePaths() {
    return _allImagePaths;
  }

  Future<void> _pickImages() async {
    if (_isPickingImages) return;

    setState(() {
      _isPickingImages = true;
    });

    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();
      setState(() {
        _allImagePaths.addAll(images.map((image) => image.path));
      });
    } finally {
      setState(() {
        _isPickingImages = false;
      });
    }
  }

  void _removeImage(String imagePath) {
    setState(() {
      _allImagePaths.remove(imagePath);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('사진', style: AppTextStyle.subTitle),
        SizedBox(height: context.hp(1)),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (_allImagePaths.isNotEmpty) ...[
                ...(_allImagePaths.map(
                  (imagePath) => Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        margin: EdgeInsets.only(right: 8),
                        padding: context.paddingXS,
                        decoration: BoxDecoration(),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                            image: DecorationImage(
                              image: FileImage(File(imagePath)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _removeImage(imagePath),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              LucideIcons.x,
                              color: Colors.white,
                              size: context.lg,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
              if (_allImagePaths.isNotEmpty) SizedBox(width: 8),
              DottedBorder(
                options: RoundedRectDottedBorderOptions(
                  color: AppColors.grey,
                  strokeWidth: 1.5,
                  dashPattern: [3, 3],
                  radius: Radius.circular(16),
                ),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _pickImages();
                  },
                  child: Container(
                    height: 80,
                    width: 80,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.imagePlus,
                          size: 30,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 4),
                        Text(
                          '사진 첨부',
                          style: AppTextStyle.caption.copyWith(
                            color: AppColors.grey,
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
      ],
    );
  }
}
