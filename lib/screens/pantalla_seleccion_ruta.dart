import 'package:flutter/material.dart';

import '../controllers/controlador_lectura.dart';
import '../models/usuario_sesion.dart';
import '../services/device/servicio_ubicacion.dart';
import '../services/local/servicio_lectura_local.dart';
import '../services/local/servicio_usuario_local.dart';
import '../services/servicio_lectura.dart';
import 'pantalla_lectura.dart';

class PantallaSeleccionRuta extends StatefulWidget {
  final UsuarioSesion usuarioSesion;

  const PantallaSeleccionRuta({
    super.key,
    required this.usuarioSesion,
  });

  @override
  State<PantallaSeleccionRuta> createState() => _PantallaSeleccionRutaState();
}

class _PantallaSeleccionRutaState extends State<PantallaSeleccionRuta> {
  late final ControladorLectura controlador;
  final ServicioLectura servicioLectura = ServicioLectura();
  final ServicioLecturaLocal servicioLecturaLocal = ServicioLecturaLocal();
  final ServicioUsuarioLocal servicioUsuarioLocal = ServicioUsuarioLocal();

  bool cargando = false;
  bool cargandoRutas = true;
  bool tieneEntornoLocal = false;
  String mensaje = '';

  List<int> rutas = [];
  List<int> rutasSeleccionadas = [];

  @override
  void initState() {
    super.initState();

    controlador = ControladorLectura(
      servicioRemoto: servicioLectura,
      servicioLocal: servicioLecturaLocal,
      servicioUbicacion: ServicioUbicacion(),
    );

    cargarEstadoInicial();
  }

  Future<void> cargarEstadoInicial() async {
    final rutasGuardadas = await servicioUsuarioLocal.obtenerRutasActivas(
      widget.usuarioSesion.username,
    );

    final hayCuentasLocales = await servicioLecturaLocal.hayCuentasLocales();
    final coincidenLocal = rutasGuardadas.isNotEmpty
        ? await servicioLecturaLocal.coincidenRutasLocales(rutasGuardadas)
        : false;

    if (!mounted) return;

    setState(() {
      rutasSeleccionadas = [...rutasGuardadas]..sort();
      tieneEntornoLocal = hayCuentasLocales && coincidenLocal && rutasGuardadas.isNotEmpty;
    });

    await cargarRutas();
  }

  Future<void> cargarRutas() async {
    setState(() {
      cargandoRutas = true;
      mensaje = '';
    });

    try {
      final lista = await servicioLectura.listarRutas();

      if (!mounted) return;

      setState(() {
        rutas = lista..sort();
        cargandoRutas = false;

        if (tieneEntornoLocal && rutasSeleccionadas.isNotEmpty) {
          mensaje =
          'Se restauraron tus rutas activas guardadas. Puedes continuar aunque no vuelvas a descargarlas.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        cargandoRutas = false;

        if (tieneEntornoLocal && rutasSeleccionadas.isNotEmpty) {
          mensaje =
          'No se pudieron consultar rutas en línea, pero puedes continuar con tus rutas activas guardadas.';
        } else {
          mensaje = 'Error al cargar rutas: $e';
        }
      });
    }
  }

  Future<void> abrirSelectorRutas() async {
    final seleccionTemporal = <int>{};

    final resultado = await showDialog<List<int>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Selecciona una o varias rutas'),
              content: SizedBox(
                width: double.maxFinite,
                child: rutas.isEmpty
                    ? const Text('No hay rutas disponibles')
                    : ListView(
                  shrinkWrap: true,
                  children: rutas.map((ruta) {
                    return CheckboxListTile(
                      value: seleccionTemporal.contains(ruta),
                      title: Text(ruta.toString()),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (value) {
                        setStateDialog(() {
                          if (value == true) {
                            seleccionTemporal.add(ruta);
                          } else {
                            seleccionTemporal.remove(ruta);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final lista = seleccionTemporal.toList()..sort();
                    Navigator.of(context).pop(lista);
                  },
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (resultado != null && mounted) {
      setState(() {
        rutasSeleccionadas = resultado;
        tieneEntornoLocal = false;
      });
    }
  }

  Future<void> continuar() async {
    if (rutasSeleccionadas.isEmpty) {
      setState(() {
        mensaje = 'Selecciona al menos una ruta';
      });
      return;
    }

    setState(() {
      cargando = true;
      mensaje = '';
    });

    try {
      if (tieneEntornoLocal) {
        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PantallaLectura(
              usuarioSesion: widget.usuarioSesion,
            ),
          ),
        );
        return;
      }

      final resultado = await controlador.cargarRutas(rutasSeleccionadas);

      if (!mounted) return;

      if (resultado.ok) {
        await servicioUsuarioLocal.guardarRutasActivas(
          username: widget.usuarioSesion.username,
          rutas: rutasSeleccionadas,
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PantallaLectura(
              usuarioSesion: widget.usuarioSesion,
            ),
          ),
        );
        return;
      }

      setState(() {
        mensaje = resultado.mensaje;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final puedeCambiarSeleccion = !tieneEntornoLocal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar rutas'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.route, size: 64),
                    const SizedBox(height: 10),
                    Text(
                      'Hola, ${widget.usuarioSesion.nombre}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tieneEntornoLocal
                          ? 'Tienes rutas activas restauradas para seguir trabajando'
                          : 'Selecciona una o varias rutas para trabajar',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    if (cargandoRutas)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: CircularProgressIndicator(),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton.icon(
                            onPressed: (cargando || !puedeCambiarSeleccion)
                                ? null
                                : abrirSelectorRutas,
                            icon: const Icon(Icons.playlist_add_check),
                            label: Text(
                              tieneEntornoLocal
                                  ? 'Rutas restauradas'
                                  : rutasSeleccionadas.isEmpty
                                  ? 'Seleccionar rutas'
                                  : 'Cambiar selección',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: rutasSeleccionadas.isEmpty
                                ? const Text('No has seleccionado rutas')
                                : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: rutasSeleccionadas
                                  .map(
                                    (ruta) => Chip(
                                  label: Text(ruta.toString()),
                                ),
                              )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    if (mensaje.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(mensaje),
                      ),
                    if (mensaje.isNotEmpty) const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: cargando ? null : continuar,
                        icon: const Icon(Icons.arrow_forward),
                        label: Text(
                          cargando ? 'Procesando...' : 'Continuar',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}