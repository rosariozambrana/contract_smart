/// Constantes para operaciones con criptomonedas
/// Sistema base: ETH (Ethereum)
class CryptoConstants {
  // Tasa de conversión fija ETH a USD (solo para display)
  static const double ETH_TO_USD = 2000.0;

  /// Convierte ETH a USD (solo para visualización)
  static double ethToUsd(double eth) {
    return eth * ETH_TO_USD;
  }

  /// Formatea valor ETH como USD string
  /// Ejemplo: 2.5 ETH → "$5,000.00"
  static String formatUsdFromEth(double eth) {
    final usd = ethToUsd(eth);
    return '\$${usd.toStringAsFixed(2)}';
  }

  /// Formatea para mostrar "X ETH ≈ $Y"
  /// Ejemplo: 2.5 ETH → "2.50 ETH ≈ $5,000.00"
  static String formatEthWithUsd(double eth) {
    return '${eth.toStringAsFixed(2)} ETH ≈ ${formatUsdFromEth(eth)}';
  }

  /// Formatea solo el valor ETH con símbolo
  /// Ejemplo: 2.5 → "2.50 ETH"
  static String formatEth(double eth) {
    return '${eth.toStringAsFixed(2)} ETH';
  }

  /// Formatea ETH con más decimales para precisión
  /// Ejemplo: 0.003 → "0.003000 ETH"
  static String formatEthPrecise(double eth, {int decimals = 6}) {
    return '${eth.toStringAsFixed(decimals)} ETH';
  }
}
