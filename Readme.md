# AVFoundation Basics

This project is dedicated to exploring the basics of Apple's AVFoundation framework. It serves as a starting point for developers looking to understand how to work with media assets, including video and audio, within iOS applications.

## Overview

AVFoundation is a powerful framework for working with time-based audiovisual media on Apple platforms. This project demonstrates fundamental concepts and common tasks you can perform with AVFoundation, such as:

- Playing audio and video files
- Capturing media using the device’s camera
- Handling various media formats
- Basic media editing

## Project Structure

- **`PlaybackListController.swift`**: Demonstrates how to load media data from a JSON file and display it in a table view.
- **`MediaItem.swift`**: A model representing media items with properties like title, description, thumbnail, and source URL.
- **`PublicData.json`**: A sample JSON file containing media data for testing purposes.
- **`ChoiceViewController.swift`**: A basic controller that allows the user to choose between Camera, Playback, and Miscellaneous options.

## Getting Started

### Prerequisites

- Xcode 12 or later
- iOS 14.0 or later
- Swift 5.0 or later

### Installation

1. Clone the repository:

    ```bash
    git clone https://github.com/ribhu69/AVFoundationBasics.git
    ```

2. Open the project in Xcode:

    ```bash
    cd AVFoundation-Basics
    open AVFoundation-Basics.xcodeproj
    ```

3. Build and run the project on a simulator or a real device.

### Usage

- **Playback Media**: The `PlaybackListController` provides a list of media items from the `PublicData.json` file. Select an item to play it.
- **Capture Media**: Choose the "Camera" option to access the device’s camera and capture photos or videos.

## Contributing

Contributions are welcome! Feel free to submit a pull request or open an issue if you find a bug or have a feature request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgements

- [Apple Developer Documentation](https://developer.apple.com/documentation/avfoundation) - For in-depth AVFoundation resources.

---

Happy coding!
