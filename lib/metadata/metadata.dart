class MetaData {
  final String artistName;
  final String songName;
  final DateTime dateTime;
  MetaData({required this.artistName, required this.dateTime, required this.songName});

  factory MetaData.fromJson(Map json) {
    return MetaData(artistName: json['artist'], dateTime: DateTime.parse(json['date']).toLocal(), songName: json['songName']);
  }
}
