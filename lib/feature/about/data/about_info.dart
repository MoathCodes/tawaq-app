import 'package:forui/forui.dart';
import 'package:tawaq/feature/about/domain/models/about_content.dart';

/// Destinations and attribution recorded in README.en.md and bundled licenses.
/// Version is supplied from installed package metadata by AboutView.
const aboutContent = AboutContent(
  appName: 'توّاق',
  latinName: 'Tawaq',
  version: '',
  tagline: AboutText(
    en: 'Prayer, Quran and remembrance',
    ar: 'الصلاة والقرآن والذكر',
  ),
  description: AboutText(
    en: 'A desktop companion for prayer times, Quran reading and study, Hadith search, and Hisn al-Muslim.',
    ar: 'رفيق للحاسوب لمواقيت الصلاة وقراءة القرآن وتدبّره والبحث في الأحاديث وحصن المسلم.',
  ),
  links: [
    AboutLink(
      icon: FLucideIcons.gitBranch,
      label: AboutText(en: 'Source code', ar: 'الشيفرة المصدرية'),
      url: 'https://github.com/MoathCodes/tawaq-app',
    ),
    AboutLink(
      icon: FLucideIcons.bug,
      label: AboutText(en: 'Report an issue', ar: 'الإبلاغ عن مشكلة'),
      url: 'https://github.com/MoathCodes/tawaq-app/issues',
    ),
  ],
  credits: [
    AboutCredit(
      icon: FLucideIcons.users,
      name: AboutText(
        en: 'Application contributors',
        ar: 'المساهمون في التطبيق',
      ),
      url: 'https://github.com/MoathCodes/tawaq-app/graphs/contributors',
    ),
  ],
  acknowledgements: [
    AboutAcknowledgement(
      name: 'adhan_dart',
      description: AboutText(
        en: 'Prayer calculations',
        ar: 'حساب مواقيت الصلاة',
      ),
      url: 'https://github.com/prayer-timetable/adhan_dart',
    ),
    AboutAcknowledgement(
      name: 'Dorar / dorar_hadith',
      description: AboutText(
        en: 'Hadith search and references',
        ar: 'البحث في الأحاديث ومراجعها',
      ),
      url: 'https://dorar.net',
    ),
    AboutAcknowledgement(
      name: 'MP3Quran',
      description: AboutText(
        en: 'Reciter catalog and audio',
        ar: 'قائمة القرّاء والتلاوات',
      ),
      url: 'https://www.mp3quran.net',
    ),
    AboutAcknowledgement(
      name: 'HisnElmoslem_App',
      description: AboutText(
        en: 'Bundled Hisn al-Muslim content',
        ar: 'محتوى حصن المسلم المضمّن',
      ),
      url: 'https://github.com/muslimpack/HisnElmoslem_App',
    ),
    AboutAcknowledgement(
      name: 'King Fahd Quran Printing Complex',
      description: AboutText(
        en: 'Mushaf and Quran fonts; separate source terms',
        ar: 'المصحف وخطوط القرآن؛ وفق شروط المصدر',
      ),
      url: 'https://qurancomplex.gov.sa',
    ),
    AboutAcknowledgement(
      name: 'Athan-MP3',
      description: AboutText(
        en: 'Bundled Adhan recordings',
        ar: 'تسجيلات الأذان المضمّنة',
      ),
      url: 'https://github.com/abodehq/Athan-MP3',
    ),
    AboutAcknowledgement(
      name: 'IBM Plex Sans Arabic / Noto',
      description: AboutText(
        en: 'Interface fonts; included SIL Open Font Licenses',
        ar: 'خطوط الواجهة؛ تراخيص SIL المرفقة',
      ),
    ),
    AboutAcknowledgement(
      name: 'Forui',
      description: AboutText(en: 'Interface components', ar: 'مكوّنات الواجهة'),
      url: 'https://forui.dev',
    ),
  ],
  legal: AboutText(
    en: 'Tawaq-owned code: MIT. Third-party content, software and assets retain their own terms.',
    ar: 'شيفرة توّاق: MIT. يبقى المحتوى والبرمجيات والأصول الخارجية خاضعًا لشروط مصادرها.',
  ),
);
