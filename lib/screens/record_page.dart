import 'package:flutter/material.dart';

class RecordPage extends StatefulWidget {
  @override
  _RecordPageState createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('입병 기록')), body: Center(child: Text('기록 페이지')));
  }
}
