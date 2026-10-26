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
    final circuito = widget.circuito;
    final perfil = circuito.perfilTopografico;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Desvío Recomendado'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              circuito.nombreCircuito,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              circuito.descripcionCultural,
              style: TextStyle(
                color: Colors.blueGrey.shade600,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),

            // Métricas esenciales
            Row(
              children: [
                _MetricaCard(
                  icon: Icons.straighten,
                  valor: '${circuito.distanciaKm} km',
                  label: 'Distancia',
                ),
                const SizedBox(width: 8),
                _MetricaCard(
                  icon: Icons.timer_outlined,
                  valor: '${circuito.tiempoEstimadoMin} min',
                  label: 'Tiempo',
                ),
                const SizedBox(width: 8),
                _MetricaCard(
                  icon: Icons.groups_outlined,
                  valor: '${circuito.porcentajeCongestion}%',
                  label: 'Afluencia',
                ),
              ],
            ),

            if (perfil != null) ...[
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(Icons.terrain, size: 15, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${perfil.desnivel} · ${perfil.calzada}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 21),
                child: Text(
                  perfil.advertencia,
                  style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade400),
                ),
              ),
            ],

            const SizedBox(height: 18),

            // Garantía de seguridad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined, color: Color(0xFF2E7D32), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      circuito.garantiaSeguridad,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1B5E20),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (circuito.checkpoints.isNotEmpty) ...[
              const SizedBox(height: 18),
              _ItinerarioDesplegable(checkpoints: circuito.checkpoints),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _enNavegacion ? const Color(0xFFC62828) : Colors.indigo,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _alternarNavegacion,
            icon: Icon(
              _enNavegacion ? Icons.stop_circle_outlined : Icons.navigation_outlined,
              size: 18,
            ),
            label: Text(
              _enNavegacion ? 'Finalizar Navegación' : 'Iniciar Navegación',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricaCard extends StatelessWidget {
  final IconData icon;
  final String valor;
  final String label;

  const _MetricaCard({
    required this.icon,
    required this.valor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.indigo, size: 19),
            const SizedBox(height: 6),
            Text(
              valor,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItinerarioDesplegable extends StatelessWidget {
  final List<CheckpointPeatonal> checkpoints;

  const _ItinerarioDesplegable({required this.checkpoints});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          iconColor: Colors.indigo,
          collapsedIconColor: const Color(0xFF64748B),
          title: Row(
            children: [
              const Icon(Icons.alt_route, size: 16, color: Colors.indigo),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Itinerario · ${checkpoints.length} paradas',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          children: [
            for (var i = 0; i < checkpoints.length; i++)
              _buildParada(
                numero: checkpoints[i].numero,
                nombre: checkpoints[i].nombre,
                detalle: checkpoints[i].detalle,
                esUltimo: i == checkpoints.length - 1,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildParada({
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
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: esUltimo ? const Color(0xFF2E7D32) : Colors.indigo,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                numero,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (!esUltimo)
              Container(width: 2, height: 30, color: Colors.indigo.shade100),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: esUltimo ? 0 : 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 1),
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
