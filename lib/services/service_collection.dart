class ServiceCollection {
  List _services = [];

  void add<T>(T service) {
    _services = [..._services, service];
  }

  void addAll<T>(List<T> services) {
    _services = [..._services, ...services];
  }

  T get<T>() {
    if (_services.isEmpty)
      throw Exception("No services found in ServiceCollection");
    if (_services.where((service) => service is T).isEmpty)
      throw Exception("No service of type $T found in ServiceCollection");

    return _services.firstWhere((service) => service is T) as T;
  }
}
