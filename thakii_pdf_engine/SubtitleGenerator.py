import sys
print("Python executable:", sys.executable)
print("sys.path:", sys.path)
from moviepy.editor import VideoFileClip
import torch
import whisper
#from moviepy.editor import VideoFileClip
import os
import datetime

class SubtitleGenerator:
    def __init__(self):
        print("Initializing SubtitleGenerator...")
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        print(f"Using device: {self.device}")
        self.model = whisper.load_model("base", device=self.device)
        print("Model loaded successfully.")

    @staticmethod
    def extract_audio(file_path):
        print(f"Extracting audio from {file_path}")
        audio_path = file_path.rsplit(".", 1)[0] + ".wav"
        if not os.path.exists(audio_path):
            print(f"Audio file does not exist, creating new audio file at {audio_path}")
            with VideoFileClip(file_path) as video:
                video.audio.write_audiofile(audio_path, codec='pcm_s16le')
            print(f"Audio file {audio_path} created successfully.")
        else:
            print(f"Audio file {audio_path} already exists.")
        return audio_path

    @staticmethod
    def format_time(seconds):
        h = int(seconds // 3600)
        m = int((seconds % 3600) // 60)
        s = int(seconds % 60)
        ms = int((seconds - int(seconds)) * 1000)
        return f"{h:02}:{m:02}:{s:02},{ms:03}"

    def generate_subtitles(self, file_path):
        start_time = datetime.datetime.now()
        print(f"Start generating subtitles at {start_time}")

        if file_path.lower().endswith(('.mp4', '.mkv', '.mov', '.avi')):
            audio_path = self.extract_audio(file_path)
        else:
            print(f"Non-video file detected, using {file_path} directly as audio source.")
            audio_path = file_path
        print("Done extracting audio.")
        
        result = self.model.transcribe(audio_path)
        print("Done transcribing.")
        end_time = datetime.datetime.now()
        print(f"Finished generating subtitles at {end_time}")
        print(f"Total time taken: {end_time - start_time}")

        total_segments = len(result["segments"])
        with open(file_path.rsplit(".", 1)[0] + ".srt", "w", encoding='utf-8') as subtitle_file:
            for i, segment in enumerate(result["segments"]):
                start = self.format_time(segment["start"])
                end = self.format_time(segment["end"])
                text = segment["text"]
                subtitle_file.write(f"{i+1}\n{start} --> {end}\n{text}\n\n")
                progress = (i + 1) / total_segments * 100
                sys.stdout.write(f"\rProgress: {progress:.2f}%")
                sys.stdout.flush()

def convert_srt_to_vtt(srt_file_path, vtt_file_path):
    try:
        with open(srt_file_path, 'r', encoding='utf-8') as srt_file:
            lines = srt_file.readlines()
        
        with open(vtt_file_path, 'w', encoding='utf-8') as vtt_file:
            # Write the WebVTT file header
            vtt_file.write("WEBVTT\n\n")

            for line in lines:
                # Convert timecode format from SRT (HH:MM:SS,mmm) to VTT (HH:MM:SS.mmm)
                if '-->' in line:
                    line = line.replace(',', '.')
                vtt_file.write(line)
                
    except Exception as e:
        print(f"An error occurred: {e}")
        
if __name__ == "__main__":
    print("Starting ...")
    if len(sys.argv) > 1:
        file_path = sys.argv[1]
        generator = SubtitleGenerator()
        generator.generate_subtitles(file_path)
        srt_path = file_path.rsplit(".", 1)[0] + ".srt"
        vtt_path = file_path.rsplit(".", 1)[0] + ".vtt"
        convert_srt_to_vtt(srt_path, vtt_path)
    else:
        print("Please provide the path to the video or audio file.")
