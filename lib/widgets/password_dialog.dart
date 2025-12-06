import 'package:flutter/material.dart';

enum PasswordMode { fixed, dynamic }

class PasswordDialog extends StatefulWidget {
  final PasswordMode mode;
  final int? dynamicKey;
  final String? title;
  final String? message;

  const PasswordDialog({
    Key? key,
    required this.mode,
    this.dynamicKey,
    this.title,
    this.message,
  }) : super(key: key);

  @override
  State<PasswordDialog> createState() => _PasswordDialogState();

  static Future<int?> show(
    BuildContext context, {
    required PasswordMode mode,
    int? dynamicKey,
    String? title,
    String? message,
  }) {
    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PasswordDialog(
        mode: mode,
        dynamicKey: dynamicKey,
        title: title,
        message: message,
      ),
    );
  }
}

class _PasswordDialogState extends State<PasswordDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null) {
      setState(() => _error = 'Ingrese un número válido');
      return;
    }
    Navigator.of(context).pop(value);
  }

  Widget _buildDynamicKey() {
    if (widget.mode != PasswordMode.dynamic || widget.dynamicKey == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Clave técnica',
            style: TextStyle(fontSize: 18, color: Colors.blueGrey)),
        const SizedBox(height: 2),
        Text(
          widget.dynamicKey.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.cyan,
          ),
        ),
        const SizedBox(height: 2),
      ],
    );
  }

  Widget _buildMessage() {
    if (widget.message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(widget.message!, style: const TextStyle(fontSize: 10)),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _controller,
      autofocus: true,
      obscureText: true,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Contraseña',
        errorText: _error,
      ),
      onSubmitted: (_) => _submit(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final isWide = size.width > size.height;
    final keyboard = mq.viewInsets.bottom;

    // Diálogo más compacto (mitad de pantalla)
    final dialogMaxHeight = size.height * 0.50;

    return Padding(
      padding: EdgeInsets.only(
        top: 0 + keyboard * 0.10, // subido pero sin irse arriba del todo
        bottom: keyboard * 0.40,
        left: 12,
        right: 12,
      ),

      // AQUÍ EL CAMBIO CLAVE
      child: Align(
        alignment: Alignment.topCenter, // ya no se centra, se fija arriba
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isWide ? size.width * 0.80 : 400,
            maxHeight: dialogMaxHeight,
          ),

          // Scroll interno si el teclado ocupa mucho
          child: Material(
            elevation: 10,
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).dialogBackgroundColor,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title ?? 'Contraseña requerida',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDynamicKey(),
                              _buildMessage(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(child: _buildPasswordField()),
                      ],
                    )
                  else
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDynamicKey(),
                        _buildMessage(),
                        _buildPasswordField(),
                      ],
                    ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Aceptar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
