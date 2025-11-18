import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:animalitos_lottery/models/animalito.dart';
import 'package:animalitos_lottery/models/sorteo.dart';
import 'package:animalitos_lottery/providers/loteria_provider.dart';
import 'package:animalitos_lottery/providers/auth_provider.dart';
import 'package:animalitos_lottery/theme/app_theme.dart';
import 'package:animalitos_lottery/widgets/animalito_card.dart';
import 'package:animalitos_lottery/widgets/custom_button.dart';

class ApuestaScreen extends ConsumerStatefulWidget {
  final Sorteo sorteo;

  const ApuestaScreen({
    super.key,
    required this.sorteo,
  });

  @override
  _ApuestaScreenState createState() => _ApuestaScreenState();
}

class _ApuestaScreenState extends ConsumerState<ApuestaScreen> {
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, FocusNode> _focusNodes = {};
  final _formKey = GlobalKey<FormState>();
  List<Animalito> _animalitos = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  double _saldoDisponible = 0.0;
  double _montoTotal = 0.0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // No llamamos _cargarDatos() aquí porque ref no está disponible aún
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Aquí es seguro usar ref porque el contexto está completamente inicializado
    if (!_isInitialized) {
      _cargarDatos();
      _isInitialized = true;
    }
  }


  @override
  void dispose() {
    // Limpiar controladores y focus nodes
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    try {
      debugPrint('🔄 Cargando datos para sorteo ${widget.sorteo.id} - Estado: ${widget.sorteo.activo}');

      // Cargar animalitos usando Riverpod - esperamos a que se carguen
      final animalitosAsync = ref.watch(animalitosProvider);
      if (animalitosAsync.isLoading) {
        debugPrint('⏳ Esperando carga de animalitos...');
        // Si aún está cargando, esperamos un poco y reintentamos
        await Future.delayed(const Duration(milliseconds: 100));
        return _cargarDatos(); // Recursión para esperar
      }

      if (animalitosAsync.hasValue) {
        _animalitos = animalitosAsync.value!;
        debugPrint('🐾 Animalitos cargados: ${_animalitos.length}');

        // Inicializar controladores y focus nodes
        for (var animalito in _animalitos) {
          _controllers[animalito.id] = TextEditingController(text: '');
          _focusNodes[animalito.id] = FocusNode();
          _controllers[animalito.id]!.addListener(_calcularTotal);
        }
      } else if (animalitosAsync.hasError) {
        debugPrint('❌ Error cargando animalitos: ${animalitosAsync.error}');
        throw Exception('Error al cargar animalitos: ${animalitosAsync.error}');
      }

      // Cargar saldo del usuario directamente desde Supabase
      final currentUser = ref.watch(currentUserProvider);
      if (currentUser != null) {
        try {
          debugPrint('👤 Usuario autenticado: ${currentUser.id}');

          // Consulta directa a Supabase para obtener el saldo
          final response = await Supabase.instance.client
              .from('perfiles')
              .select('saldo')
              .eq('id', currentUser.id)
              .single();

          final saldo = (response['saldo'] as num?)?.toDouble() ?? 0.0;
          debugPrint('💰 Saldo cargado desde Supabase: $saldo');

          if (mounted) {
            setState(() {
              _saldoDisponible = saldo;
            });
          }
        } catch (e) {
          debugPrint('❌ Error al cargar saldo: $e');
          if (mounted) {
            setState(() {
              _saldoDisponible = 0.0;
            });
          }
        }
      } else {
        debugPrint('❌ No hay usuario autenticado');
        if (mounted) {
          setState(() {
            _saldoDisponible = 0.0;
          });
        }
      }

      // Forzar actualización del saldo después de cargar datos iniciales
      // Esto asegura que el saldo se refresque correctamente
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted && currentUser != null) {
          try {
            final response = await Supabase.instance.client
                .from('perfiles')
                .select('saldo')
                .eq('id', currentUser.id)
                .single();

            final saldoActualizado = (response['saldo'] as num?)?.toDouble() ?? 0.0;
            debugPrint('🔄 Saldo actualizado después de carga inicial: $saldoActualizado');

            if (mounted) {
              setState(() {
                _saldoDisponible = saldoActualizado;
              });
            }
          } catch (e) {
            debugPrint('❌ Error al actualizar saldo después de carga inicial: $e');
          }
        }
      });

      // Cargar apuestas existentes si las hay
      final loteriaServiceInstance = ref.read(loteriaServiceProvider);
      final apuestas = await loteriaServiceInstance.getApuestasUsuario(widget.sorteo.id);
      debugPrint('🎯 Apuestas existentes para sorteo ${widget.sorteo.id}: ${apuestas.length} apuestas');
      for (var entry in apuestas.entries) {
        if (_controllers.containsKey(entry.key)) {
          _controllers[entry.key]!.text = entry.value.toStringAsFixed(2);
        }
      }

      _calcularTotal();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error al cargar datos: $e');
      setState(() {
        _errorMessage = 'Error al cargar los datos: $e';
        _isLoading = false;
      });
    }
  }

  void _calcularTotal() {
    double total = 0;
    for (var entry in _controllers.entries) {
      final monto = double.tryParse(entry.value.text) ?? 0;
      if (monto > 0) {
        total += monto;
      }
    }
    setState(() {
      _montoTotal = total;
    });
  }

  void _limpiarApuestas() {
    for (var controller in _controllers.values) {
      controller.text = '';
    }
    setState(() {
      _montoTotal = 0;
      _errorMessage = null;
    });
  }

  bool _validarApuestas() {
    if (_montoTotal <= 0) {
      setState(() {
        _errorMessage = 'Debes apostar al menos un monto positivo';
      });
      return false;
    }

    if (_montoTotal > _saldoDisponible) {
      setState(() {
        _errorMessage = 'Saldo insuficiente para realizar la apuesta';
      });
      return false;
    }

    // Contar cuántos animales tienen apuesta
    final apuestasRealizadas = _controllers.values
        .where((controller) => (double.tryParse(controller.text) ?? 0) > 0)
        .length;

    if (apuestasRealizadas == 0) {
      setState(() {
        _errorMessage = 'Debes seleccionar al menos un animalito';
      });
      return false;
    }

    return true;
  }

  Future<void> _realizarApuesta() async {
    if (!_validarApuestas()) return;

    debugPrint('🎯 Iniciando proceso de apuesta');
    debugPrint('💰 Monto total: $_montoTotal');
    debugPrint('💰 Saldo disponible: $_saldoDisponible');

    // Confirmar la apuesta
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Apuesta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de realizar esta apuesta por un total de ${_montoTotal.toStringAsFixed(2)} Bs?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text('Resumen de apuestas:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._controllers.entries
                .where((entry) => (double.tryParse(entry.value.text) ?? 0) > 0)
                .map((entry) {
              final animalito = _animalitos.firstWhere((a) => a.id == entry.key);
              final monto = double.tryParse(entry.value.text) ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${animalito.nombre}:'),
                    Text(
                      '${monto.toStringAsFixed(2)} Bs',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            Text(
              'Saldo disponible: ${_saldoDisponible.toStringAsFixed(2)} Bs',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Saldo después de la apuesta: ${(_saldoDisponible - _montoTotal).toStringAsFixed(2)} Bs',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      debugPrint('❌ Usuario canceló la apuesta');
      return;
    }

    try {
      debugPrint('✅ Usuario confirmó la apuesta');
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });

      // Usar Riverpod providers

      // Obtener el ID del usuario autenticado usando Riverpod
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      final usuarioId = currentUser.id;
      debugPrint('👤 Usuario autenticado: $usuarioId');

      // Crear mapa de apuestas solo con los montos mayores a cero
      final apuestas = <int, double>{};
      for (var entry in _controllers.entries) {
        final monto = double.tryParse(entry.value.text) ?? 0;
        if (monto > 0) {
          apuestas[entry.key] = monto;
        }
      }

      debugPrint('🎲 Apuestas preparadas: $apuestas');

      // Realizar la apuesta múltiple usando Riverpod
      final apuestaNotifier = ref.read(apuestaNotifierProvider.notifier);
      await apuestaNotifier.realizarApuestaMultiple(
        sorteoId: widget.sorteo.id,
        apuestas: apuestas,
      );

      debugPrint('🎉 Apuesta realizada exitosamente');

      // Forzar actualización del provider de saldo para obtener el saldo real de la BD
      ref.invalidate(userSaldoProvider);

      // Esperar un momento para que se actualice el provider
      await Future.delayed(const Duration(milliseconds: 500));

      // Obtener el saldo actualizado del provider
      final userSaldoAsync = ref.read(userSaldoProvider);
      userSaldoAsync.when(
        data: (saldoActualizado) {
          debugPrint('💰 Saldo actualizado desde BD: $saldoActualizado');
          setState(() {
            _saldoDisponible = saldoActualizado;
          });
        },
        loading: () {
          debugPrint('⏳ Esperando actualización de saldo...');
        },
        error: (error, stack) {
          debugPrint('❌ Error al obtener saldo actualizado: $error');
          // Mantener el saldo calculado localmente como fallback
          final nuevoSaldo = _saldoDisponible - _montoTotal;
          setState(() {
            _saldoDisponible = nuevoSaldo;
          });
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apuesta realizada con éxito por ${_montoTotal.toStringAsFixed(2)} Bs'),
            backgroundColor: Colors.green,
          ),
        );

        // Retornar éxito
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('❌ Error al realizar la apuesta: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al realizar la apuesta: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Método para construir el campo de entrada de monto
  Widget _buildMontoInput(Animalito animalito) {
    return SizedBox(
      width: 100,
      child: TextFormField(
        controller: _controllers[animalito.id],
        focusNode: _focusNodes[animalito.id],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: '0.00',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          suffixText: 'Bs',
          suffixStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onChanged: (value) {
          _calcularTotal();
          setState(() {
            _errorMessage = null;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) return null;
          final monto = double.tryParse(value) ?? 0;
          if (monto < 0) return 'Monto inválido';
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios en el provider de saldo
    ref.listen(userSaldoProvider, (previous, next) {
      next.when(
        data: (saldo) {
          if (mounted && saldo != _saldoDisponible) {
            debugPrint('🔄 Saldo actualizado desde provider: $saldo');
            setState(() {
              _saldoDisponible = saldo;
            });
          }
        },
        error: (error, stack) {
          debugPrint('❌ Error en provider de saldo: $error');
        },
        loading: () {
          // Mantener el saldo actual mientras carga
        },
      );
    });

    // Observar el estado de carga de animalitos
    final animalitosAsync = ref.watch(animalitosProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Apuestas Múltiples - ${widget.sorteo.nombreConHora}',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: animalitosAsync.isLoading || _isLoading
          ? const Center(child: CircularProgressIndicator())
          : animalitosAsync.hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error al cargar animalitos: ${animalitosAsync.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _cargarDatos,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : Form(
              key: _formKey,
              child: Column(
                children: [
                  // Encabezado con saldo actual - Siempre mostrar el saldo actualizado
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Saldo Actual: ',
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${_saldoDisponible.toStringAsFixed(2)} Bs',
                          style: GoogleFonts.roboto(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Mensaje de error si existe
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Grid de animalitos con campos de apuesta (responsive)
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Calcular el número de columnas basado en el ancho disponible
                        final availableWidth = constraints.maxWidth - 32; // Restar padding
                        final minCardWidth = 180.0; // Ancho mínimo de cada card (más grande)
                        final crossAxisCount = (availableWidth / minCardWidth).floor().clamp(2, 5);

                        // Calcular el ancho real de cada card
                        final cardWidth = (availableWidth - (crossAxisCount - 1) * 16) / crossAxisCount;

                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            alignment: WrapAlignment.center,
                            children: List.generate(_animalitos.length, (index) {
                              final animalito = _animalitos[index];
                              return SizedBox(
                                width: cardWidth,
                                child: Card(
                                  elevation: 6,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // Imagen del animalito (225x225 píxeles para consistencia)
                                        Container(
                                          width: 225, // Tamaño fijo de 225 píxeles
                                          height: 225, // Tamaño fijo de 225 píxeles
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                              width: 3,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.15),
                                                blurRadius: 10,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(9),
                                            child: Image.asset(
                                              animalito.imagenAsset ?? 'imgAn/${animalito.id + 1}.png',
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                debugPrint('Error loading image for ${animalito.nombre}: $error');
                                                return Container(
                                                  color: Colors.grey[100],
                                                  child: Center(
                                                    child: Text(
                                                      animalito.nombre[0].toUpperCase(),
                                                      style: TextStyle(
                                                        fontSize: 72, // Tamaño fijo para fallback
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        // Nombre del animalito
                                        Text(
                                          animalito.nombre,
                                          style: GoogleFonts.roboto(
                                            fontSize: cardWidth * 0.08, // Tamaño relativo
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 12),
                                        // Campo de monto (más grande y responsive)
                                        SizedBox(
                                          width: cardWidth * 0.9, // 90% del ancho del card
                                          height: 48,
                                          child: TextFormField(
                                            controller: _controllers[animalito.id],
                                            focusNode: _focusNodes[animalito.id],
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.roboto(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                             decoration: InputDecoration(
                                                hintText: '0.00',
                                                hintStyle: const TextStyle(color: Colors.black54),
                                                filled: true,
                                                fillColor: Colors.white,
                                               border: OutlineInputBorder(
                                                 borderRadius: BorderRadius.circular(8),
                                                 borderSide: BorderSide(
                                                   color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                                   width: 2,
                                                 ),
                                               ),
                                               enabledBorder: OutlineInputBorder(
                                                 borderRadius: BorderRadius.circular(8),
                                                 borderSide: BorderSide(
                                                   color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                                   width: 1,
                                                 ),
                                               ),
                                               focusedBorder: OutlineInputBorder(
                                                 borderRadius: BorderRadius.circular(8),
                                                 borderSide: BorderSide(
                                                   color: Theme.of(context).colorScheme.primary,
                                                   width: 2,
                                                 ),
                                               ),
                                               contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                               suffixText: 'Bs',
                                               suffixStyle: const TextStyle(
                                                 fontWeight: FontWeight.bold,
                                                 fontSize: 16,
                                                 color: Colors.black,
                                               ),
                                             ),
                                            onChanged: (value) {
                                              _calcularTotal();
                                              setState(() {
                                                _errorMessage = null;
                                              });
                                            },
                                            validator: (value) {
                                              if (value == null || value.isEmpty) return null;
                                              final monto = double.tryParse(value) ?? 0;
                                              if (monto < 0) return 'Inválido';
                                              return null;
                                            },
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        );
                      },
                    ),
                  ),

                  // Información del total y botones de acción
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Total a apostar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Total a apostar: ',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '${_montoTotal.toStringAsFixed(2)} Bs',
                              style: GoogleFonts.roboto(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _montoTotal > _saldoDisponible
                                    ? Colors.red
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Botones de acción
                        Row(
                          children: [
                            // Botón para limpiar
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isSubmitting ? null : _limpiarApuestas,
                                icon: const Icon(Icons.clear_all, size: 20),
                                label: const Text('Limpiar'),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.grey[200],
                                  foregroundColor: Colors.black87,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Botón para apostar
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isSubmitting ? null : _realizarApuesta,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: _isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.attach_money, size: 20),
                                label: Text(
                                  _isSubmitting ? 'Procesando...' : 'Apostar',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Método dispose ya está definido arriba
}