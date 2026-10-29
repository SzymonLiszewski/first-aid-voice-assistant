class ModelFile {
  const ModelFile({
    required this.path,
    required this.url,
    required this.sha256,
    required this.sizeBytes,
    this.extract = false,
  });

  final String path;
  final String url;
  final String sha256;
  final int sizeBytes;
  final bool extract;

  Uri get uri => Uri.parse(url);
}

abstract interface class ModelPackage {
  String get title;

  List<ModelFile> get files;
}
