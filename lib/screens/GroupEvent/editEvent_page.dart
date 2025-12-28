import 'package:cift_teker_front/models/requests/updateGroupEvent_request.dart';
import 'package:cift_teker_front/models/responses/groupEvent_response.dart';
import 'package:cift_teker_front/services/groupEvent_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cift_teker_front/cities/turkish_cities.dart';

class EditEventPage extends StatefulWidget {
  final GroupEventResponse event;
  const EditEventPage({super.key, required this.event});

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();
  final EventService _eventService = EventService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _startDateTime;
  late DateTime _endDateTime;
  late TextEditingController _startLocationController;
  late TextEditingController _endLocationController;
  late TextEditingController _maxParticipantsController;
  String? _city;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController = TextEditingController(
      text: widget.event.description,
    );
    _startDateTime = widget.event.startDateTime;
    _endDateTime = widget.event.endDateTime;
    _startLocationController = TextEditingController(
      text: widget.event.startLocation,
    );
    _endLocationController = TextEditingController(
      text: widget.event.endLocation,
    );
    _maxParticipantsController = TextEditingController(
      text: widget.event.maxParticipants.toString(),
    );
    _city = widget.event.city;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _startLocationController.dispose();
    _endLocationController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async => await _storage.read(key: "auth_token");

  Future<void> _pickStartDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startDateTime),
    );
    if (time == null) return;
    setState(() {
      _startDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickEndDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endDateTime),
    );
    if (time == null) return;
    setState(() {
      _endDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_endDateTime.isBefore(_startDateTime)) {
      _showAlert("Hata", "Bitiş tarihi başlangıç tarihinden önce olamaz.");
      return;
    }

    final token = await _getToken();
    if (token == null || token.isEmpty) {
      _showAlert("Hata", "Giriş yapılmamış.");
      return;
    }

    setState(() => _isSubmitting = true);

    final request = UpdateGroupEventRequest(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      startDateTime: _startDateTime,
      endDateTime: _endDateTime,
      startLocation: _startLocationController.text.trim(),
      endLocation: _endLocationController.text.trim(),
      maxParticipants:
          int.tryParse(_maxParticipantsController.text.trim()) ??
          widget.event.maxParticipants,
      city: _city ?? widget.event.city ?? '',
    );

    try {
      final resp = await _eventService.updateGroupEvent(
        widget.event.groupEventId,
        request,
        token,
      );
      if (resp != null && resp.data != null) {
        Navigator.pop(context, resp.data);
      } else {
        _showAlert("Hata", "Güncelleme başarısız: ${resp?.message}");
      }
    } catch (e) {
      _showAlert("Hata", "Güncelleme sırasında hata: $e");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Etkinliği Düzenle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Başlık',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Başlık gerekli' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _pickStartDateTime,
                      child: Text(
                        'Başlangıç: ${_startDateTime.toLocal()}'
                            .split('.')
                            .first,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _pickEndDateTime,
                      child: Text(
                        'Bitiş: ${_endDateTime.toLocal()}'.split('.').first,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _startLocationController,
                decoration: const InputDecoration(
                  labelText: 'Başlangıç Lokasyonu',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Lokasyon gerekli' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _endLocationController,
                decoration: const InputDecoration(
                  labelText: 'Bitiş Lokasyonu',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Lokasyon gerekli' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maxParticipantsController,
                decoration: const InputDecoration(
                  labelText: 'Maks Katılımcı',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Geçerli sayı girin';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _city,
                decoration: const InputDecoration(
                  labelText: 'Şehir',
                  border: OutlineInputBorder(),
                ),
                items: TurkishCities.list
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _city = v),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Şehir seçiniz' : null,
                isExpanded: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Güncelle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
