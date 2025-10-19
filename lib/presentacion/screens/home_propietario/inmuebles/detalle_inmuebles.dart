import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:rentals/negocio/models/servicio_basico_model.dart';
import '../../../../datos/ApiService.dart';
import '../../../../negocio/models/inmueble_model.dart';
import '../../../../negocio/models/galeria_inmueble_model.dart';
import '../../../providers/inmueble_provider.dart';
import '../../components/Loading.dart';
import 'my_inmuebles_screen.dart';

class DetalleInmueblesScreen extends StatefulWidget {
  final bool isEditing;
  final InmuebleModel? inmueble;

  const DetalleInmueblesScreen({
    Key? key,
    required this.isEditing,
    this.inmueble,
  }) : super(key: key);

  @override
  State<DetalleInmueblesScreen> createState() => _DetalleInmueblesScreenState();
}

class _DetalleInmueblesScreenState extends State<DetalleInmueblesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _detalleController = TextEditingController();
  final _numHabitacionController = TextEditingController();
  final _numPisoController = TextEditingController();
  final _precioController = TextEditingController();
  bool _isOcupado = false;
  int _tipoInmuebleId = 1; // Default value
  List<ServicioBasicoModel> _selectedServices = [];
  List<XFile> _selectedImages = [];
  List<GaleriaInmuebleModel> _existingImages = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _existingImages.clear();
    if (widget.isEditing && widget.inmueble != null) {
      _nombreController.text = widget.inmueble!.nombre;
      _detalleController.text = widget.inmueble!.detalle ?? '';
      _numHabitacionController.text = widget.inmueble!.numHabitacion;
      _numPisoController.text = widget.inmueble!.numPiso;
      _precioController.text = widget.inmueble!.precio.toString();
      _isOcupado = widget.inmueble!.isOcupado;
      _tipoInmuebleId = widget.inmueble!.tipoInmuebleId;

      // Inicializar los servicios seleccionados si existen
      if (widget.inmueble!.servicios_basicos != null) {
        _selectedServices = widget.inmueble!.servicios_basicos!
            .map((servicio) => ServicioBasicoModel(
              id: servicio.id,
              nombre: servicio.nombre,
              descripcion: servicio.descripcion,
            ))
            .toList();
      }

      // Cargar imágenes existentes después de construir el árbol de widgets
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingImages();
        _loadGaleriaInmueble();
      });
    }
    // Initialize provider and load property types and basic services
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('🚀 INICIANDO DetalleInmueblesScreen');
      print('   - isEditing: ${widget.isEditing}');

      final provider = context.read<InmuebleProvider>();
      print('   - Provider isInitialized: ${provider.isInitialized}');
      print('   - CurrentUser antes: ${provider.currentUser != null ? "EXISTE (ID: ${provider.currentUser!.id})" : "NULL"}');

      // Inicializar provider si no está inicializado (carga el usuario actual)
      if (!provider.isInitialized) {
        print('⏳ Inicializando provider...');
        await provider.initialize();
        print('✅ Provider inicializado. CurrentUser: ${provider.currentUser != null ? "EXISTE (ID: ${provider.currentUser!.id})" : "NULL"}');
      } else {
        print('✅ Provider ya estaba inicializado');
      }

      // Luego cargar tipos y servicios
      await _loadTipoInmuebles();
      await _loadServiciosBasicos();
    });
  }

  Future<void> _loadTipoInmuebles() async {
    await context.read<InmuebleProvider>().loadTipoInmueble();
    // Si no estamos editando y se cargaron tipos de inmueble, usar el primero
    if (!widget.isEditing && mounted) {
      final tipoInmuebles = context.read<InmuebleProvider>().tipoInmuebles;
      if (tipoInmuebles.isNotEmpty) {
        setState(() {
          _tipoInmuebleId = tipoInmuebles.first.id;
        });
      }
    }
  }

  Future<void> _loadServiciosBasicos() async {
    await context.read<InmuebleProvider>().loadServiciosBasicos();
  }

  Future<void> _loadExistingImages() async {
    if (widget.inmueble != null) {
      await context.read<InmuebleProvider>().loadInmuebleGaleria(
        widget.inmueble!.id,
      );
    }
  }

  Future<void> _loadGaleriaInmueble() async {
    if(mounted){
      if(widget.inmueble == null) return;
      await context.read<InmuebleProvider>().loadInmuebleGaleria(widget.inmueble!.id);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _detalleController.dispose();
    _numHabitacionController.dispose();
    _numPisoController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  Future<void> _takePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      setState(() {
        _selectedImages.add(photo);
      });
    }
  }

  Future<File?> _compressImage(XFile image) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(
        tempDir.path,
        '${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        image.path,
        targetPath,
        quality: 70,
        minWidth: 1024,
        minHeight: 1024,
      );

      return compressedFile != null ? File(compressedFile.path) : null;
    } catch (e) {
      debugPrint('Error al comprimir la imagen: $e');
      return null;
    }
  }

  Future<void> _saveInmueble() async {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<InmuebleProvider>();

      // 🔍 DEBUG: Verificar estado del provider antes de crear inmueble
      print('═══════════════════════════════════════════════════════');
      print('🏗️ INICIANDO CREACIÓN/EDICIÓN DE INMUEBLE');
      print('📋 Provider isInitialized: ${provider.isInitialized}');
      print('👤 CurrentUser: ${provider.currentUser != null ? "CARGADO (ID: ${provider.currentUser!.id})" : "❌ NULL"}');
      print('✏️ Modo edición: ${widget.isEditing}');

      provider.isLoading = true;
      // Create or update the property
      InmuebleModel inmueble = InmuebleModel(
        id: widget.isEditing ? widget.inmueble!.id : 0,
        userId: provider.currentUser?.id ?? 0,
        nombre: _nombreController.text,
        detalle: _detalleController.text,
        numHabitacion: _numHabitacionController.text,
        numPiso: _numPisoController.text,
        precio: double.tryParse(_precioController.text) ?? 0.0,
        isOcupado: _isOcupado,
        servicios_basicos: _selectedServices,
        tipoInmuebleId: _tipoInmuebleId,
      );

      print('📦 Inmueble creado:');
      print('   - ID: ${inmueble.id}');
      print('   - User ID: ${inmueble.userId} ${inmueble.userId == 0 ? "⚠️ CERO!" : "✅"}');
      print('   - Nombre: ${inmueble.nombre}');
      print('   - Tipo Inmueble ID: ${inmueble.tipoInmuebleId}');
      print('═══════════════════════════════════════════════════════');

      bool success;
      if (widget.isEditing) {
        success = await provider.updateInmueble(inmueble);
      } else {
        success = await provider.createInmueble(inmueble);
      }

      if (success && _selectedImages.isNotEmpty) {
        setState(() {
          _isUploading = true;
        });

        // Upload images
        final inmuebleId = provider.selectedInmueble?.id ?? 0;
        if (inmuebleId > 0) {
          for (var image in _selectedImages) {
            // Compress image before uploading
            final compressedImage = await _compressImage(image);
            if (compressedImage != null) {
              await provider.uploadInmuebleImage(
                inmuebleId,
                compressedImage.path,
              );
            }
          }
        }

        setState(() {
          _isUploading = false;
        });
      }

      provider.isLoading = false;

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isEditing
                    ? 'Inmueble actualizado exitosamente'
                    : 'Inmueble creado exitosamente',
              ),
              backgroundColor: Colors.green,
            ),
          );
          // Navegar a la lista de inmuebles para ver el inmueble creado/actualizado
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MyInmueblesScreen(),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.message ?? 'Error al guardar el inmueble'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteImage(int index) async {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _deleteExistingImage(GaleriaInmuebleModel image) async {
    if (widget.inmueble != null) {
      context.read<InmuebleProvider>().isLoading = true;
      final success = await context
          .read<InmuebleProvider>()
          .deleteInmuebleImage(image.id, widget.inmueble!.id);

      if (success) {
        setState(() {
          _existingImages.removeWhere((item) => item.id == image.id);
        });
      }
      context.read<InmuebleProvider>().isLoading = false;
    }
  }

  Widget _buildImageList(List<dynamic> images, bool isExisting) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          final image = images[index];
          // String imagePath = '${ApiService.getInstance().baseUrlImage}/${image.photoPath}';
          final String imagePath = isExisting
              ? '${ApiService.getInstance().baseUrlImage}/${image.photoPath}'
              : image.path;
          print('Image path: $imagePath');
          return Stack(
            children: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child:
                      isExisting
                          ? Image.network(
                            imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.error, color: Colors.red),
                              );
                            },
                          )
                          : Image.file(File(image.path), fit: BoxFit.cover),
                ),
              ),
              Positioned(
                top: 4,
                right: 12,
                child: GestureDetector(
                  onTap:
                      () =>
                          isExisting
                              ? _deleteExistingImage(image)
                              : _deleteImage(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final apiService = context.read<InmuebleProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar Inmueble' : 'Crear Inmueble'),
        actions: [
          if (!apiService.isLoading && !_isUploading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveInmueble,
              tooltip: 'Guardar',
            ),
        ],
      ),
      body:
          apiService.isLoading
              ? Loading(title: 'Cargando inmueble...')
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Property details form
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del inmueble',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese un nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _detalleController,
                        decoration: const InputDecoration(
                          labelText: 'Detalles',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _numHabitacionController,
                              decoration: const InputDecoration(
                                labelText: 'Número de habitaciones',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Requerido';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Debe ser un número válido';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _numPisoController,
                              decoration: const InputDecoration(
                                labelText: 'Número de piso',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Requerido';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Debe ser un número válido';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _precioController,
                        decoration: const InputDecoration(
                          labelText: 'Precio',
                          border: OutlineInputBorder(),
                          prefixText: '\$ ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese un precio';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Por favor ingrese un número válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Consumer<InmuebleProvider>(
                        builder: (context, provider, child) {
                          final tipoInmuebles = provider.tipoInmuebles;

                          // Si no hay tipos de inmueble, mostrar mensaje
                          if (tipoInmuebles.isEmpty) {
                            return TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Tipo de Inmueble',
                                border: OutlineInputBorder(),
                                helperText: 'Cargando tipos de inmueble...',
                              ),
                              enabled: false,
                            );
                          }

                          // Verificar si el valor actual existe en la lista
                          final valueExists = tipoInmuebles.any((t) => t.id == _tipoInmuebleId);

                          return DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Tipo de Inmueble',
                              border: OutlineInputBorder(),
                            ),
                            value: valueExists ? _tipoInmuebleId : tipoInmuebles.first.id,
                            items: tipoInmuebles.map((tipo) {
                              return DropdownMenuItem<int>(
                                value: tipo.id,
                                child: Text(tipo.nombre),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _tipoInmuebleId = value ?? tipoInmuebles.first.id;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Por favor seleccione un tipo de inmueble';
                              }
                              return null;
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: _isOcupado,
                            onChanged: (value) {
                              setState(() {
                                _isOcupado = value ?? false;
                              });
                            },
                          ),
                          const Text('¿Está ocupado?'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Servicios Básicos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Selecciona los servicios básicos que ofrece este inmueble',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: context.watch<InmuebleProvider>().serviciosBasicos.map((servicio) {
                          bool isSelected = _selectedServices.any((s) => s.id == servicio.id);
                          return FilterChip(
                            label: Text(servicio.nombre),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  ServicioBasicoModel servicioSeleccionado = ServicioBasicoModel(
                                    id: servicio.id,
                                    nombre: servicio.nombre,
                                    descripcion: servicio.descripcion,
                                  );
                                  _selectedServices.add(servicioSeleccionado);
                                } else {
                                  _selectedServices.removeWhere((s) => s.id == servicio.id);
                                }
                              });
                            },
                            selectedColor: Colors.blue.shade100,
                            checkmarkColor: Colors.blue,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Imágenes del inmueble',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Puedes subir múltiples imágenes. Cada imagen será reducida a menos de 1MB.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      // Existing images
                      if (apiService.galeriaInmueble.isNotEmpty) ...[
                        const Text(
                          'Imágenes existentes:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildImageList(apiService.galeriaInmueble, true),
                        const SizedBox(height: 16),
                      ],
                      // Selected images
                      if (_selectedImages.isNotEmpty) ...[
                        const Text(
                          'Imágenes seleccionadas:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildImageList(_selectedImages, false),
                        const SizedBox(height: 16),
                      ],
                      // Image selection buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isUploading ? null : _pickImages,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Galería'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _isUploading ? null : _takePicture,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Cámara'),
                          ),
                        ],
                      ),
                      if (_isUploading) ...[
                        const SizedBox(height: 16),
                        const Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 8),
                              Text('Subiendo imágenes...'),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed:
                              apiService.isLoading || _isUploading ? null : _saveInmueble,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            widget.isEditing
                                ? 'Actualizar Inmueble'
                                : 'Crear Inmueble',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
