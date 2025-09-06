from setuptools import setup, find_packages
import os

# Read README
readme_path = os.path.join(os.path.dirname(__file__), "README.md")
if os.path.exists(readme_path):
    with open(readme_path, "r", encoding="utf-8") as fh:
        long_description = fh.read()
else:
    long_description = "Core video-to-PDF conversion library for Thakii Lecture2PDF Service"

# Read requirements
requirements_path = os.path.join(os.path.dirname(__file__), "requirements.txt")
if os.path.exists(requirements_path):
    with open(requirements_path, "r", encoding="utf-8") as fh:
        requirements = [line.strip() for line in fh if line.strip() and not line.startswith("#")]
else:
    requirements = [
        "opencv-python>=4.8.0",
        "SpeechRecognition>=3.10.0", 
        "fpdf>=2.5.7",
        "Pillow>=10.0.0",
        "webvtt-py>=0.4.6"
    ]

setup(
    name="thakii-pdf-engine",
    version="1.0.0",
    author="Thakii Team",
    author_email="team@thakii.com",
    description="Core video-to-PDF conversion library for Thakii Lecture2PDF Service",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/oudaykhaled/thakii-pdf-engine",
    packages=find_packages(),
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
    ],
    python_requires=">=3.8",
    install_requires=requirements,
    entry_points={
        "console_scripts": [
            "thakii-pdf-engine=thakii_pdf_engine.main:main",
        ],
    } if os.path.exists("thakii_pdf_engine/main.py") else {},
    include_package_data=True,
    package_data={
        "thakii_pdf_engine": ["fonts/*"] if os.path.exists("fonts") else [],
    },
)
