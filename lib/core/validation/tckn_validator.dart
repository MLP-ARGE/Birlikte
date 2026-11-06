/// TC Kimlik No sağlama algoritması.
///
/// Sunucu zaten doğruluyor; bu yalnızca anında kullanıcı geri bildirimi
/// için — yanlış girilen bir numarayı SMS beklemeden yakalar. Algoritma
/// `private.is_valid_tckn` (Postgres) ile birebir aynı, tek doğru kaynak
/// orası.
abstract final class TcknValidator {
  static bool isValid(String raw) {
    if (!RegExp(r'^[1-9][0-9]{10}$').hasMatch(raw)) return false;

    final d = raw.split('').map(int.parse).toList();

    var oddSum = 0;
    for (var i = 0; i < 9; i += 2) {
      oddSum += d[i];
    }
    var evenSum = 0;
    for (var i = 1; i < 8; i += 2) {
      evenSum += d[i];
    }

    if ((oddSum * 7 - evenSum) % 10 != d[9]) return false;

    final total = d.take(10).fold<int>(0, (a, b) => a + b);
    return total % 10 == d[10];
  }
}
