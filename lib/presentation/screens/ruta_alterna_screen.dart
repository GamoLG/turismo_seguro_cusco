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
  bool _enNavegacion = false;

  void _alternarNavegacion() {
    setState(() {
      _enNavegacion = !_enNavegacion;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _enNavegacion
              ? 'Navegación asistida activa. Monitoreo por cuadrantes POLTUR iniciado.'
              : 'Navegación pausada.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Ficha Técnica de Desvío'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. BANNER DE MITIGACIÓN Y IMPACTO PATRIMONIAL
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Color(0xFF2E7D32), size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mitigación de Carga Lítica Activa',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        Text(
                          'Desvía el flujo peatonal de ${widget.origenNombre} (-38% presión estimada).',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF2E7D32)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. ENCABEZADO DEL CIRCUITO
            Text(
              widget.circuito.nombreCircuito,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.circuito.descripcionCultural,
              style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 13, height: 1.3),
            ),
            const SizedBox(height: 14),

            // 3. TARJETAS DE MÉTRICAS TÉCNICAS (Perfil de Tránsito)
            Row(
              children: [
                _buildMetricaCard(Icons.straighten, '${widget.circuito.distanciaKm} km', 'Distancia', 'Callejero real'),
                const SizedBox(width: 8),
                _buildMetricaCard(Icons.timer_outlined, '${widget.circuito.tiempoEstimadoMin} min', 'Tiempo Estim.', 'Vel: 0.8 m/s'),
                const SizedBox(width: 8),
                _buildMetricaCard(Icons.speed, 'Nivel A', 'Flujo Peatonal', '${widget.circuito.porcentajeCongestion}% densidad'),
              ],
            ),
            const SizedBox(height: 14),

            // 4. CONDICIÓN TOPOGRÁFICA Y ACCESIBILIDAD (Específico de Cusco)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.terrain, size: 16, color: Colors.indigo),
                      SizedBox(width: 6),
                      Text(
                        'Perfil Topográfico y Accesibilidad Lítica',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTopografiaItem('Desnivel:', '+38 m (Pendiente 6.2%)'),
                      _buildTopografiaItem('Calzada:', 'Empedrado y gradas'),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: Colors.amber.shade800),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Contiene escalinatas coloniales. Tránsito sugerido a ritmo moderado.',
                          style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 5. ITINERARIO Y CHECKPOINTS PEATONALES (En lugar del podómetro)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.alt_route, size: 16, color: Colors.indigo),
                      SizedBox(width: 6),
                      Text(
                        'Checkpoints del Corredor Peatonal',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildHitoPaso(
                    numero: '1',
                    nombre: 'Desvío Inicial por Calle Choquechaka',
                    detalle: 'Vía lateral ancha con calzada regular (0 - 300 m)',
                    esUltimo: false,
                  ),
                  _buildHitoPaso(
                    numero: '2',
                    nombre: 'Paso por Acueducto Sapantiana',
                    detalle: 'Monumento colonial de desfogue cultural (300 - 750 m)',
                    esUltimo: false,
                  ),
                  _buildHitoPaso(
                    numero: '3',
                    nombre: 'Callejón Siete Borreguitos y Saphy',
                    detalle: 'Corredor empinado hacia miradores (750 - 1050 m)',
                    esUltimo: false,
                  ),
                  _buildHitoPaso(
                    numero: '4',
                    nombre: 'Llegada: Plazoleta San Cristóbal',
                    detalle: 'Zona de aforo libre y descanso panorámico (1.2 km)',
                    esUltimo: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 6. MATRIZ DE SEGURIDAD OPERATIVA (POLTUR / CÁMARAS)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_police, color: Colors.indigo, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cuadrante de Seguridad Activo',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B)),
                        ),
                        Text(
                          '${widget.circuito.garantiaSeguridad}. Cámaras de monitoreo ciudadanas en tramos críticos.',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 7. BOTÓN PRINCIPAL DE NAVEGACIÓN
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _enNavegacion ? const Color(0xFFC62828) : Colors.indigo,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _alternarNavegacion,
                icon: Icon(_enNavegacion ? Icons.stop_circle_outlined : Icons.navigation_outlined, size: 18),
                label: Text(
                  _enNavegacion ? 'Finalizar Navegación Asistida' : 'Iniciar Navegación del Desvío',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricaCard(IconData icon, String valor, String titulo, String subtitulo) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.indigo, size: 20),
            const SizedBox(height: 4),
            Text(
              valor,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
            ),
            Text(
              titulo,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
            Text(
              subtitulo,
              style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopografiaItem(String label, String valor) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
        ),
        const SizedBox(width: 4),
        Text(
          valor,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
      ],
    );
  }

  Widget _buildHitoPaso({
    required String numero,
    required String nombre,
    required String detalle,
    required bool esUltimo,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: esUltimo ? const Color(0xFF2E7D32) : Colors.indigo,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                numero,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            if (!esUltimo)
              Container(
                width: 2,
                height: 28,
                color: Colors.indigo.shade100,
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: esUltimo ? 0 : 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                Text(
                  detalle,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}