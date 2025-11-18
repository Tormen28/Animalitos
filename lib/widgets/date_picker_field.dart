import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'states/date_picker_field_state.dart' show DatePickerFieldState;

/// Un campo de formulario personalizado para seleccionar fechas.
///
/// Este widget muestra un campo de texto de solo lectura que, al tocarlo,
/// abre un selector de fecha. La fecha seleccionada se muestra en formato
/// 'dd/MM/yyyy' y se puede personalizar el rango de fechas permitido.
class DatePickerField extends StatefulWidget {
  /// La etiqueta que se muestra encima del campo.
  final String label;
  
  /// La fecha actualmente seleccionada.
  final DateTime? selectedDate;
  
  /// Función que se llama cuando se selecciona una nueva fecha.
  final Function(DateTime) onDateSelected;
  
  /// La fecha más temprana que se puede seleccionar.
  final DateTime? firstDate;
  
  /// La fecha más tardía que se puede seleccionar.
  final DateTime? lastDate;
  
  /// La fecha que se muestra inicialmente en el selector si no hay una fecha seleccionada.
  final DateTime? initialDate;
  
  /// Si es verdadero, el campo se marca como obligatorio en el formulario.
  final bool isRequired;

  /// Crea un nuevo [DatePickerField].
  ///
  /// Los parámetros [label], [selectedDate] y [onDateSelected] son obligatorios.
  const DatePickerField({
    super.key,
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
    this.firstDate,
    this.lastDate,
    this.initialDate,
    this.isRequired = false,
  });

  @override
  DatePickerFieldState createState() => DatePickerFieldState();

  /// Método estático para abrir manualmente el selector de fecha.
  /// Útil cuando se necesita activar el selector desde fuera del widget.
  static Future<void> selectDate(DatePickerFieldState state) => state._selectDate(state.context);
}

class DatePickerFieldState extends State<DatePickerField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.selectedDate != null
        ? DateFormat('dd/MM/yyyy').format(widget.selectedDate!)
        : '');
  }

  @override
  void didUpdateWidget(covariant DatePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      _controller.text = widget.selectedDate != null
          ? DateFormat('dd/MM/yyyy').format(widget.selectedDate!)
          : '';
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate ?? widget.initialDate ?? DateTime.now(),
      firstDate: widget.firstDate ?? DateTime(2000),
      lastDate: widget.lastDate ?? DateTime(2100),
      locale: const Locale('es', 'ES'),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != widget.selectedDate) {
      widget.onDateSelected(picked);
      _controller.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (widget.isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controller,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Seleccione una fecha',
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today, color: Colors.blue),
              onPressed: () => _selectDate(context),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          onTap: () => _selectDate(context),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
