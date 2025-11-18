class Animalito {
  final int id;
  final String nombre;
  final String numeroStr;
  final String? descripcion;
  final String? imagenUrl;
  final String? imagenSvgUrl;
  final String? imagenAsset;
  final List<String> caracteristicas;
  final DateTime fechaCreacion;
  final bool activo;

  Animalito({
    required this.id,
    required this.nombre,
    required this.numeroStr,
    this.descripcion,
    this.imagenUrl,
    this.imagenSvgUrl,
    this.imagenAsset,
    List<String>? caracteristicas,
    DateTime? fechaCreacion,
    this.activo = true,
  })  : caracteristicas = caracteristicas ?? [],
        fechaCreacion = fechaCreacion ?? DateTime.now();

  // Número entero para ordenamiento y comparación
  int get numero => int.tryParse(numeroStr.padLeft(2, '0')) ?? 0;

  // Nombre para mostrar con el número
  String get nombreCompleto => '${numeroStr.padLeft(2, '0')} - $nombre';

  // URL de la imagen con respaldo
  String get imagenConRespaldo =>
      imagenSvgUrl ??
      imagenUrl ??
      imagenAsset ??
      'https://via.placeholder.com/150/FFD700/000000?text=${nombre[0].toUpperCase()}';

  // Método para obtener la imagen actual (prioriza assets locales)
  String? getImagenActual() {
    if (imagenAsset != null) return imagenAsset;
    if (imagenSvgUrl != null) return imagenSvgUrl;
    if (imagenUrl != null) return imagenUrl;
    return null;
  }

  factory Animalito.fromJson(Map<String, dynamic> json) {
    return Animalito(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      numeroStr: json['numero_str'] as String,
      descripcion: json['descripcion'] as String?,
      imagenUrl: json['imagen_url'] as String?,
      imagenSvgUrl: json['imagen_svg_url'] as String?,
      imagenAsset: json['imagen_asset'] as String?,
      caracteristicas: json['caracteristicas'] != null
          ? List<String>.from(json['caracteristicas'] as List)
          : null,
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'] as String)
          : null,
      activo: json['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'numero_str': numeroStr,
      if (descripcion != null) 'descripcion': descripcion,
      if (imagenUrl != null) 'imagen_url': imagenUrl,
      if (imagenSvgUrl != null) 'imagen_svg_url': imagenSvgUrl,
      if (imagenAsset != null) 'imagen_asset': imagenAsset,
      'caracteristicas': caracteristicas,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'activo': activo,
    };
  }

  // Crea una copia del animalito con algunos campos actualizados
  Animalito copyWith({
    int? id,
    String? nombre,
    String? numeroStr,
    String? descripcion,
    String? imagenUrl,
    String? imagenSvgUrl,
    String? imagenAsset,
    List<String>? caracteristicas,
    bool? activo,
  }) {
    return Animalito(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      numeroStr: numeroStr ?? this.numeroStr,
      descripcion: descripcion ?? this.descripcion,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      imagenSvgUrl: imagenSvgUrl ?? this.imagenSvgUrl,
      imagenAsset: imagenAsset ?? this.imagenAsset,
      caracteristicas: caracteristicas ?? this.caracteristicas,
      fechaCreacion: fechaCreacion,
      activo: activo ?? this.activo,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Animalito &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nombre == other.nombre &&
          numeroStr == other.numeroStr;

  @override
  int get hashCode => id.hashCode ^ nombre.hashCode ^ numeroStr.hashCode;

  @override
  String toString() => 'Animalito(${numeroStr.padLeft(2, '0')}: $nombre)';

  // Lista estática de todos los animalitos del Lotto Activo
  static final List<Animalito> lottoActivoAnimalitos = [
    Animalito(id: 0, nombre: 'Ballena', numeroStr: '00', imagenAsset: 'imgAn/1.png'),
    Animalito(id: 1, nombre: 'Delfín', numeroStr: '0', imagenAsset: 'imgAn/2.png'),
    Animalito(id: 2, nombre: 'Carnero', numeroStr: '1', imagenAsset: 'imgAn/3.png'),
    Animalito(id: 3, nombre: 'Toro', numeroStr: '2', imagenAsset: 'imgAn/4.png'),
    Animalito(id: 4, nombre: 'Ciempiés', numeroStr: '3', imagenAsset: 'imgAn/5.png'),
    Animalito(id: 5, nombre: 'Alacrán', numeroStr: '4', imagenAsset: 'imgAn/6.png'),
    Animalito(id: 6, nombre: 'León', numeroStr: '5', imagenAsset: 'imgAn/7.png'),
    Animalito(id: 7, nombre: 'Rana', numeroStr: '6', imagenAsset: 'imgAn/8.png'),
    Animalito(id: 8, nombre: 'Perico', numeroStr: '7', imagenAsset: 'imgAn/9.png'),
    Animalito(id: 9, nombre: 'Ratón', numeroStr: '8', imagenAsset: 'imgAn/10.png'),
    Animalito(id: 10, nombre: 'Águila', numeroStr: '9', imagenAsset: 'imgAn/11.png'),
    Animalito(id: 11, nombre: 'Tigre', numeroStr: '10', imagenAsset: 'imgAn/12.png'),
    Animalito(id: 12, nombre: 'Gato', numeroStr: '11', imagenAsset: 'imgAn/13.png'),
    Animalito(id: 13, nombre: 'Caballo', numeroStr: '12', imagenAsset: 'imgAn/14.png'),
    Animalito(id: 14, nombre: 'Mono', numeroStr: '13', imagenAsset: 'imgAn/15.png'),
    Animalito(id: 15, nombre: 'Paloma', numeroStr: '14', imagenAsset: 'imgAn/16.png'),
    Animalito(id: 16, nombre: 'Zorro', numeroStr: '15', imagenAsset: 'imgAn/17.png'),
    Animalito(id: 17, nombre: 'Oso', numeroStr: '16', imagenAsset: 'imgAn/18.png'),
    Animalito(id: 18, nombre: 'Pavo', numeroStr: '17', imagenAsset: 'imgAn/19.png'),
    Animalito(id: 19, nombre: 'Burro', numeroStr: '18', imagenAsset: 'imgAn/20.png'),
    Animalito(id: 20, nombre: 'Chivo', numeroStr: '19', imagenAsset: 'imgAn/21.png'),
    Animalito(id: 21, nombre: 'Cerdo', numeroStr: '20', imagenAsset: 'imgAn/22.png'),
    Animalito(id: 22, nombre: 'Gallo', numeroStr: '21', imagenAsset: 'imgAn/23.png'),
    Animalito(id: 23, nombre: 'Camello', numeroStr: '22', imagenAsset: 'imgAn/24.png'),
    Animalito(id: 24, nombre: 'Cebra', numeroStr: '23', imagenAsset: 'imgAn/25.png'),
    Animalito(id: 25, nombre: 'Iguana', numeroStr: '24', imagenAsset: 'imgAn/26.png'),
    Animalito(id: 26, nombre: 'Gallina', numeroStr: '25', imagenAsset: 'imgAn/27.png'),
    Animalito(id: 27, nombre: 'Vaca', numeroStr: '26', imagenAsset: 'imgAn/28.png'),
    Animalito(id: 28, nombre: 'Perro', numeroStr: '27', imagenAsset: 'imgAn/29.png'),
    Animalito(id: 29, nombre: 'Zamuro', numeroStr: '28', imagenAsset: 'imgAn/30.png'),
    Animalito(id: 30, nombre: 'Elefante', numeroStr: '29', imagenAsset: 'imgAn/31.png'),
    Animalito(id: 31, nombre: 'Caimán', numeroStr: '30', imagenAsset: 'imgAn/32.png'),
    Animalito(id: 32, nombre: 'Lapa', numeroStr: '31', imagenAsset: 'imgAn/33.png'),
    Animalito(id: 33, nombre: 'Ardilla', numeroStr: '32', imagenAsset: 'imgAn/34.png'),
    Animalito(id: 34, nombre: 'Pescado', numeroStr: '33', imagenAsset: 'imgAn/35.png'),
    Animalito(id: 35, nombre: 'Venado', numeroStr: '34', imagenAsset: 'imgAn/36.png'),
    Animalito(id: 36, nombre: 'Jirafa', numeroStr: '35', imagenAsset: 'imgAn/37.png'),
    Animalito(id: 37, nombre: 'Culebra', numeroStr: '36', imagenAsset: 'imgAn/38.png'),
  ];

  // Obtener un animalito por su ID
  static Animalito? getById(int id) {
    try {
      return lottoActivoAnimalitos.firstWhere((animal) => animal.id == id);
    } catch (e) {
      return null;
    }
  }

  // Obtener un animalito por su número
  static Animalito? getByNumero(String numero) {
    try {
      // Primero intentar con el número tal cual viene
      var animalito = lottoActivoAnimalitos.firstWhere(
        (animal) => animal.numeroStr == numero,
      );
      return animalito;
    } catch (e) {
      try {
        // Si no encuentra, intentar con padding de ceros
        return lottoActivoAnimalitos.firstWhere(
          (animal) => animal.numeroStr == numero.padLeft(2, '0'),
        );
      } catch (e2) {
        return null;
      }
    }
  }
}
