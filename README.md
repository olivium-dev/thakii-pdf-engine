# Thakii PDF Engine

Core video-to-PDF conversion library for the Thakii Lecture2PDF system. Provides computer vision, speech recognition, and PDF generation capabilities to transform lecture videos into readable PDF documents.

## 🚀 Features

- **Video Frame Extraction**: Intelligent key frame selection using computer vision
- **Speech Recognition**: Automatic subtitle generation from video audio
- **Scene Change Detection**: Identifies slide transitions and content changes
- **PDF Generation**: Creates formatted PDFs with images and text
- **Multiple Format Support**: Handles various video formats (MP4, AVI, MOV, WMV, MKV)
- **Subtitle Parsing**: Supports SRT and VTT subtitle formats
- **Customizable Output**: Configurable PDF layout and quality settings

## 🛠️ Technology Stack

- **OpenCV**: Computer vision and video processing
- **SpeechRecognition**: Audio-to-text conversion
- **FPDF**: PDF creation and formatting
- **Pillow**: Image processing and manipulation
- **webvtt-py**: WebVTT subtitle parsing
- **NumPy**: Numerical operations for image processing

## 📦 Installation

### PyPI Installation (Recommended)
```bash
pip install thakii-pdf-engine
```

### Development Installation
```bash
git clone https://github.com/oudaykhaled/thakii-pdf-engine.git
cd thakii-pdf-engine
pip install -e .
```

### System Dependencies
```bash
# Ubuntu/Debian
sudo apt install ffmpeg libopencv-dev python3-opencv portaudio19-dev

# macOS
brew install ffmpeg opencv portaudio

# Windows
# Install FFmpeg and add to PATH
# OpenCV will be installed via pip
```

## 🚀 Quick Start

### Command Line Usage
```bash
# Basic usage with video file
thakii-pdf-engine video.mp4 -o output.pdf

# With existing subtitles
thakii-pdf-engine video.mp4 -s subtitles.srt -o output.pdf

# Skip subtitle generation
thakii-pdf-engine video.mp4 -S -o output.pdf
```

### Python API Usage
```python
from thakii_pdf_engine import VideoProcessor, PDFGenerator

# Initialize processor
processor = VideoProcessor()

# Process video to extract frames and generate subtitles
frames, subtitles = processor.process_video("lecture.mp4")

# Generate PDF
generator = PDFGenerator()
generator.create_pdf(frames, subtitles, "output.pdf")
```

## 📁 Project Structure

```
thakii-pdf-engine/
├── thakii_pdf_engine/
│   ├── __init__.py
│   ├── main.py                    # Command line interface
│   ├── video_processor.py         # Video analysis and frame extraction
│   ├── subtitle_generator.py      # Speech recognition
│   ├── subtitle_parsers/
│   │   ├── srt_parser.py         # SRT format parser
│   │   └── vtt_parser.py         # WebVTT format parser
│   ├── frame_extractor.py         # Key frame selection
│   ├── pdf_generator.py           # PDF creation
│   └── utils/
│       ├── image_utils.py         # Image processing utilities
│       └── text_utils.py          # Text processing utilities
├── tests/
├── examples/
├── docs/
├── setup.py
└── requirements.txt
```

## 🎯 Core Components

### Video Processor
```python
class VideoProcessor:
    def process_video(self, video_path, subtitle_path=None):
        """
        Process video to extract key frames and generate subtitles
        
        Args:
            video_path (str): Path to input video file
            subtitle_path (str, optional): Path to existing subtitle file
            
        Returns:
            tuple: (frames, subtitles) - extracted frames and subtitle data
        """
```

### Frame Extractor
```python
class FrameExtractor:
    def extract_key_frames(self, video_path):
        """
        Extract key frames representing slide changes
        
        Uses computer vision algorithms:
        - Histogram comparison for scene change detection
        - Edge detection for content analysis
        - Temporal filtering to remove duplicates
        """
```

