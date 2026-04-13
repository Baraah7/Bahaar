/// Converts ASCII digits to Arabic-Indic numerals when [locale] is 'ar'.
String arabicN(String value, String locale) {
  if (locale != 'ar') return value;
  const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return value.replaceAllMapped(
    RegExp(r'[0-9]'),
    (m) => digits[int.parse(m.group(0)!)],
  );
}
