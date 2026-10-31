import 'package:flutter/material.dart';
import 'package:flutter_hbb/buskit_brand.dart';
import 'package:flutter_hbb/common.dart' show showToast;
import 'package:flutter_hbb/models/platform_model.dart';
export 'buskit_update_button.dart';

class BuskitTechnicianProfile extends StatefulWidget {
  const BuskitTechnicianProfile({Key? key}) : super(key: key);

  @override
  State<BuskitTechnicianProfile> createState() => _BuskitTechnicianProfileState();
}

class _BuskitTechnicianProfileState extends State<BuskitTechnicianProfile> {
  static const _profileKey = 'buskit-technician-profile';
  static const _nameKey = 'buskit-technician-name';
  late bool _enabled = bind.mainGetLocalOption(key: _profileKey) == 'Y';
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    final savedName = bind.mainGetLocalOption(key: _nameKey).trim();
    _name = TextEditingController(
        text: savedName.isEmpty ? buskitTechnicianDisplayName : savedName);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    await bind.mainSetLocalOption(
        key: _nameKey,
        value: name.isEmpty ? buskitTechnicianDisplayName : name);
    await bind.mainSetLocalOption(
        key: _profileKey, value: _enabled ? 'Y' : 'N');
    showToast('Perfil guardado. Se aplicará en la próxima conexión.');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Perfil del técnico',
              style: TextStyle(fontWeight: FontWeight.bold)),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Usar este equipo como técnico BUSKIT'),
            value: _enabled,
            onChanged: (value) => setState(() => _enabled = value ?? false),
          ),
          const Text('Actívalo solo en el equipo desde el que das soporte.'),
          const SizedBox(height: 16),
          Row(
            children: [
              Image.asset('assets/icon.png', width: 56, height: 56),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _name,
                  enabled: _enabled,
                  maxLength: 80,
                  decoration: const InputDecoration(
                      labelText: 'Nombre que verá el cliente',
                      border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _save, child: const Text('Guardar perfil')),
        ],
      ),
    );
  }
}
