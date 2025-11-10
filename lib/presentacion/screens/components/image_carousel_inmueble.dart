import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../datos/ApiService.dart';
import '../../../negocio/models/galeria_inmueble_model.dart';
import '../../providers/inmueble_provider.dart';

class ImageCarouselInmueble extends StatefulWidget {
  final int? inmuebleId;
  final List<dynamic>? galeriaInmueble;
  final double height;

  const ImageCarouselInmueble({
    Key? key,
    this.inmuebleId,
    this.galeriaInmueble,
    this.height = 200,
  }) : super(key: key);

  @override
  State<ImageCarouselInmueble> createState() => _ImageCarouselInmuebleState();
}

class _ImageCarouselInmuebleState extends State<ImageCarouselInmueble> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;
  List<GaleriaInmuebleModel> _loadedGaleria = [];

  @override
  void initState() {
    super.initState();
    if (widget.inmuebleId != null &&
        widget.inmuebleId! > 0 &&
        (widget.galeriaInmueble == null || widget.galeriaInmueble!.isEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadGaleriaInmueble();
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadGaleriaInmueble() async {
    if (widget.inmuebleId == null) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      await context
          .read<InmuebleProvider>()
          .loadInmuebleGaleria(widget.inmuebleId!);
      if (mounted) {
        final galeria = context.read<InmuebleProvider>().galeriaInmueble;
        setState(() {
          _loadedGaleria = galeria;
        });
      }
    } catch (e) {
      print('Error loading gallery images: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<GaleriaInmuebleModel> _getImages() {
    if (widget.galeriaInmueble != null && widget.galeriaInmueble!.isNotEmpty) {
      return widget.galeriaInmueble!.cast<GaleriaInmuebleModel>();
    }
    return _loadedGaleria;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: widget.height,
        color: Colors.grey[300],
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final images = _getImages();

    if (images.isEmpty) {
      return Container(
        height: widget.height,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.home, size: 80, color: Colors.grey),
        ),
      );
    }

    return Stack(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: images.length,
            itemBuilder: (context, index) {
              final image = images[index];
              final String imagePath =
                  '${ApiService.getInstance().baseUrlImage}/${image.photoPath}';

              return Image.network(
                imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.error, color: Colors.red, size: 50),
                    ),
                  );
                },
              );
            },
          ),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
