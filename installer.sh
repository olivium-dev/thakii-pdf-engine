#!/bin/bash

# 1. Ensure Xcode Command Line Tools are installed
echo "Checking for Xcode Command Line Tools..."
if ! xcode-select -p &> /dev/null; then
  echo "Xcode Command Line Tools not found. Installing..."
  xcode-select --install
else
  echo "Xcode Command Line Tools are already installed."
fi

# 2. Install Homebrew (if not already installed)
echo "Checking for Homebrew..."
if ! command -v brew &> /dev/null; then
  echo "Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "Homebrew is already installed."
fi

# 3. Reinstall Python 3.9 to ensure proper configuration
echo "Reinstalling Python 3.9 using Homebrew..."
brew reinstall python@3.9

# 4. Create a virtual environment
VENV_PATH="$HOME/venv/my-project"
echo "Creating virtual environment at $VENV_PATH..."
/opt/homebrew/bin/python3.9 -m venv "$VENV_PATH"

# 5. Activate the virtual environment
echo "Activating virtual environment..."
source "$VENV_PATH/bin/activate"

# 6. Upgrade pip, setuptools, and wheel
echo "Upgrading pip, setuptools, and wheel..."
pip install --upgrade pip setuptools wheel

# 7. Pre-install numpy and opencv-python as wheels
echo "Installing numpy and opencv-python from prebuilt wheels..."
pip install --only-binary=:all: numpy==1.19.5 opencv-python==4.5.1.48

# 8. Install the rest of the dependencies
REQUIREMENTS_FILE="requirements.txt"
if [ -f "$REQUIREMENTS_FILE" ]; then
  echo "Installing dependencies from $REQUIREMENTS_FILE..."
  pip install --only-binary=:all: -r "$REQUIREMENTS_FILE"
else
  echo "Requirements file not found. Skipping dependency installation."
fi

# 9. Set Environment Variables for Builds (optional for specific errors)
export CFLAGS="-march=native -mtune=native"
export LDFLAGS="-L/usr/local/lib"

echo "Setup complete."
