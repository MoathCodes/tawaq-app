part of '../flutter_quran_screen.dart';

class AyahLongClickDialog extends StatelessWidget {
  final Ayah ayah;

  const AyahLongClickDialog(this.ayah, {super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: OutlinedContainer(
        // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        // elevation: 3,
        backgroundColor: const Color(0xFFF7EFE0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'أضف علامة',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(
                            text: AppBloc
                                .quranCubit.staticPages[ayah.page - 1].ayahs
                                .firstWhere((element) => element.id == ayah.id)
                                .ayah))
                        .then((value) =>
                            ToastUtils().showToast("تم النسخ الى الحافظة"));
                    Navigator.of(context).pop();
                  },
                  child: const Alert(
                      title: Text("نسخ الى الحافظة"),
                      leading: Icon(
                        Icons.copy_rounded,
                        color: Color(0xFF798FAB),
                      )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
