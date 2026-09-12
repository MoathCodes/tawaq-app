import 'dart:convert';
import 'dart:io';
import 'package:vm_service/vm_service_io.dart';
Future<void> main(List<String> args) async {
 final vm=await vmServiceConnectUri(args[0]);
 try {
 final info=await vm.getVM();
 final iso=info.isolates!.firstWhere((i)=>i.name=='main',orElse:()=>info.isolates!.first).id!;
 if(args[1]=='memory') {
 print(jsonEncode((await vm.getMemoryUsage(iso)).json));
 final p=await vm.getAllocationProfile(iso,gc:args.contains('gc'));
 final m=p.members!..sort((a,b)=>(b.bytesCurrent??0).compareTo(a.bytesCurrent??0));
 print(jsonEncode({'memory':p.memoryUsage?.json,'classes':m.take(35).map((x)=>{'name':x.classRef?.name,'bytes':x.bytesCurrent,'instances':x.instancesCurrent,'id':x.classRef?.id}).toList()}));
 } else if(args[1]=='info') {print(jsonEncode((await vm.getIsolate(iso)).json));}
 else if(args[1]=='driver') {print(jsonEncode((await vm.callServiceExtension('ext.flutter.driver',isolateId:iso,args:Map<String,dynamic>.from(jsonDecode(args[2])))).json));}
 else {print(jsonEncode((await vm.callServiceExtension(args[1],isolateId:iso,args:args.length>2?Map<String,dynamic>.from(jsonDecode(args[2])):{})).json));}
 }finally {await vm.dispose();}
}
