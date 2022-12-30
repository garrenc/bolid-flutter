import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:radio_bolid/metadata/metadata.dart';

mixin MetadataObserver {
  void metadataListener();
}

class MetadataWorker {
  static List<MetaData> metaData = [];
  MetadataWorker._();

  static final MetadataWorker _instance = MetadataWorker._();

  static MetadataWorker get instance => _instance;

  bool isRunning = false;

  MetadataObserver? metadataObserver;

  void addObserver(MetadataObserver observer) {
    metadataObserver = observer;
  }

  void removeObserver(MetadataObserver observer) {
    metadataObserver = null;
  }

  void notifyObservers() {
    if (metadataObserver != null) {
      metadataObserver!.metadataListener();
    }
  }

  void start() async {
    print('Starting fetching metadata...');
    isRunning = true;
    await loadAndStore();
    Timer.periodic(const Duration(seconds: 30), (timer) async => await loadAndStore());
  }

  void stop() {
    print('Stopping fetching metadata...');
    isRunning = false;
  }

  Future<void> loadAndStore() async {
    if (isRunning) {
      var request = await http.get(Uri.parse('http://217.25.93.159:3000/songs'));
      var decoded = json.decode(request.body);
      metaData = (decoded['result'] as List).map((e) => MetaData.fromJson(e)).toList();
      notifyObservers();
    }
  }
}
