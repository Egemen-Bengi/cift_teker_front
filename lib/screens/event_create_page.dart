import 'package:cift_teker_front/cities/turkish_cities.dart';
import 'package:cift_teker_front/formatter/time_input_formatter.dart';
import 'package:cift_teker_front/models/requests/groupEvent_request.dart';
import 'package:cift_teker_front/screens/main_navigation.dart';
import 'package:cift_teker_front/services/groupEvent_service.dart';
import 'package:cift_teker_front/widgets/CustomAppBar_Widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EventCreatePage extends StatefulWidget {
  const EventCreatePage({super.key});

  @override
  State<EventCreatePage> createState() => _EventCreatePageState();
}

class _EventCreatePageState extends State<EventCreatePage> {
  final TextEditingController startLocationController = TextEditingController();
  final TextEditingController endLocationController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();
  final TextEditingController capacityController = TextEditingController();
  final List<String> _turkishCities = TurkishCities.list;

  DateTime? selectedDate;
  String? selectedCity;

  Future<void> pickDate() async {
    final today = DateTime.now();
    final date = await showDatePicker(
      context: context,
      locale: const Locale('tr'),
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
                                        : DateFormat(
                                            'dd MMM yyyy',
                                            'tr',
                                          ).format(selectedDate!),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      color: Colors.grey.shade50,
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      underline: const SizedBox(),
                      menuMaxHeight: 300,
                      hint: Row(
                        children: [
                          Icon(
                            Icons.location_city,
                            color: Colors.orangeAccent,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text("Şehir"),
                        ],
                      ),
                      value: selectedCity,
                      items: _turkishCities.map((String city) {
                        return DropdownMenuItem<String>(
                          value: city,
                          child: Text(city),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() => selectedCity = newValue);
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Konumlar
                  Row(
                    children: [
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
                            selectedCity == null ||
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
                          city: selectedCity!,
                        );

                        try {
                          final storage = const FlutterSecureStorage();
                          final token = await storage.read(key: "auth_token");

                          final response = await EventService()
                              .createGroupEvent(request, token!);

                          if (response.httpStatus == "OK" ||
                              response.httpStatus == "CREATED" ||
                              response.httpStatus == "200") {
                            if (!mounted) return;

                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return Center(
                                  child: SingleChildScrollView(
                                    child: Dialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      elevation: 0,
                                      backgroundColor: Colors.transparent,
                                      child: Container(
                                        padding: const EdgeInsets.all(30),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 20,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade100,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.check_circle,
                                                color: Colors.green.shade700,
                                                size: 50,
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            Text(
                                              response.message,
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 12),
                                            const Text(
                                              "Etkinliğiniz başarıyla oluşturuldu. Ana sayfaya yönlendiriliyorsunuz.",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 25),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  Navigator.pushAndRemoveUntil(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          const MainNavigation(),
                                                    ),
                                                    (route) => false,
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.orangeAccent,
                                                  foregroundColor: Colors.white,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                ),
                                                child: const Text(
                                                  "Ana Sayfaya Dön",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          } else {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Hata: ${response.message}"),
                              ),
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
