import 'package:flutter/material.dart';
import 'package:medical_records/styles/app_size.dart';

class ImageListWidget extends StatefulWidget {
  const ImageListWidget({super.key});

  @override
  _ImageListWidgetState createState() => _ImageListWidgetState();
}

class _ImageListWidgetState extends State<ImageListWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: AppSize.hp(10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              showDialog(context: context, builder: (context) => Dialog(child: Image.asset('assets/images/sample.jpeg')));
            },
            child: Container(
              width: AppSize.hp(10),
              margin: EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
              child: Image.asset('assets/images/sample.jpeg'),
            ),
          );
        },
      ),
    );
  }
}
