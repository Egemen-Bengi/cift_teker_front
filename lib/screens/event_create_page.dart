import 'package:cift_teker_front/formatter/time_input_formatter.dart';
import 'package:cift_teker_front/models/requests/groupEvent_request.dart';
import 'package:cift_teker_front/services/groupEvent_service.dart';
import 'package:cift_teker_front/widgets/CustomAppBar_Widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EventCreatePage extends StatefulWidget {
  const EventCreatePage({super.key});

  @override
  State<EventCreatePage> createState() => _EventCreatePageState();
}

class _EventCreatePageState extends State<EventCreatePage> {
  final TextEditingController cityController = TextEditingController();
  final TextEditingController startLocationController = TextEditingController();
  final TextEditingController endLocationController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();
  final TextEditingController capacityController = TextEditingController();

  DateTime? selectedDate;

  Future<void> pickDate() async {
    final today = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: DateTime(2030),
      initialDate: today,
    );

    if (date != null) {
      setState(() => selectedDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(title: "Etkinlik Oluştur"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 3 / 2,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                  image: const DecorationImage(
                    image: AssetImage("assets/grupSurus.png"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    color: Colors.black.withOpacity(0.07),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ------------ Etkinlik Başlığı
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.event,
                        color: Colors.orangeAccent,
                      ),
                      labelText: "Etkinlik Başlığı",
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ------------ Açıklama
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.description,
                        color: Colors.orangeAccent,
                      ),
                      labelText: "Etkinlik Açıklaması",
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ------------ Tarih ve Kapasite
                  const Text(
                    "Etkinlik Tarihi",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: Colors.orangeAccent,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    selectedDate == null
                                        ? "Tarih seç"
                                        : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Max katılımcı sayısı
                      SizedBox(
                        width: 140,
                        child: TextField(
                          controller: capacityController,
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter
                                .digitsOnly, // sadece rakam
                          ],
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.people,
                              color: Colors.orangeAccent,
                            ),
                            labelText: "Katılımcı Sayısı",
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ------------ Saatler
                  const Text(
                    "Başlangıç - Bitiş Saati",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: startTimeController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            TimeInputFormatter(),
                          ],
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.access_time,
                              color: Colors.orangeAccent,
                            ),
                            labelText: "Başlangıç (HH:MM)",
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: endTimeController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            TimeInputFormatter(),
                          ],
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.access_time,
                              color: Colors.orangeAccent,
                            ),
                            labelText: "Bitiş (HH:MM)",
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  const Text(
                    "Etkinlik Konumları",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),

                  // Şehir
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cityController,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r"[a-zA-ZığüşöçİĞÜŞÖÇ\s]"),
                            ),
                          ],
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.location_city,
                              color: Colors.orangeAccent,
                            ),
                            labelText: "Şehr",
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: startLocationController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.location_on_outlined,
                              color: Colors.orangeAccent,
                            ),
                            labelText: "Başlangıç Konumu",
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: endLocationController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.flag_outlined,
                              color: Colors.orangeAccent,
                            ),
                            labelText: "Bitiş Konumu",
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Etkinlik Oluştur butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Zorunlu alanları kontrol et
                        if (titleController.text.isEmpty ||
                            capacityController.text.isEmpty ||
                            cityController.text.isEmpty ||
                            descriptionController.text.isEmpty ||
                            startLocationController.text.isEmpty ||
                            endLocationController.text.isEmpty ||
                            selectedDate == null ||
                            startTimeController.text.isEmpty ||
                            endTimeController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Lütfen tüm alanları doldurun."),
                            ),
                          );
                          print('title: ${titleController.text}');
                          print('description: ${descriptionController.text}');
                          print(
                            'startLocation: ${startLocationController.text}',
                          );
                          print('endLocation: ${endLocationController.text}');
                          print('selectedDate: ${selectedDate}');
                          print('startTime: ${startTimeController.text}');
                          print('endTime: ${endTimeController.text}');
                          print('capacity: ${capacityController.text}');
                          print('city: ${cityController.text}');
                          return;
                        }

                        // Katılımcı sayısı
                        final maxP = int.tryParse(
                          capacityController.text.trim(),
                        );
                        if (maxP == null || maxP <= 0 || maxP > 50) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Katılımcı sayısı 1-50 arasında olmalıdır.",
                              ),
                            ),
                          );
                          return;
                        }

                        // Saatleri parse et (HH:MM)
                        final startParts = startTimeController.text.split(":");
                        final endParts = endTimeController.text.split(":");

                        final startDateTime = DateTime(
                          selectedDate!.year,
                          selectedDate!.month,
                          selectedDate!.day,
                          int.parse(startParts[0]),
                          int.parse(startParts[1]),
                        );

                        final endDateTime = DateTime(
                          selectedDate!.year,
                          selectedDate!.month,
                          selectedDate!.day,
                          int.parse(endParts[0]),
                          int.parse(endParts[1]),
                        );

                        // Request objesi
                        final request = GroupEventRequest(
                          title: titleController.text,
                          description: descriptionController.text,
                          startDateTime: startDateTime,
                          endDateTime: endDateTime,
                          startLocation: startLocationController.text,
                          endLocation: endLocationController.text,
                          maxParticipants: maxP,
                          city: cityController.text,
                        );

                        try {
                          final storage = const FlutterSecureStorage();
                          final token = await storage.read(key: "auth_token");

                          final response = await EventService()
                              .createGroupEvent(request, token!);

                          if (response == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Etkinlik başarıyla oluşturuldu!",
                                ),
                              ),
                            );
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(builder: (context) => SocialMediaPage()),
                            // );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(response.message)),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text("Hata: $e")));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Etkinliği Oluştur",
                        style: TextStyle(fontSize: 17),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    startLocationController.dispose();
    endLocationController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
    capacityController.dispose();
    super.dispose();
  }
}
