import 'model_file.dart';

export 'model_file.dart';

enum EngineFamily { parakeet, vosk, whisper }

const String _parakeetRepo =
    'https://huggingface.co/csukuangfj/sherpa-onnx-nemo-parakeet-tdt-0.6b-v3-int8/resolve/main';
const String _whisperRepo =
    'https://huggingface.co/ggerganov/whisper.cpp/resolve/main';

const ModelFile _sileroVad = ModelFile(
  path: 'common/silero_vad.onnx',
  url: 'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/silero_vad.onnx',
  sha256: '9e2449e1087496d8d4caba907f23e0bd3f78d91fa552479bb9c23ac09cbb1fd6',
  sizeBytes: 643854,
);

enum SpeechEngine implements ModelPackage {
  parakeet(
    title: 'Parakeet v3',
    library: 'sherpa-onnx',
    sizeLabel: 'ok. 670 MB',
    description:
        'NVIDIA, 25 języków europejskich, z interpunkcją (licencja CC-BY-4.0)',
    family: EngineFamily.parakeet,
    files: [
      ModelFile(
        path: 'parakeet-v3/encoder.int8.onnx',
        url: '$_parakeetRepo/encoder.int8.onnx',
        sha256:
            'acfc2b4456377e15d04f0243af540b7fe7c992f8d898d751cf134c3a55fd2247',
        sizeBytes: 652184281,
      ),
      ModelFile(
        path: 'parakeet-v3/decoder.int8.onnx',
        url: '$_parakeetRepo/decoder.int8.onnx',
        sha256:
            '179e50c43d1a9de79c8a24149a2f9bac6eb5981823f2a2ed88d655b24248db4e',
        sizeBytes: 11845275,
      ),
      ModelFile(
        path: 'parakeet-v3/joiner.int8.onnx',
        url: '$_parakeetRepo/joiner.int8.onnx',
        sha256:
            '3164c13fc2821009440d20fcb5fdc78bff28b4db2f8d0f0b329101719c0948b3',
        sizeBytes: 6355277,
      ),
      ModelFile(
        path: 'parakeet-v3/tokens.txt',
        url: '$_parakeetRepo/tokens.txt',
        sha256:
            'd58544679ea4bc6ac563d1f545eb7d474bd6cfa467f0a6e2c1dc1c7d37e3c35d',
        sizeBytes: 93939,
      ),
      _sileroVad,
    ],
  ),
  vosk(
    title: 'Vosk small-pl',
    library: 'Vosk',
    sizeLabel: 'ok. 53 MB',
    description: 'model strumieniowy, tekst od razu, bez interpunkcji',
    family: EngineFamily.vosk,
    files: [
      ModelFile(
        path: 'vosk/vosk-model-small-pl-0.22.zip',
        url: 'https://alphacephei.com/vosk/models/vosk-model-small-pl-0.22.zip',
        sha256:
            'c4cd16498ea544f446f9e9a55cbd602b71cfe5a2b6f2b0834d81e1b6fce15f0d',
        sizeBytes: 52979372,
        extract: true,
      ),
    ],
  ),
  whisperTiny(
    title: 'Whisper tiny',
    library: 'whisper.cpp',
    sizeLabel: 'ok. 33 MB',
    description: 'skwantyzowany (q5_1), najszybszy, najsłabszy po polsku',
    family: EngineFamily.whisper,
    files: [
      ModelFile(
        path: 'whisper/ggml-tiny-q5_1.bin',
        url: '$_whisperRepo/ggml-tiny-q5_1.bin',
        sha256:
            '818710568da3ca15689e31a743197b520007872ff9576237bda97bd1b469c3d7',
        sizeBytes: 32152673,
      ),
      _sileroVad,
    ],
  ),
  whisperBase(
    title: 'Whisper base',
    library: 'whisper.cpp',
    sizeLabel: 'ok. 61 MB',
    description: 'skwantyzowany (q5_1), kompromis szybkości i jakości',
    family: EngineFamily.whisper,
    files: [
      ModelFile(
        path: 'whisper/ggml-base-q5_1.bin',
        url: '$_whisperRepo/ggml-base-q5_1.bin',
        sha256:
            '422f1ae452ade6f30a004d7e5c6a43195e4433bc370bf23fac9cc591f01a8898',
        sizeBytes: 59707625,
      ),
      _sileroVad,
    ],
  ),
  whisperSmall(
    title: 'Whisper small',
    library: 'whisper.cpp',
    sizeLabel: 'ok. 191 MB',
    description: 'skwantyzowany (q5_1), najdokładniejszy z Whisperów',
    family: EngineFamily.whisper,
    files: [
      ModelFile(
        path: 'whisper/ggml-small-q5_1.bin',
        url: '$_whisperRepo/ggml-small-q5_1.bin',
        sha256:
            'ae85e4a935d7a567bd102fe55afc16bb595bdb618e11b2fc7591bc08120411bb',
        sizeBytes: 190085487,
      ),
      _sileroVad,
    ],
  );

  const SpeechEngine({
    required this.title,
    required this.library,
    required this.sizeLabel,
    required this.description,
    required this.family,
    required this.files,
  });

  static const SpeechEngine defaultEngine = SpeechEngine.parakeet;

  static const String vadModelPath = 'common/silero_vad.onnx';

  static const String voskModelDir = 'vosk/vosk-model-small-pl-0.22';

  @override
  final String title;
  final String library;
  final String sizeLabel;
  final String description;
  final EngineFamily family;
  @override
  final List<ModelFile> files;

  String get primaryModelPath => files.first.path;
}
