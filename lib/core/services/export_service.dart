import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:xml/xml.dart';

import '../constants/enums.dart' hide Visibility;
import '../constants/enums.dart' as enums show Visibility;
import '../../features/dive_log/domain/entities/dive.dart';
import '../../features/dive_sites/domain/entities/dive_site.dart';
import '../../features/equipment/domain/entities/equipment_item.dart';
import '../../features/marine_life/domain/entities/species.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  final _dateFormat = DateFormat('yyyy-MM-dd');
  final _timeFormat = DateFormat('HH:mm');
  final _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

  // ==================== CSV EXPORT ====================

  /// Export dives to CSV format
  Future<String> exportDivesToCsv(List<Dive> dives) async {
    final headers = [
      'Dive Number',
      'Date',
      'Time',
      'Site',
      'Location',
      'Max Depth (m)',
      'Avg Depth (m)',
      'Duration (min)',
      'Water Temp (°C)',
      'Air Temp (°C)',
      'Visibility',
      'Dive Type',
      'Buddy',
      'Dive Master',
      'Rating',
      'Start Pressure (bar)',
      'End Pressure (bar)',
      'Tank Volume (L)',
      'O2 %',
      'Notes',
    ];

    final rows = <List<dynamic>>[headers];

    for (final dive in dives) {
      final tank = dive.tanks.isNotEmpty ? dive.tanks.first : null;
      rows.add([
        dive.diveNumber ?? '',
        _dateFormat.format(dive.dateTime),
        _timeFormat.format(dive.dateTime),
        dive.site?.name ?? '',
        dive.site?.locationString ?? '',
        dive.maxDepth?.toStringAsFixed(1) ?? '',
        dive.avgDepth?.toStringAsFixed(1) ?? '',
        dive.duration?.inMinutes ?? '',
        dive.waterTemp?.toStringAsFixed(0) ?? '',
        dive.airTemp?.toStringAsFixed(0) ?? '',
        dive.visibility?.displayName ?? '',
        dive.diveType.displayName,
        dive.buddy ?? '',
        dive.diveMaster ?? '',
        dive.rating ?? '',
        tank?.startPressure ?? '',
        tank?.endPressure ?? '',
        tank?.volume?.toStringAsFixed(0) ?? '',
        tank?.gasMix.o2.toStringAsFixed(0) ?? '',
        dive.notes.replaceAll('\n', ' '),
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    return _saveAndShareFile(csvData, 'dives_export.csv', 'text/csv');
  }

  /// Export dive sites to CSV format
  Future<String> exportSitesToCsv(List<DiveSite> sites) async {
    final headers = [
      'Name',
      'Country',
      'Region',
      'Latitude',
      'Longitude',
      'Max Depth (m)',
      'Water Type',
      'Current',
      'Entry Type',
      'Rating',
      'Description',
      'Notes',
    ];

    final rows = <List<dynamic>>[headers];

    for (final site in sites) {
      rows.add([
        site.name,
        site.country ?? '',
        site.region ?? '',
        site.location?.latitude.toStringAsFixed(6) ?? '',
        site.location?.longitude.toStringAsFixed(6) ?? '',
        site.maxDepth?.toStringAsFixed(1) ?? '',
        site.conditions?.waterType ?? '',
        site.conditions?.typicalCurrent ?? '',
        site.conditions?.entryType ?? '',
        site.rating?.toStringAsFixed(1) ?? '',
        site.description.replaceAll('\n', ' '),
        site.notes.replaceAll('\n', ' '),
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    return _saveAndShareFile(csvData, 'sites_export.csv', 'text/csv');
  }

  /// Export equipment to CSV format
  Future<String> exportEquipmentToCsv(List<EquipmentItem> equipment) async {
    final headers = [
      'Name',
      'Type',
      'Brand',
      'Model',
      'Serial Number',
      'Purchase Date',
      'Last Service',
      'Next Service Due',
      'Active',
      'Notes',
    ];

    final rows = <List<dynamic>>[headers];

    for (final item in equipment) {
      rows.add([
        item.name,
        item.type.displayName,
        item.brand ?? '',
        item.model ?? '',
        item.serialNumber ?? '',
        item.purchaseDate != null ? _dateFormat.format(item.purchaseDate!) : '',
        item.lastServiceDate != null ? _dateFormat.format(item.lastServiceDate!) : '',
        item.nextServiceDue != null ? _dateFormat.format(item.nextServiceDue!) : '',
        item.isActive ? 'Yes' : 'No',
        item.notes.replaceAll('\n', ' '),
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    return _saveAndShareFile(csvData, 'equipment_export.csv', 'text/csv');
  }

  // ==================== PDF EXPORT ====================

  /// Generate PDF dive logbook
  Future<String> exportDivesToPdf(
    List<Dive> dives, {
    String title = 'Dive Logbook',
    List<Sighting>? allSightings,
  }) async {
    final pdf = pw.Document();

    // Cover page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 36,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                '${dives.length} Dives',
                style: const pw.TextStyle(fontSize: 24),
              ),
              pw.SizedBox(height: 10),
              if (dives.isNotEmpty) ...[
                pw.Text(
                  '${_dateFormat.format(dives.last.dateTime)} - ${_dateFormat.format(dives.first.dateTime)}',
                  style: const pw.TextStyle(fontSize: 16),
                ),
              ],
              pw.SizedBox(height: 40),
              pw.Text(
                'Generated on ${_dateTimeFormat.format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
      ),
    );

    // Summary page
    if (dives.isNotEmpty) {
      final totalDiveTime = dives
          .where((d) => d.duration != null)
          .fold<Duration>(Duration.zero, (sum, d) => sum + d.duration!);
      final maxDepth = dives
          .where((d) => d.maxDepth != null)
          .map((d) => d.maxDepth!)
          .fold<double>(0, (max, depth) => depth > max ? depth : max);
      final avgDepth = dives.where((d) => d.avgDepth != null).isEmpty
          ? 0.0
          : dives
                  .where((d) => d.avgDepth != null)
                  .map((d) => d.avgDepth!)
                  .reduce((a, b) => a + b) /
              dives.where((d) => d.avgDepth != null).length;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Summary',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              _buildPdfStatRow('Total Dives', '${dives.length}'),
              _buildPdfStatRow('Total Dive Time', '${totalDiveTime.inHours}h ${totalDiveTime.inMinutes % 60}m'),
              _buildPdfStatRow('Deepest Dive', '${maxDepth.toStringAsFixed(1)}m'),
              _buildPdfStatRow('Average Depth', '${avgDepth.toStringAsFixed(1)}m'),
              _buildPdfStatRow('Unique Sites', '${dives.map((d) => d.site?.id).where((id) => id != null).toSet().length}'),
            ],
          ),
        ),
      );
    }

    // Dive log pages (multiple dives per page)
    const divesPerPage = 3;
    for (var i = 0; i < dives.length; i += divesPerPage) {
      final pageDives = dives.skip(i).take(divesPerPage).toList();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              ...pageDives.expand((dive) => [
                _buildPdfDiveEntry(dive),
                pw.SizedBox(height: 16),
                pw.Divider(),
                pw.SizedBox(height: 16),
              ]).toList(),
            ],
          ),
        ),
      );
    }

    final pdfBytes = await pdf.save();
    final fileName = 'dive_logbook_${_dateFormat.format(DateTime.now())}.pdf';
    return _saveAndShareFileBytes(pdfBytes, fileName, 'application/pdf');
  }

  pw.Widget _buildPdfStatRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 14)),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfDiveEntry(Dive dive) {
    final tank = dive.tanks.isNotEmpty ? dive.tanks.first : null;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '#${dive.diveNumber ?? '-'} - ${dive.site?.name ?? 'Unknown Site'}',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                _dateTimeFormat.format(dive.dateTime),
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _buildPdfInfoChip('Depth', '${dive.maxDepth?.toStringAsFixed(1) ?? '-'}m'),
              pw.SizedBox(width: 16),
              _buildPdfInfoChip('Duration', '${dive.duration?.inMinutes ?? '-'} min'),
              pw.SizedBox(width: 16),
              _buildPdfInfoChip('Temp', '${dive.waterTemp?.toStringAsFixed(0) ?? '-'}°C'),
              if (tank != null) ...[
                pw.SizedBox(width: 16),
                _buildPdfInfoChip('Air', '${tank.startPressure ?? '-'} → ${tank.endPressure ?? '-'} bar'),
              ],
            ],
          ),
          if (dive.notes.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              dive.notes,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              maxLines: 2,
            ),
          ],
          if (dive.rating != null && dive.rating! > 0) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              '${'★' * dive.rating!}${'☆' * (5 - dive.rating!)}',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.amber),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildPdfInfoChip(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  // ==================== UDDF EXPORT ====================

  /// Export dives to UDDF format (Universal Dive Data Format)
  Future<String> exportDivesToUddf(List<Dive> dives, {List<DiveSite>? sites}) async {
    final builder = XmlBuilder();

    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('uddf', attributes: {
      'version': '3.2.0',
      'xmlns': 'http://www.streit.cc/uddf/3.2/',
    }, nest: () {
      // Generator info
      builder.element('generator', nest: () {
        builder.element('name', nest: 'Submersion');
        builder.element('version', nest: '0.1.0');
        builder.element('datetime', nest: DateTime.now().toIso8601String());
        builder.element('manufacturer', nest: () {
          builder.element('name', nest: 'Submersion App');
        });
      });

      // Dive sites
      if (sites != null || dives.any((d) => d.site != null)) {
        builder.element('divesite', nest: () {
          final allSites = sites ?? dives.map((d) => d.site).whereType<DiveSite>().toSet().toList();
          for (final site in allSites) {
            builder.element('site', attributes: {'id': 'site_${site.id}'}, nest: () {
              builder.element('name', nest: site.name);
              if (site.location != null) {
                builder.element('geography', nest: () {
                  builder.element('latitude', nest: site.location!.latitude.toString());
                  builder.element('longitude', nest: site.location!.longitude.toString());
                });
              }
              if (site.country != null) {
                builder.element('country', nest: site.country);
              }
              if (site.region != null) {
                builder.element('state', nest: site.region);
              }
              if (site.maxDepth != null) {
                builder.element('maximumdepth', nest: site.maxDepth.toString());
              }
              if (site.description.isNotEmpty) {
                builder.element('notes', nest: site.description);
              }
            });
          }
        });
      }

      // Gas definitions
      builder.element('gasdefinitions', nest: () {
        // Collect all unique gas mixes from dives
        final gasMixes = <String, GasMix>{};
        for (final dive in dives) {
          for (final tank in dive.tanks) {
            final key = 'mix_${tank.gasMix.o2.toInt()}_${tank.gasMix.he.toInt()}';
            gasMixes[key] = tank.gasMix;
          }
        }
        // Add air as default
        gasMixes['mix_21_0'] = const GasMix();

        for (final entry in gasMixes.entries) {
          builder.element('mix', attributes: {'id': entry.key}, nest: () {
            builder.element('name', nest: entry.value.name);
            builder.element('o2', nest: (entry.value.o2 / 100).toString());
            builder.element('n2', nest: (entry.value.n2 / 100).toString());
            builder.element('he', nest: (entry.value.he / 100).toString());
          });
        }
      });

      // Profile data (repetition groups and dives)
      builder.element('profiledata', nest: () {
        // Group dives by date for repetition groups
        final divesByDate = <String, List<Dive>>{};
        for (final dive in dives) {
          final dateKey = _dateFormat.format(dive.dateTime);
          divesByDate.putIfAbsent(dateKey, () => []);
          divesByDate[dateKey]!.add(dive);
        }

        for (final dateEntry in divesByDate.entries) {
          builder.element('repetitiongroup', nest: () {
            for (final dive in dateEntry.value) {
              builder.element('dive', attributes: {'id': 'dive_${dive.id}'}, nest: () {
                builder.element('informationbeforedive', nest: () {
                  builder.element('datetime', nest: dive.dateTime.toIso8601String());
                  if (dive.diveNumber != null) {
                    builder.element('divenumber', nest: dive.diveNumber.toString());
                  }
                  if (dive.airTemp != null) {
                    builder.element('airtemperature', nest: (dive.airTemp! + 273.15).toString()); // Kelvin
                  }
                  if (dive.site != null) {
                    builder.element('link', attributes: {'ref': 'site_${dive.site!.id}'});
                  }
                });

                // Samples (dive profile)
                builder.element('samples', nest: () {
                  final tank = dive.tanks.isNotEmpty ? dive.tanks.first : null;
                  final mixId = tank != null
                      ? 'mix_${tank.gasMix.o2.toInt()}_${tank.gasMix.he.toInt()}'
                      : 'mix_21_0';

                  // Add tank switch at start
                  builder.element('waypoint', nest: () {
                    builder.element('divetime', nest: '0');
                    builder.element('depth', nest: '0');
                    builder.element('switchmix', attributes: {'ref': mixId});
                  });

                  if (dive.profile.isNotEmpty) {
                    // Use actual profile data
                    for (final point in dive.profile) {
                      builder.element('waypoint', nest: () {
                        builder.element('divetime', nest: point.timestamp.toString());
                        builder.element('depth', nest: point.depth.toString());
                        if (point.temperature != null) {
                          builder.element('temperature', nest: (point.temperature! + 273.15).toString()); // Kelvin
                        }
                        if (point.pressure != null) {
                          builder.element('tankpressure', nest: (point.pressure! * 100000).toString()); // Pascal
                        }
                      });
                    }
                  } else {
                    // Generate basic profile from dive data
                    final durationSecs = dive.duration?.inSeconds ?? 0;
                    if (dive.maxDepth != null && durationSecs > 0) {
                      // Descent to max depth (assume 1/5 of dive)
                      final descentTime = (durationSecs * 0.2).toInt();
                      builder.element('waypoint', nest: () {
                        builder.element('divetime', nest: descentTime.toString());
                        builder.element('depth', nest: dive.maxDepth.toString());
                        if (dive.waterTemp != null) {
                          builder.element('temperature', nest: (dive.waterTemp! + 273.15).toString());
                        }
                      });

                      // Bottom time at avg depth (3/5 of dive)
                      final bottomTime = (durationSecs * 0.8).toInt();
                      builder.element('waypoint', nest: () {
                        builder.element('divetime', nest: bottomTime.toString());
                        builder.element('depth', nest: (dive.avgDepth ?? dive.maxDepth! * 0.7).toString());
                      });

                      // Ascent to surface
                      builder.element('waypoint', nest: () {
                        builder.element('divetime', nest: durationSecs.toString());
                        builder.element('depth', nest: '0');
                      });
                    }
                  }
                });

                builder.element('informationafterdive', nest: () {
                  if (dive.maxDepth != null) {
                    builder.element('greatestdepth', nest: dive.maxDepth.toString());
                  }
                  if (dive.avgDepth != null) {
                    builder.element('averagedepth', nest: dive.avgDepth.toString());
                  }
                  if (dive.duration != null) {
                    builder.element('diveduration', nest: dive.duration!.inSeconds.toString());
                  }
                  if (dive.waterTemp != null) {
                    builder.element('lowesttemperature', nest: (dive.waterTemp! + 273.15).toString()); // Kelvin
                  }
                  if (dive.visibility != null) {
                    builder.element('visibility', nest: _visibilityToUddf(dive.visibility!));
                  }
                  if (dive.rating != null) {
                    builder.element('rating', nest: () {
                      builder.element('ratingvalue', nest: dive.rating.toString());
                    });
                  }
                  if (dive.notes.isNotEmpty) {
                    builder.element('notes', nest: () {
                      builder.element('para', nest: dive.notes);
                    });
                  }
                  if (dive.buddy != null && dive.buddy!.isNotEmpty) {
                    builder.element('buddy', nest: () {
                      builder.element('personal', nest: () {
                        builder.element('firstname', nest: dive.buddy);
                      });
                    });
                  }
                });
              });
            }
          });
        }
      });
    });

    final xmlDoc = builder.buildDocument();
    final xmlString = xmlDoc.toXmlString(pretty: true, indent: '  ');
    final fileName = 'dives_export_${_dateFormat.format(DateTime.now())}.uddf';
    return _saveAndShareFile(xmlString, fileName, 'application/xml');
  }

  String _visibilityToUddf(enums.Visibility visibility) {
    switch (visibility) {
      case enums.Visibility.excellent:
        return '30'; // meters
      case enums.Visibility.good:
        return '20';
      case enums.Visibility.moderate:
        return '10';
      case enums.Visibility.poor:
        return '5';
      case enums.Visibility.unknown:
        return '0';
    }
  }

  // ==================== UDDF IMPORT ====================

  /// Result class for UDDF import containing both dives and sites
  /// Import dives from UDDF file
  /// Returns a map with 'dives' and 'sites' lists
  Future<Map<String, List<Map<String, dynamic>>>> importDivesFromUddf(String uddfContent) async {
    final document = XmlDocument.parse(uddfContent);
    final uddfElement = document.findElements('uddf').firstOrNull;
    if (uddfElement == null) {
      throw const FormatException('Invalid UDDF file: missing uddf root element');
    }

    // Parse buddies from diver section
    final buddies = <String, Map<String, dynamic>>{};
    final diverElement = uddfElement.findElements('diver').firstOrNull;
    if (diverElement != null) {
      for (final buddyElement in diverElement.findElements('buddy')) {
        final buddyId = buddyElement.getAttribute('id');
        if (buddyId != null) {
          final personalElement = buddyElement.findElements('personal').firstOrNull;
          if (personalElement != null) {
            final firstName = _getElementText(personalElement, 'firstname');
            final lastName = _getElementText(personalElement, 'lastname');
            final buddyName = [firstName, lastName].whereType<String>().where((s) => s.isNotEmpty).join(' ').trim();
            if (buddyName.isNotEmpty) {
              buddies[buddyId] = {'name': buddyName};
            }
          }
        }
      }
    }

    // Parse dive sites
    final sites = <String, Map<String, dynamic>>{};
    final divesiteElement = uddfElement.findElements('divesite').firstOrNull;
    if (divesiteElement != null) {
      for (final siteElement in divesiteElement.findElements('site')) {
        final siteId = siteElement.getAttribute('id');
        if (siteId != null) {
          final siteData = _parseUddfSite(siteElement);
          siteData['uddfId'] = siteId; // Keep track of original ID for linking
          sites[siteId] = siteData;
        }
      }
    }

    // Parse gas definitions
    final gasMixes = <String, GasMix>{};
    final gasDefsElement = uddfElement.findElements('gasdefinitions').firstOrNull;
    if (gasDefsElement != null) {
      for (final mixElement in gasDefsElement.findElements('mix')) {
        final mixId = mixElement.getAttribute('id');
        if (mixId != null) {
          gasMixes[mixId] = _parseUddfGasMix(mixElement);
        }
      }
    }

    // Parse dives from profile data
    final dives = <Map<String, dynamic>>[];
    final profileDataElement = uddfElement.findElements('profiledata').firstOrNull;
    if (profileDataElement != null) {
      for (final repGroup in profileDataElement.findElements('repetitiongroup')) {
        for (final diveElement in repGroup.findElements('dive')) {
          final diveData = _parseUddfDive(diveElement, sites, buddies, gasMixes);
          if (diveData.isNotEmpty) {
            dives.add(diveData);
          }
        }
      }
    }

    // Return both dives and unique sites
    return {
      'dives': dives,
      'sites': sites.values.toList(),
    };
  }

  Map<String, dynamic> _parseUddfSite(XmlElement siteElement) {
    final site = <String, dynamic>{};

    site['name'] = _getElementText(siteElement, 'name');

    final geoElement = siteElement.findElements('geography').firstOrNull;
    if (geoElement != null) {
      final lat = _getElementText(geoElement, 'latitude');
      final lon = _getElementText(geoElement, 'longitude');
      if (lat != null && lon != null) {
        site['latitude'] = double.tryParse(lat);
        site['longitude'] = double.tryParse(lon);
      }
    }

    site['country'] = _getElementText(siteElement, 'country');
    site['region'] = _getElementText(siteElement, 'state');
    final maxDepth = _getElementText(siteElement, 'maximumdepth');
    if (maxDepth != null) {
      site['maxDepth'] = double.tryParse(maxDepth);
    }
    site['description'] = _getElementText(siteElement, 'notes');

    return site;
  }

  GasMix _parseUddfGasMix(XmlElement mixElement) {
    final o2Text = _getElementText(mixElement, 'o2');
    final heText = _getElementText(mixElement, 'he');

    // UDDF stores as fractions (0.21 for 21%)
    final o2 = o2Text != null ? (double.tryParse(o2Text) ?? 0.21) * 100 : 21.0;
    final he = heText != null ? (double.tryParse(heText) ?? 0.0) * 100 : 0.0;

    return GasMix(o2: o2, he: he);
  }

  Map<String, dynamic> _parseUddfDive(
    XmlElement diveElement,
    Map<String, Map<String, dynamic>> sites,
    Map<String, Map<String, dynamic>> buddies,
    Map<String, GasMix> gasMixes,
  ) {
    final diveData = <String, dynamic>{};
    final buddyNames = <String>[];

    // Parse information before dive
    final beforeElement = diveElement.findElements('informationbeforedive').firstOrNull;
    if (beforeElement != null) {
      final dateTimeText = _getElementText(beforeElement, 'datetime');
      if (dateTimeText != null) {
        diveData['dateTime'] = DateTime.tryParse(dateTimeText);
      }

      final diveNumText = _getElementText(beforeElement, 'divenumber');
      if (diveNumText != null) {
        diveData['diveNumber'] = int.tryParse(diveNumText);
      }

      final airTempText = _getElementText(beforeElement, 'airtemperature');
      if (airTempText != null) {
        // UDDF stores temps in Kelvin
        final kelvin = double.tryParse(airTempText);
        if (kelvin != null) {
          diveData['airTemp'] = kelvin - 273.15;
        }
      }

      // Parse equipment used (e.g., lead weight)
      final equipmentElement = beforeElement.findElements('equipmentused').firstOrNull;
      if (equipmentElement != null) {
        final leadText = _getElementText(equipmentElement, 'leadquantity');
        if (leadText != null) {
          final leadKg = double.tryParse(leadText);
          if (leadKg != null) {
            diveData['weightUsed'] = leadKg;
          }
        }
      }

      // Get all linked references (can be sites or buddies)
      for (final linkElement in beforeElement.findElements('link')) {
        final ref = linkElement.getAttribute('ref');
        if (ref != null) {
          // Check if it's a site reference
          if (sites.containsKey(ref)) {
            diveData['site'] = sites[ref];
          }
          // Check if it's a buddy reference
          else if (buddies.containsKey(ref)) {
            final buddyName = buddies[ref]?['name'] as String?;
            if (buddyName != null && buddyName.isNotEmpty) {
              buddyNames.add(buddyName);
            }
          }
        }
      }
    }

    // Parse tank data
    final tanks = <Map<String, dynamic>>[];
    for (final tankDataElement in diveElement.findElements('tankdata')) {
      final tankInfo = <String, dynamic>{};

      // Get tank volume (in liters)
      final volumeText = _getElementText(tankDataElement, 'tankvolume');
      if (volumeText != null) {
        tankInfo['volume'] = double.tryParse(volumeText);
      }

      // Get linked gas mix
      final mixLink = tankDataElement.findElements('link').firstOrNull;
      if (mixLink != null) {
        final mixRef = mixLink.getAttribute('ref');
        if (mixRef != null && gasMixes.containsKey(mixRef)) {
          tankInfo['gasMix'] = gasMixes[mixRef];
        }
      }

      // Get start/end pressure if available
      final startPressureText = _getElementText(tankDataElement, 'tankpressurebegin');
      if (startPressureText != null) {
        // UDDF stores in Pascal, convert to bar
        final pascal = double.tryParse(startPressureText);
        if (pascal != null) {
          tankInfo['startPressure'] = (pascal / 100000).round();
        }
      }

      final endPressureText = _getElementText(tankDataElement, 'tankpressureend');
      if (endPressureText != null) {
        final pascal = double.tryParse(endPressureText);
        if (pascal != null) {
          tankInfo['endPressure'] = (pascal / 100000).round();
        }
      }

      // Only add tank if it has meaningful data
      if (tankInfo['volume'] != null || tankInfo['gasMix'] != null) {
        tanks.add(tankInfo);
      }
    }

    if (tanks.isNotEmpty) {
      diveData['tanks'] = tanks;
    }

    // Parse samples (dive profile)
    final samplesElement = diveElement.findElements('samples').firstOrNull;
    if (samplesElement != null) {
      final profile = <Map<String, dynamic>>[];
      GasMix? currentMix;

      for (final waypoint in samplesElement.findElements('waypoint')) {
        final point = <String, dynamic>{};

        final timeText = _getElementText(waypoint, 'divetime');
        if (timeText != null) {
          point['timestamp'] = int.tryParse(timeText) ?? 0;
        }

        final depthText = _getElementText(waypoint, 'depth');
        if (depthText != null) {
          point['depth'] = double.tryParse(depthText) ?? 0.0;
        }

        final tempText = _getElementText(waypoint, 'temperature');
        if (tempText != null) {
          final kelvin = double.tryParse(tempText);
          if (kelvin != null) {
            point['temperature'] = kelvin - 273.15;
          }
        }

        final pressureText = _getElementText(waypoint, 'tankpressure');
        if (pressureText != null) {
          // UDDF stores pressure in Pascal, convert to bar
          final pascal = double.tryParse(pressureText);
          if (pascal != null) {
            point['pressure'] = pascal / 100000;
          }
        }

        // Check for gas switch
        final switchMix = waypoint.findElements('switchmix').firstOrNull;
        if (switchMix != null) {
          final mixRef = switchMix.getAttribute('ref');
          if (mixRef != null && gasMixes.containsKey(mixRef)) {
            currentMix = gasMixes[mixRef];
          }
        }

        if (point.containsKey('timestamp') && point.containsKey('depth')) {
          profile.add(point);
        }
      }

      if (profile.isNotEmpty) {
        diveData['profile'] = profile;
      }
      // Use gas mix from samples if no tank data was found
      if (currentMix != null && !diveData.containsKey('tanks')) {
        diveData['gasMix'] = currentMix;
      }
    }

    // Parse information after dive
    final afterElement = diveElement.findElements('informationafterdive').firstOrNull;
    if (afterElement != null) {
      final maxDepthText = _getElementText(afterElement, 'greatestdepth');
      if (maxDepthText != null) {
        diveData['maxDepth'] = double.tryParse(maxDepthText);
      }

      final avgDepthText = _getElementText(afterElement, 'averagedepth');
      if (avgDepthText != null) {
        diveData['avgDepth'] = double.tryParse(avgDepthText);
      }

      final durationText = _getElementText(afterElement, 'diveduration');
      if (durationText != null) {
        final seconds = int.tryParse(durationText);
        if (seconds != null) {
          diveData['duration'] = Duration(seconds: seconds);
        }
      }

      final waterTempText = _getElementText(afterElement, 'lowesttemperature');
      if (waterTempText != null) {
        final kelvin = double.tryParse(waterTempText);
        if (kelvin != null) {
          diveData['waterTemp'] = kelvin - 273.15;
        }
      }

      final visibilityText = _getElementText(afterElement, 'visibility');
      if (visibilityText != null) {
        diveData['visibility'] = _parseUddfVisibility(visibilityText);
      }

      // Parse rating
      final ratingElement = afterElement.findElements('rating').firstOrNull;
      if (ratingElement != null) {
        final ratingValue = _getElementText(ratingElement, 'ratingvalue');
        if (ratingValue != null) {
          diveData['rating'] = int.tryParse(ratingValue);
        }
      }

      // Parse notes
      final notesElement = afterElement.findElements('notes').firstOrNull;
      if (notesElement != null) {
        final para = _getElementText(notesElement, 'para');
        if (para != null) {
          diveData['notes'] = para;
        }
      }

      // Parse buddy from informationafterdive (backup if not found in links)
      if (buddyNames.isEmpty) {
        final buddyElement = afterElement.findElements('buddy').firstOrNull;
        if (buddyElement != null) {
          final personalElement = buddyElement.findElements('personal').firstOrNull;
          if (personalElement != null) {
            final firstName = _getElementText(personalElement, 'firstname');
            final lastName = _getElementText(personalElement, 'lastname');
            final buddyName = [firstName, lastName].whereType<String>().where((s) => s.isNotEmpty).join(' ').trim();
            if (buddyName.isNotEmpty) {
              buddyNames.add(buddyName);
            }
          }
        }
      }
    }

    // Set buddy names (join multiple buddies with comma)
    if (buddyNames.isNotEmpty) {
      diveData['buddy'] = buddyNames.join(', ');
    }

    return diveData;
  }

  enums.Visibility _parseUddfVisibility(String value) {
    final meters = double.tryParse(value) ?? 0;
    if (meters >= 30) {
      return enums.Visibility.excellent;
    } else if (meters >= 15) {
      return enums.Visibility.good;
    } else if (meters >= 5) {
      return enums.Visibility.moderate;
    } else if (meters > 0) {
      return enums.Visibility.poor;
    }
    return enums.Visibility.unknown;
  }

  String? _getElementText(XmlElement parent, String elementName) {
    final element = parent.findElements(elementName).firstOrNull;
    return element?.innerText.trim().isEmpty == true ? null : element?.innerText.trim();
  }

  // ==================== CSV IMPORT ====================

  /// Import dives from CSV file
  /// Returns a list of imported Dive objects (without IDs - caller must assign)
  Future<List<Map<String, dynamic>>> importDivesFromCsv(String csvContent) async {
    final rows = const CsvToListConverter().convert(csvContent);
    if (rows.isEmpty) {
      throw FormatException('CSV file is empty');
    }

    final headers = rows.first.map((e) => e.toString().toLowerCase().trim()).toList();
    final dataRows = rows.skip(1);

    final dives = <Map<String, dynamic>>[];

    for (final row in dataRows) {
      if (row.isEmpty || row.every((cell) => cell == null || cell.toString().isEmpty)) {
        continue; // Skip empty rows
      }

      final diveData = <String, dynamic>{};

      // Map CSV columns to dive fields
      for (var i = 0; i < headers.length && i < row.length; i++) {
        final header = headers[i];
        final value = row[i]?.toString().trim() ?? '';

        if (value.isEmpty) continue;

        // Parse based on header name
        if (header.contains('dive') && header.contains('number')) {
          diveData['diveNumber'] = int.tryParse(value);
        } else if (header == 'date' || header.contains('date') && !header.contains('time')) {
          diveData['date'] = _parseDate(value);
        } else if (header == 'time' || header.contains('time') && !header.contains('date')) {
          diveData['time'] = _parseTime(value);
        } else if (header.contains('max') && header.contains('depth')) {
          diveData['maxDepth'] = _parseDouble(value);
        } else if (header.contains('avg') && header.contains('depth')) {
          diveData['avgDepth'] = _parseDouble(value);
        } else if (header.contains('duration') || header.contains('time') && header.contains('min')) {
          diveData['duration'] = _parseDuration(value);
        } else if (header.contains('water') && header.contains('temp')) {
          diveData['waterTemp'] = _parseDouble(value);
        } else if (header.contains('air') && header.contains('temp')) {
          diveData['airTemp'] = _parseDouble(value);
        } else if (header.contains('site') || header.contains('location')) {
          diveData['siteName'] = value;
        } else if (header.contains('buddy')) {
          diveData['buddy'] = value;
        } else if (header.contains('dive') && header.contains('master')) {
          diveData['diveMaster'] = value;
        } else if (header.contains('rating')) {
          diveData['rating'] = int.tryParse(value);
        } else if (header.contains('note')) {
          diveData['notes'] = value;
        } else if (header.contains('visibility')) {
          diveData['visibility'] = _parseVisibility(value);
        } else if (header.contains('type')) {
          diveData['diveType'] = _parseDiveType(value);
        } else if (header.contains('start') && header.contains('pressure')) {
          diveData['startPressure'] = int.tryParse(value);
        } else if (header.contains('end') && header.contains('pressure')) {
          diveData['endPressure'] = int.tryParse(value);
        } else if (header.contains('tank') && header.contains('volume')) {
          diveData['tankVolume'] = _parseDouble(value);
        } else if (header.contains('o2') || header.contains('oxygen')) {
          diveData['o2Percent'] = _parseDouble(value);
        }
      }

      // Combine date and time if both present
      if (diveData['date'] != null) {
        DateTime dateTime = diveData['date'] as DateTime;
        if (diveData['time'] != null) {
          final time = diveData['time'] as DateTime;
          dateTime = DateTime(
            dateTime.year,
            dateTime.month,
            dateTime.day,
            time.hour,
            time.minute,
          );
        }
        diveData['dateTime'] = dateTime;
        diveData.remove('date');
        diveData.remove('time');
      }

      if (diveData.isNotEmpty) {
        dives.add(diveData);
      }
    }

    return dives;
  }

  DateTime? _parseDate(String value) {
    // Try common date formats
    final formats = [
      'yyyy-MM-dd',
      'MM/dd/yyyy',
      'dd/MM/yyyy',
      'yyyy/MM/dd',
      'dd-MM-yyyy',
      'MM-dd-yyyy',
    ];

    for (final format in formats) {
      try {
        return DateFormat(format).parse(value);
      } catch (_) {
        continue;
      }
    }

    return DateTime.tryParse(value);
  }

  DateTime? _parseTime(String value) {
    final formats = ['HH:mm', 'H:mm', 'hh:mm a', 'h:mm a'];

    for (final format in formats) {
      try {
        return DateFormat(format).parse(value);
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  double? _parseDouble(String value) {
    // Remove units like 'm', 'ft', '°C', '°F', 'bar', 'psi'
    final cleanValue = value.replaceAll(RegExp(r'[^\d.-]'), '');
    return double.tryParse(cleanValue);
  }

  Duration? _parseDuration(String value) {
    // Try to parse as minutes
    final minutes = int.tryParse(value.replaceAll(RegExp(r'[^\d]'), ''));
    if (minutes != null) {
      return Duration(minutes: minutes);
    }

    // Try to parse as HH:mm
    final parts = value.split(':');
    if (parts.length == 2) {
      final hours = int.tryParse(parts[0]);
      final mins = int.tryParse(parts[1]);
      if (hours != null && mins != null) {
        return Duration(hours: hours, minutes: mins);
      }
    }

    return null;
  }

  enums.Visibility? _parseVisibility(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('excellent') || lower.contains('>30') || lower.contains('>100')) {
      return enums.Visibility.excellent;
    } else if (lower.contains('good') || lower.contains('15-30') || lower.contains('50-100')) {
      return enums.Visibility.good;
    } else if (lower.contains('moderate') || lower.contains('fair') || lower.contains('5-15') || lower.contains('15-50')) {
      return enums.Visibility.moderate;
    } else if (lower.contains('poor') || lower.contains('<5') || lower.contains('<15')) {
      return enums.Visibility.poor;
    }
    return enums.Visibility.unknown;
  }

  DiveType _parseDiveType(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('training') || lower.contains('course')) {
      return DiveType.training;
    } else if (lower.contains('night')) {
      return DiveType.night;
    } else if (lower.contains('deep')) {
      return DiveType.deep;
    } else if (lower.contains('wreck')) {
      return DiveType.wreck;
    } else if (lower.contains('drift')) {
      return DiveType.drift;
    } else if (lower.contains('cave') || lower.contains('cavern')) {
      return DiveType.cave;
    } else if (lower.contains('tech')) {
      return DiveType.technical;
    } else if (lower.contains('free')) {
      return DiveType.freedive;
    } else if (lower.contains('ice')) {
      return DiveType.ice;
    } else if (lower.contains('altitude')) {
      return DiveType.altitude;
    } else if (lower.contains('shore')) {
      return DiveType.shore;
    } else if (lower.contains('boat')) {
      return DiveType.boat;
    } else if (lower.contains('liveaboard')) {
      return DiveType.liveaboard;
    }
    return DiveType.recreational;
  }

  // ==================== FILE UTILITIES ====================

  Future<String> _saveAndShareFile(String content, String fileName, String mimeType) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(content);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: mimeType)],
      subject: fileName,
    );

    return file.path;
  }

  Future<String> _saveAndShareFileBytes(List<int> bytes, String fileName, String mimeType) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: mimeType)],
      subject: fileName,
    );

    return file.path;
  }

  /// Get temporary file path for export
  Future<String> getExportFilePath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$fileName';
  }
}
