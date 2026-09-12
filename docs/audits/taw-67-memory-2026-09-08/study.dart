import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tawaq/main.dart' as app;
import 'package:tawaq/app/routing/route_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/translation_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/tafsir_provider.dart';
import 'package:tawaq/feature/quran/domain/models/translation_source.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_source.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
const mode=String.fromEnvironment('STUDY_MODE',defaultValue:'full');
Future<void> pause([int s=5])=>Future.delayed(Duration(seconds:s));
void sample(String label) {
 final dir=Platform.environment['STUDY_OUTPUT']!;
 final cache=PaintingBinding.instance.imageCache;
 final widgets=<String,int>{};
 void visit(Element e){final n=e.widget.runtimeType.toString();widgets[n]=(widgets[n]??0)+1;e.visitChildren(visit);}
 visit(WidgetsBinding.instance.rootElement!);
 print('STUDY ${jsonEncode({'label':label,'pid':pid,'rss':ProcessInfo.currentRss,'peak':ProcessInfo.maxRss,'imageBytes':cache.currentSizeBytes,'imageCount':cache.currentSize,'liveImages':cache.liveImageCount,'widgets':widgets.entries.where((e)=>e.key.endsWith('Screen') || e.key=='HadithPage').map((e)=>'${e.key}:${e.value}').toList(),'view':WidgetsBinding.instance.platformDispatcher.views.map((v)=>'${v.physicalSize.width}x${v.physicalSize.height} @ ${v.devicePixelRatio}').toList()})}');
}
Future<void> main() async {
 if(mode!='full') {
 WidgetsFlutterBinding.ensureInitialized();
 await windowManager.ensureInitialized();
 await windowManager.waitUntilReadyToShow(const WindowOptions(size:Size(720,1080),minimumSize:Size(720,640),title:'TAW-67 memory control'));
 if(mode=='mushaf') await MushafReaderLibrary.ensureInitialized(subDirectory:'tawaq');
 if(mode=='mpv') {MpvAudioKit.ensureInitialized(); final player=Player(); await player.setVolume(0);}
 runApp(const MaterialApp(home:Scaffold(body:Center(child:Text('Memory control')))));
 await windowManager.show(); await pause(10);sample(mode);return;
 }
 await app.main(); await pause(10);sample('prayer-start');
 Element? root;
 void find(Element e){if(e.widget is app.AppBootstrap)root=e;e.visitChildren(find);}
 find(WidgetsBinding.instance.rootElement!);
 final c=ProviderScope.containerOf(root!,listen:false);
 final router=c.read(appRouterProvider);
 for(final route in ['/quran','/hadith','/muslim_fortress','/settings','/prayer']) {
 router.go(route);await pause();sample(route.substring(1));
 }
 router.go('/quran');await pause();
 final mushaf=c.read(quranMushafControllerProvider);await mushaf.ensureReady();
 for(final p in [2,50,100,200,300,400,500,604]){mushaf.jumpToPage(p);await pause(1);}
 sample('quran-eight-pages');
 final hits=await mushaf.searchAyahs('بسم');print('STUDY searchHits=${hits.length}');sample('quran-search');
 for(final source in TranslationId.values){await c.read(translationRepositoryProvider).getTranslation(source,1,1);}
 sample('all-translation-open');
 for(final source in TafsirId.values){await c.read(tafsirRepositoryProvider).getTafsir(source,1,1);}
 sample('all-tafsir-open');await pause(10);sample('all-databases-idle');
 router.go('/prayer');await pause(10);sample('prayer-return');print('STUDY DONE');
}
