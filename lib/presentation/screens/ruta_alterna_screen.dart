import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/models/circuito_alternativo.dart';

class RutaAlternaScreen extends StatefulWidget {
  final CircuitoAlternativo circuito;
  final String origenNombre;

  const RutaAlternaScreen({
    super.key,
    required this.circuito,
    required this.origenNombre,
  });

  @override
  State<RutaAlternaScreen> createState() => _RutaAlternaScreenState();
}

class _RutaAlternaScreenState extends State<RutaAlternaScreen> {
  int _pasosSimulados = 0;
  double _distanciaRecorridaMetros = 0.0;
  bool _enNavegacion = false;
  Timer? _timerSensores;

  void _alternarNavegacion() {
    setState(() {
      _enNavegacion = !_enNavegacion;
    });

    if (_enNavegacion) {
      // Emulación del sensor podómetro (Práctica 08.2)
      _timerSensores = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _pasosSimulados += 2;
          _distanciaRecorridaMetros = _pasosSimulados * 0.75; // 0.75m aprox por paso
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navegación iniciada. Conteo de pasos y GPS activo.')),
      );
    } else {
      _timerSensores?.cancel();
    }
  }

  @override
  void dispose() {
    _timerSensores?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Desvío Peatonal Sugerido'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ruta recomendada para evitar el atasco en ${widget.origenNombre}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.circuito.nombreCircuito,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.circuito.descripcionCultural,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildInfoCard(Icons.directions_walk, '${widget.circuito.distanciaKm} km', 'Distancia'),
                const SizedBox(width: 10),
                _buildInfoCard(Icons.timer_outlined, '${widget.circuito.tiempoEstimadoMin} min', 'Tiempo'),
                const SizedBox(width: 10),
                _buildInfoCard(Icons.traffic, '${widget.circuito.porcentajeCongestion}%', 'Congestión'),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: const Icon(Icons.local_police_outlined, color: Colors.blue, size: 30),
                title: const Text('Seguridad Garantizada', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(widget.circuito.garantiaSeguridad, style: const TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(height: 20),
            // Panel de Sensores (Práctica 08)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Telemetría Peatonal (Sensores en Vivo)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.nordic_walking, color: Colors.indigo),
                          Text('$_pasosSimulados', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const Text('Pasos dados', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      Column(
                        children: [
                          const Icon(Icons.straighten, color: Colors.indigo),
                          Text('${_distanciaRecorridaMetros.toStringAsFixed(1)} m', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const Text('Avanzado', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _enNavegacion ? Colors.red.shade700 : Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                onPressed: _alternarNavegacion,
                icon: Icon(_enNavegacion ? Icons.stop : Icons.navigation),
                label: Text(_enNavegacion ? 'Detener Navegación' : 'Iniciar Navegación Asistida'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String valor, String etiqueta) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.indigo),
            const SizedBox(height: 6),
            Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(etiqueta, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}