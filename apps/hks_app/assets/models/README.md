# TFLite Model Assets

Place the following files here when the model is ready:
- `waste_classifier.tflite` — TFLite waste contamination classification model (input: 224x224 RGB)
- `labels.txt` — One label per line: `Clean`, `Contaminated`, `Mixed`

## How the model is loaded

```dart
final interpreter = await Interpreter.fromAsset('assets/models/waste_classifier.tflite');
```

## Input format
- Image resized to 224×224 pixels
- Normalized to [0.0, 1.0] float32 values per channel
- Shape: `[1, 224, 224, 3]`

## Output format
- Shape: `[1, 3]`
- Index 0: Clean confidence
- Index 1: Contaminated confidence  
- Index 2: Mixed confidence