### Subtitle Generator
```python
class SubtitleGenerator:
    def generate_subtitles(self, video_path):
        """
        Generate subtitles from video audio using speech recognition
        
        Process:
        1. Extract audio from video
        2. Convert to appropriate format
        3. Apply speech recognition
        4. Generate timestamp alignment
        5. Output SRT format
        """
```

### PDF Generator
```python
class PDFGenerator:
    def create_pdf(self, frames, subtitles, output_path):
        """
        Create formatted PDF from frames and subtitles
        
        Features:
        - High-quality frame images
        - Readable text formatting
        - Consistent page layout
        - Metadata embedding
        """
```

## ⚙️ Configuration

### Processing Options
```python
config = {
    # Frame extraction settings
    "frame_similarity_threshold": 0.85,
    "min_scene_duration": 2.0,  # seconds
    "max_frames_per_minute": 10,
    
    # Speech recognition settings
    "language": "en-US",
    "audio_sample_rate": 16000,
    "recognition_timeout": 30,
    
    # PDF generation settings
    "pdf_quality": "high",  # low, medium, high
    "page_size": "A4",
    "font_size": 12,
    "image_width": 195,  # mm
}
```

### Advanced Usage
```python
from thakii_pdf_engine import VideoProcessor, Config

# Custom configuration
config = Config(
    frame_threshold=0.9,
    language="es-ES",
    pdf_quality="high"
)

# Initialize with config
processor = VideoProcessor(config=config)
result = processor.process_video("video.mp4")
```

## 🧪 Testing

```bash
# Run all tests
python -m pytest tests/

# Run specific test categories
python -m pytest tests/test_video_processing.py
python -m pytest tests/test_subtitle_generation.py
python -m pytest tests/test_pdf_creation.py

# Run with coverage
python -m pytest --cov=thakii_pdf_engine tests/
```

## 📊 Performance

### Typical Processing Times
- **Video Analysis**: 1-2 minutes per hour of video
- **Speech Recognition**: 2-3 minutes per hour of audio
- **PDF Generation**: 30-60 seconds per video
- **Total**: 3-6 minutes per hour of input video

### Memory Usage
- **Peak Memory**: 1-2GB for HD video processing
- **Average Memory**: 500MB-1GB during processing
- **Temporary Storage**: 2-3x input video size

### Optimization Tips
```python
# Use GPU acceleration if available
config.use_gpu = True

# Reduce frame quality for faster processing
config.frame_quality = "medium"

# Limit concurrent processing
config.max_workers = 2
```

## 🔧 API Reference

### Main Classes

#### VideoProcessor
Main processing class that orchestrates the entire pipeline.

```python
VideoProcessor(config=None)
    .process_video(video_path, subtitle_path=None)
    .extract_frames(video_path)
    .generate_subtitles(video_path)
```

#### FrameExtractor
Handles video analysis and key frame extraction.

```python
FrameExtractor(config=None)
    .extract_key_frames(video_path)
    .detect_scene_changes(video_path)
    .filter_similar_frames(frames)
```

#### SubtitleGenerator
Manages speech recognition and subtitle generation.

```python
SubtitleGenerator(config=None)
    .generate_from_video(video_path)
    .generate_from_audio(audio_path)
    .parse_existing(subtitle_path)
```

#### PDFGenerator
Creates formatted PDF documents from processed content.

```python
PDFGenerator(config=None)
    .create_pdf(frames, subtitles, output_path)
    .add_metadata(pdf, metadata)
    .format_content(content)
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-feature`
3. Install development dependencies: `pip install -e .[dev]`
4. Make your changes and add tests
5. Run tests: `pytest`
6. Commit changes: `git commit -am 'Add new feature'`
7. Push to branch: `git push origin feature/new-feature`
8. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🔗 Related Repositories

- [thakii-worker-service](https://github.com/oudaykhaled/thakii-worker-service) - Background processing service
- [thakii-backend-api](https://github.com/oudaykhaled/thakii-backend-api) - REST API server
- [thakii-frontend](https://github.com/oudaykhaled/thakii-frontend) - Web interface
