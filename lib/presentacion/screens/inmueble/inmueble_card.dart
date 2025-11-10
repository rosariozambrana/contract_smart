import 'package:flutter/material.dart';
import '../../../negocio/models/inmueble_model.dart';
import '../components/image_carousel_inmueble.dart';
import '../../../core/constants/crypto_constants.dart';
class InmuebleCard extends StatelessWidget {
  final InmuebleModel inmueble;
  final VoidCallback? onContractRequest;

  const InmuebleCard({
    Key? key,
    required this.inmueble,
    this.onContractRequest,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property image carousel
          ImageCarouselInmueble(
            inmuebleId: inmueble.id,
            galeriaInmueble: inmueble.galeria,
            height: 200,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        inmueble.nombre,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: inmueble.isOcupado ? Colors.red : Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        inmueble.isOcupado ? 'Ocupado' : 'Disponible',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (inmueble.tipoInmueble != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.home_work, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        inmueble.tipoInmueble!.nombre,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  inmueble.detalle ?? "Sin descripción",
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.hotel, size: 16),
                    const SizedBox(width: 4),
                    Text('${inmueble.numHabitacion} hab.'),
                    const SizedBox(width: 16),
                    const Icon(Icons.stairs, size: 16),
                    const SizedBox(width: 4),
                    Text('Piso ${inmueble.numPiso}'),
                  ],
                ),
                if (inmueble.direccion != null && inmueble.direccion!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          inmueble.direccion!,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${inmueble.precio.toStringAsFixed(2)} ETH/mes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '≈ ${CryptoConstants.formatUsdFromEth(inmueble.precio)}/mes',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: inmueble.isOcupado ? null : onContractRequest,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      inmueble.isOcupado ? 'Este inmueble ya está alquilado' : 'Solicitar contrato',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
