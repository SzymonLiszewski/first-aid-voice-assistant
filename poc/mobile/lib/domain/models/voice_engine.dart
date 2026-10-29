import 'model_file.dart';

enum VoiceFamily { system, piper }

enum VoiceEngine implements ModelPackage {
  system(
    title: 'Głos systemowy',
    library: 'flutter_tts',
    sizeLabel: 'bez pobierania',
    description: 'syntezator mowy telefonu (Google / Apple), brzmi inaczej na każdym telefonie',
    family: VoiceFamily.system,
    files: [],
  ),
  piperGosia(
    title: 'Piper – Gosia',
    library: 'sherpa-onnx',
    sizeLabel: 'ok. 67 MB',
    description:
        'neuronowy głos Piper (medium), na każdym telefonie brzmi tak samo',
    family: VoiceFamily.piper,
    files: [
      ModelFile(
        path: 'piper/vits-piper-pl_PL-gosia-medium.tar.bz2',
        url: 'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-pl_PL-gosia-medium.tar.bz2',
        sha256:
            '75bd34dcbdc4dd98d763954756b4b34b4208100497c836381542e4d73dcefa9c',
        sizeBytes: 67211182,
        extract: true,
      ),
    ],
    modelDirectory: 'piper/vits-piper-pl_PL-gosia-medium',
    modelName: 'pl_PL-gosia-medium.onnx',
    espeakVoice: 'pl',
  );

  const VoiceEngine({
    required this.title,
    required this.library,
    required this.sizeLabel,
    required this.description,
    required this.family,
    required this.files,
    this.modelDirectory = '',
    this.modelName = '',
    this.espeakVoice = '',
  });

  static const VoiceEngine defaultEngine = VoiceEngine.system;

  static const String language = 'pl-PL';

  @override
  final String title;
  final String library;
  final String sizeLabel;
  final String description;
  final VoiceFamily family;
  @override
  final List<ModelFile> files;
  final String modelDirectory;
  final String modelName;
  final String espeakVoice;
}
