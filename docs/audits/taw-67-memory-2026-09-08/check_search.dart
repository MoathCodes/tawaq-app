import 'dart:convert';
import 'package:hive_ce/hive.dart';
Future<void> main(List<String> a)async {
 Hive.init(a[0]); final b=await Hive.openBox<String>('search_index');
 print(jsonEncode({'length':b.length,'firstKeys':b.keys.take(3).map((k)=>{'key':k,'type':k.runtimeType.toString(),'hasSeparator':b.get(k)!.contains('|'),'valueLength':b.get(k)!.length}).toList(),'integerKey1':b.containsKey(1),'stringKey1':b.containsKey('1'),'bsmMatches':b.values.where((s)=>s.contains('بسم')).length,'rahmanMatches':b.values.where((s)=>s.contains('الرحمن')).length}));await b.close();
}
