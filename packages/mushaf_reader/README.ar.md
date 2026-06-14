



# mushaf_reader

**لبنة Flutter بسيطة** لعرض مصحف المدينة المنورة بخطوط [QCF4](https://qurancomplex.gov.sa/). أنت تبني واجهة التطبيق، التنقّل، الإعدادات، والهيكل العام فوق هذه الحزمة.

## ما الذي توفّره الحزمة

- تخطيط مصحف المدينة عبر 604 خط صفحة QCF4 وخط مشترك للعناوين والزخارف
- بيانات القرآن مضمّنة (آيات، سور، أجزاء، تخطيط الصفحات) — بلا اتصال بالشبكة
- ويدجتات قابلة للتركيب: قارئ كامل، صفحة واحدة، آية منفردة، عناصر زخرفية
- `[MushafReaderController](https://pub.dev/documentation/mushaf_reader/latest/mushaf_reader/MushafReaderController-class.html)` اختياري للتنقّل بين الصفحات وتحديد الآيات وجلب البيانات
- `[MushafStyle.modify()](https://pub.dev/documentation/mushaf_reader/latest/mushaf_reader/MushafStyle/MushafStyle.modify.html)` للألوان والأنماط والتحجيم — وليست نظام تصميم جاهزاً

## ما الذي لا توفّره الحزمة

عمداً **لا** تتضمّن:

- تطبيق قرآن كامل (شريط علوي، تبويبات، علامات مرجعية، إعداد أولي)
- تلاوة صوتية، تفسير، ترجمات، أو واجهة بحث
- ثيمات مفروضة بخلاف تنسيق المصحف الأساسي
- إدارة حالة عامة — استخدم Riverpod أو Bloc أو ما يناسبك
- مؤشرات تحميل افتراضية — مرّر `loadingWidget` الخاص بك إن رغبت

إن أردت تجربة تطبيق متكامل، استخدم هذه الحزمة كطبقة عرض وابنِ الباقي بنفسك.

## الميزات


| المجال          | المتوفّر                                                                       |
| --------------- | ------------------------------------------------------------------------------ |
| عرض الصفحات     | `MushafPage`، `MushafPageRange`، `MushafReader` (`pagesPerViewport: 1` أو `2`) |
| النقر والتمييز  | تحديد آية بأنماط قابلة للتخصيص                                                 |
| عناصر الصفحة    | ترويسة السورة، البسملة، علامة الجزء، رقم الصفحة                                |
| نماذج البيانات  | `Ayah`، `Surah`، `Juz`، `QuranPage`، `MushafPageInfo`                          |
| واجهة التنقّل   | `jumpToPage`، `jumpToSurah`، `jumpToJuz`، `jumpToAyah`، `searchAyahs`          |
| ثوابت ومساعدات  | `MushafConstants`، `Ayah.globalIdFor()`، `AyahIdResolver`                      |
| أنواع الاستدعاء | `AyahTapCallback`، `AyahIdTapCallback`، `SurahTapCallback`، …                  |
| الخطوط والتحجيم | `MushafFonts`، `MushafScale`، `MushafTextStyleMerger`                          |


## التثبيت

من جذر مشروع Flutter:

```bash
flutter pub add mushaf_reader
```

يُضاف أحدث إصدار متوافق إلى `pubspec.yaml` تلقائياً. خطوط QCF4 وSVG وبيانات Hive مضمّنة — بلا إعداد أصول يدوي.

## التهيئة

استدعِ مرة واحدة قبل `runApp`:

```dart
import 'package:flutter/material.dart';
import 'package:mushaf_reader/mushaf_reader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MushafReaderLibrary.ensureInitialized();
  runApp(const MyApp());
}
```

اختياري: عزل بيانات Hive في مجلد فرعي:

```dart
await MushafReaderLibrary.ensureInitialized(subDirectory: 'my_app');
```

## استخدام بسيط

قارئ قابل للسحب مع معالجة النقر على الآية:

```dart
class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  late final MushafReaderController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MushafReaderController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MushafReader(
      controller: _controller,
      onAyahTap: (ayah) => debugPrint(ayah.reference),
    );
  }
}
```

عرض صفحة واحدة داخل تخطيطك:

```dart
MushafPage(
  page: 1,
  onAyahIdTap: (ayahId) => debugPrint('ayah $ayahId'),
)
```

## نطاق آيات

اعرض مجموعة آيات على صفحة واحدة أو عبر صفحات — بلا تصفية يدوية للمقاطع أو قواعد بسملة. أضف إطار البطاقة أو التذييل أو التصدير في تطبيقك.

```dart
MushafPageRange.onPage(
  page: 1,
  startAyahId: 1,
  endAyahId: 3,
  showSurahHeader: true,
  showBasmalah: true,
)
```

## الاستدعاءات (Callbacks)

ويدجتات القارئ و`MushafPage` تستخدم أشكال استدعاء مختلفة عن قصد:


| الويدجت        | الاستدعاء     | ما يُستلم                                             |
| -------------- | ------------- | ----------------------------------------------------- |
| `MushafReader` | `onAyahTap`   | نموذج `Ayah` كامل                                     |
| `MushafPage`   | `onAyahIdTap` | المعرّف العام للآية (`1`–`MushafConstants.ayahCount`) |


حوّل المعرّف إلى نموذج عبر المتحكّم أو المستودع:

```dart
MushafPage(
  page: 1,
  onAyahIdTap: (ayahId) async {
    final ayah = await controller.getAyah(ayahId);
    debugPrint(ayah.reference);
  },
)
```

## عرض صفحتين

```dart
MushafReader(
  pagesPerViewport: 2,
  onAyahTap: (ayah) => debugPrint(ayah.reference),
  onSpreadChanged: (info) => debugPrint(info.$1.pageNumber),
)
```

## الثوابت ومعرّفات الآيات

استخدم `[MushafConstants](https://pub.dev/documentation/mushaf_reader/latest/mushaf_reader/MushafConstants-class.html)` بدل الأرقام الثابتة:

```dart
PageView.builder(
  itemCount: MushafConstants.pageCount,
  itemBuilder: (_, index) => MushafPage(page: index + 1),
);
```

حوّل سورة + آية إلى معرّف عام بلا قراءة من التخزين:

```dart
final id = Ayah.globalIdFor(surah: 2, ayahInSurah: 255); // 262
```

عند توفّر بيانات السور من التخزين، يوفّر `[AyahIdResolver](https://pub.dev/documentation/mushaf_reader/latest/mushaf_reader/AyahIdResolver-class.html)` نفس التحويل بجداول بداية مخصّصة.

## الويدجتات والمتحكّم الرئيسي


| الواجهة                                       | الدور                                                                                         |
| --------------------------------------------- | --------------------------------------------------------------------------------------------- |
| `MushafReader`                                | قارئ قابل للسحب؛ `pagesPerViewport: 1` (افتراضي) أو `2` للعرض المزدوج                         |
| `MushafPage`                                  | صفحة مصحف واحدة — للتخطيطات المخصّصة                                                          |
| `MushafReaderController`                      | تنقّل، تحديد، وجلب بيانات غير متزامن؛ يعرض `repository` للوصول المباشر إلى `IQuranRepository` |
| `AyahWidget`                                  | آية منفردة بالمعرّف العام أو سورة:آية                                                         |
| `BasmalahWidget`، `SurahHeaderWidget`، وغيرها | قطع منخفضة المستوى لواجهات مخصّصة                                                             |


## خطافات التخصيص

**التنسيق** — إعداد المعدّلات فقط عبر `[MushafStyle.modify()](https://pub.dev/documentation/mushaf_reader/latest/mushaf_reader/MushafStyle/MushafStyle.modify.html)`:

```dart
MushafReader(
  style: MushafStyle.modify(
    ayah: (s) => s.copyWith(color: const Color(0xFF1B4332)),
    activeAyah: (s) => s.copyWith(
      backgroundColor: const Color(0xFF2D6A4F),
      color: Colors.white,
    ),
    scale: MushafScale(readingBoost: 1.08, minScale: 0.6, maxScale: 1.5),
  ),
)
```

سلسلة تعديلات إضافية بـ `.modify(...)`:

```dart
final style = MushafStyle.modify(
  ayah: (s) => s.copyWith(color: Colors.brown),
).modify(
  activeAyah: (s) => s.copyWith(backgroundColor: Colors.amber),
  scale: MushafScale(readingBoost: 1.08),
);
```

استخدم مُنشئ `MushafStyle(...)` عند الحاجة إلى `TextStyle` صريحة. معاملات `*StyleModifier` القديمة ما زالت مدعومة.

**التحميل** — الافتراضي بلا مؤشر (`MushafLoading.none`):

```dart
MushafReader(
  loadingWidget: const CircularProgressIndicator(),
  pageLoadingWidget: const CircularProgressIndicator(),
)
```

**قراءة فقط:**

```dart
MushafPage(page: 1, enableAyahHighlight: false)
```

**الاتجاه** — `MushafReader` يستخدم `TextDirection.rtl` افتراضياً.

## تطبيق المثال

راجع `[example/](example/)` لكتالوج عروض (`MushafReader`، عرض صفحتين، `MushafPage`، `MushafPageRange`، ويدجات مستقلة). من جذر الحزمة:

```bash
cd example && flutter pub get && flutter run
```

## توثيق الواجهة البرمجية

- [مرجع pub.dev](https://pub.dev/documentation/mushaf_reader/latest/)
- محلياً: `dart doc .`

## الأصول المضمّنة


| الأصل               | الغرض                                           |
| ------------------- | ----------------------------------------------- |
| `assets/otf_fonts/` | 604 خط صفحة QCF4 وخط مشترك للعناوين             |
| `assets/hive/`      | نص القرآن وبيانات السور والأجزاء وتخطيط الصفحات |
| `assets/images/`    | SVG لترويسات السور والزخارف                     |


البيانات تُنسخ من Hive عند أول تشغيل. JSON تحت `assets/jsons/` للمطوّرين فقط ولا يُنشر على pub.dev.

حجم الحزمة كبير (نحو 600 ملف خط). خطّط لحجم التطبيق وفقاً لذلك.

## شكر وتقدير

مصادر ممتازة ساهمت في تصميم هذه المكتبة وبنائها:

- [Wahy](https://main.wahy.net/en/)
- [quran_library](https://pub.dev/packages/quran_library)

## الأصول من جهات خارجية

- **خطوط QCF4** — برمجيات حرة ملكية (proprietary freeware) من [مجمع الملك فهد لطباعة المصحف الشريف](https://qurancomplex.gov.sa/). مجانية للاستخدام في التطبيقات؛ **ليست** ضمن رخصة MIT. إعادة التوزيع والتعديل تخضع لشروط المجمع.

## الترخيص

- **كود الحزمة** — [رخصة MIT](LICENSE)
- **ملفات خطوط QCF4** — برمجيات حرة ملكية؛ راجع [الأصول من جهات خارجية](#الأصول-من-جهات-خارجية) والإشعار في نهاية [LICENSE](LICENSE)

