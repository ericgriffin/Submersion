# Submersion

An open-source dive logging application for scuba divers.

## Features

- **Dive Logging**: Track all your dives with comprehensive data entry
- **Dive Sites**: Manage and organize your favorite dive locations
- **Gear Management**: Track your equipment and service schedules
- **Statistics**: View insights and analytics about your diving history
- **Import/Export**: Exchange data with other dive log applications (UDDF, CSV)
- **Cross-Platform**: Runs on macOS, Windows, Linux, iOS, and Android

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.5.0 or higher)
- [Dart SDK](https://dart.dev/get-dart) (included with Flutter)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/submersion.git
   cd submersion
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Generate code (database, serialization):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. Run the app:
   ```bash
   # Mobile/Desktop
   flutter run

   # Specific platform
   flutter run -d macos
   flutter run -d windows
   flutter run -d linux
   flutter run -d ios
   flutter run -d android
   ```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # Root widget
├── core/                     # Core utilities and services
│   ├── constants/            # Enums, units, constants
│   ├── database/             # Drift database schema
│   ├── router/               # Navigation (go_router)
│   ├── services/             # Core services
│   └── theme/                # App theming
├── features/                 # Feature modules
│   ├── dive_log/             # Dive logging feature
│   ├── dive_sites/           # Dive site management
│   ├── gear/                 # Gear tracking
│   ├── statistics/           # Analytics & stats
│   ├── import_export/        # Data import/export
│   ├── dive_computer/        # Dive computer integration
│   └── settings/             # App settings
└── shared/                   # Shared widgets and utilities
```

## Architecture

Submersion follows Clean Architecture principles:

- **Presentation Layer**: Flutter widgets, pages, and state management (Riverpod)
- **Domain Layer**: Business logic, entities, and use cases
- **Data Layer**: Repositories, data sources, and database (Drift/SQLite)

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed documentation.

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the GPL-3.0 License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Subsurface](https://subsurface-divelog.org/) - Inspiration and UDDF format
- [libdivecomputer](https://www.libdivecomputer.org/) - Dive computer communication
- [Flutter](https://flutter.dev/) - Cross-platform framework
