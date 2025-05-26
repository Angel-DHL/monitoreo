import 'package:flutter/material.dart';

class MapaEmpresaWidget extends StatelessWidget {
  final String apiKey = 'f2895e76108b480db07c13db8d7c118f'; // Reemplaza esto con tu key real

  @override
  Widget build(BuildContext context) {
    final mapUrl =
    'https://maps.geoapify.com/v1/staticmap?style=osm-carto&width=600&height=300'
    '&center=lonlat:-100.86330,20.51531'
    '&zoom=13'
    '&marker=lonlat:-100.86330,20.51531;color:%23ff0000;size:medium'
    '&apiKey=$apiKey';

    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          mapUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, error, stackTrace) => Container(
            height: 300,
            color: Colors.grey[300],
            child: Center(child: Icon(Icons.error, color: Colors.red)),
          ),
        ),
      ),
    );
  }
}
