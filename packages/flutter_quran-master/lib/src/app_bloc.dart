import 'package:flutter_bloc/flutter_bloc.dart';

import 'controllers/quran_controller.dart';

class AppBloc {
  static final quranCubit = QuranCubit();

  static final List<BlocProvider> providers = [
    BlocProvider<QuranCubit>(create: (context) => quranCubit),
  ];

  static void dispose() {
    quranCubit.close();
  }

  ///Singleton factory
  static final AppBloc _instance = AppBloc._internal();

  factory AppBloc() {
    return _instance;
  }

  AppBloc._internal();
}
