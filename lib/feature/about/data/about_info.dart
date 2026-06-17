import 'package:forui/forui.dart';
import 'package:tawaq/feature/about/domain/models/about_content.dart';

/// The content shown by the about dialog.
///
/// ────────────────────────────────────────────────────────────────────────
/// THIS IS THE ONE FILE TO EDIT.
/// ────────────────────────────────────────────────────────────────────────
/// Everything below is placeholder/mock data — swap the strings, links and
/// people for the real details. To add a row, append another entry to the
/// relevant list. To hide a whole section, leave its list empty.
///
/// Icons come from [FLucideIcons]; browse them at https://lucide.dev/icons.
const aboutContent = AboutContent(
  appName: 'توّاق',
  latinName: 'TAWAQ',
  version: 'v1.0.0',
  tagline: AboutText(
    en: 'Your companion for prayer, Qurʼan and remembrance',
    ar: 'رفيقك في الصلاة والقرآن والذكر',
  ),
  description: AboutText(
    en: 'Tawaq gathers accurate prayer times, the Mushaf, hadith and the '
        'fortress of the Muslim into one calm, distraction-free space — '
        'crafted for both desktop and mobile.',
    ar: 'يجمع توّاق مواقيت الصلاة الدقيقة والمصحف والأحاديث وحصن المسلم في '
        'مكانٍ واحدٍ هادئ خالٍ من المشتتات — صُمّم للحاسوب والهاتف معًا.',
  ),

  // ── Quick facts strip ──────────────────────────────────────────────────
  facts: [
    AboutFact(
      icon: FLucideIcons.tag,
      label: AboutText(en: 'Version', ar: 'الإصدار'),
      value: AboutText.shared('1.0.0'),
    ),
    AboutFact(
      icon: FLucideIcons.calendar,
      label: AboutText(en: 'Released', ar: 'تاريخ الإصدار'),
      value: AboutText.shared('2026'),
    ),
    AboutFact(
      icon: FLucideIcons.monitorSmartphone,
      label: AboutText(en: 'Platform', ar: 'المنصّة'),
      value: AboutText(en: 'Desktop & Mobile', ar: 'حاسوب وهاتف'),
    ),
  ],

  // ── Links ────────────────────────────────────────────────────────────────
  links: [
    AboutLink(
      icon: FLucideIcons.globe,
      label: AboutText(en: 'Website', ar: 'الموقع الإلكتروني'),
      url: 'https://example.com',
      description: AboutText.shared('tawaq.app'),
    ),
    AboutLink(
      icon: FLucideIcons.gitBranch,
      label: AboutText(en: 'Source code', ar: 'الشيفرة المصدرية'),
      url: 'https://github.com/example/tawaq',
    ),
    AboutLink(
      icon: FLucideIcons.bug,
      label: AboutText(en: 'Report an issue', ar: 'الإبلاغ عن مشكلة'),
      url: 'https://github.com/example/tawaq/issues',
    ),
    AboutLink(
      icon: FLucideIcons.mail,
      label: AboutText(en: 'Contact', ar: 'تواصل معنا'),
      url: 'mailto:hello@example.com',
      description: AboutText.shared('hello@example.com'),
    ),
  ],

  // ── Credits ────────────────────────────────────────────────────────────
  credits: [
    AboutCredit(
      icon: FLucideIcons.penTool,
      name: AboutText(en: 'Your Name', ar: 'اسمك هنا'),
      role: AboutText(en: 'Design & development', ar: 'التصميم والتطوير'),
      url: 'https://example.com',
    ),
  ],

  // ── Acknowledgements ─────────────────────────────────────────────────────
  acknowledgements: [
    AboutAcknowledgement(
      name: 'Forui',
      description: AboutText(en: 'UI component library', ar: 'مكتبة الواجهات'),
      url: 'https://forui.dev',
    ),
    AboutAcknowledgement(
      name: 'Dorar.net',
      description: AboutText(
        en: 'Hadith database',
        ar: 'قاعدة بيانات الأحاديث',
      ),
      url: 'https://dorar.net',
    ),
    AboutAcknowledgement(
      name: 'Hisn al-Muslim',
      description: AboutText(en: 'Supplications content', ar: 'محتوى الأذكار'),
    ),
  ],

  // ── Legal footer ───────────────────────────────────────────────────────
  legal: AboutText(
    en: '© 2026 Tawaq. All rights reserved.',
    ar: '© ٢٠٢٦ توّاق. جميع الحقوق محفوظة.',
  ),
);
