import 'package:climapp_cc20262/src/controller/list_city_controller.dart';
import 'package:climapp_cc20262/src/screens/weather_city_screen.dart';
import 'package:climapp_cc20262/src/widgets/city_tile_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ListCityScreen extends StatefulWidget {
  const ListCityScreen({super.key});

  @override
  State<ListCityScreen> createState() => _ListCityScreenState();
}

class _ListCityScreenState extends State<ListCityScreen> {
  final TextEditingController textController = TextEditingController();

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xFF00457D), Color(0xFF05051F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              const SizedBox(height: 25),
              // Identificação do país em algum canto da tela (canto superior direito)
              Align(
                alignment: Alignment.topRight,
                child: Consumer<ListCityController>(
                  builder: (context, controller, child) {
                    if (controller.deviceCountry.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.public,
                            color: Color(0xFF7693FF),
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'País: ${controller.deviceCountry}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                style: const TextStyle(color: Colors.white),
                controller: textController,
                onChanged: (query) {
                  context.read<ListCityController>().filterCities(query);
                },
                decoration: const InputDecoration(
                  fillColor: Color(0x15FFFFFF),
                  filled: true,
                  hintText: 'Digite uma cidade',
                  hintStyle: TextStyle(color: Colors.white),
                  suffixIcon: Icon(Icons.search, color: Colors.white),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: Consumer<ListCityController>(
                  builder: (context, controller, child) {
                    if (controller.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    // Mensagem de erro caso não consiga obter os dados
                    if (controller.errorMessage.isNotEmpty) {
                      return RefreshIndicator(
                        onRefresh: controller.loadCities,
                        color: const Color(0xFF7693FF),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.4,
                              child: Center(
                                child: Text(
                                  controller.errorMessage,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: controller.loadCities,
                      color: const Color(0xFF7693FF),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: controller.filteredCities.length,
                        itemBuilder: (context, index) {
                          final city = controller.filteredCities[index];
                          return CityTileWidget(
                            cityName: city.cityName,
                            icon: city.conditionSlug,
                            temperature: city.temp,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WeatherCityScreen(
                                    weatherForecastModel: city,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
