import 'dart:io';

const List<String> iconNumbering = ['one', 'two', '3', '4', '5', '6'];

var mergeFilesIntoKey = <String, List<String>>{
  'reference/transformations_demo.dart': [
    'reference/transformations_demo_board.dart',
    'reference/transformations_demo_color_picker.dart',
    'reference/transformations_demo_edit_board_point.dart',
    'reference/transformations_demo_gesture_transformable.dart',
    'reference/transformations_demo_inertial_motion.dart'
  ],
};

/// Method capitalizes the first word of a paragraph.
String toTitleCase(String str) => str
    .toLowerCase()
    .split(' ')
    .map((word) =>
word.substring(0, 1).toUpperCase() + word.substring(1, word.length))
    .join(' ');

/// Method generated the string that will be show within dartpad_metadata.yaml.
void generateDartpadMetadata(String fileDirectory, String fileName) {
  File(fileDirectory + '/dartpad_metadata.yaml').create();
  File(fileDirectory + '/dartpad_metadata.yaml').writeAsString(
      'name: ${toTitleCase(fileName.replaceAll('_', ' ')).replaceAll('Demo.dart', '')}Demonstration\n'
          'mode: flutter\n'
          'files:\n'
          '  - name: main.dart\n');
}

/// Method generates list of classes that will be the executable within the
/// runApp of each dart file.
List<String> generateExecutables() {
  /// Demos file is where all the classes are being generated.
  var demosPage = File('lib/data/demos.dart').readAsStringSync();
  RegExp exp = RegExp(r'buildRoute: \((context|_)\) =>\s*\w*\(\s*.*\s*\),');
  Iterable<RegExpMatch> matches = exp.allMatches(demosPage);

  List<String> executableClasses = List<String>();
  matches.toList().forEach((element) {
    executableClasses.add(element
        .group(0)
        .replaceAll(RegExp(r'buildRoute: \((context|_)\) =>\s*'), '')
        .replaceAll(RegExp(r'\s*'), ''));
  });

  return executableClasses;
}

/// Generates the executable for the specific file.
String generateExecutableClass(List<String> executables, String fileContent) =>
    executables.firstWhere(
            (element) => fileContent
            .contains(' ' + element.replaceAll(RegExp(r'\(\s*.*'), '')),
        orElse: () => null);

/// Generates the executable list for that specific component.
List<String> generateExecutablesForClass(
    List<String> executables, String fileContent) =>
    executables
        .where((element) => fileContent
        .contains(' ' + element.replaceAll(RegExp(r'\(\s*.*'), '')))
        .toList();

/// Replaces GalleryLocalizations Strings with English equivalent.
String replaceGalleryLocalizations(String fileContent) {
  fileContent = fileContent.replaceFirst(
      'import \'package:gallery/l10n/gallery_localizations.dart\';', '');
  RegExp galleryLocalizationRegExp =
  RegExp(r'GalleryLocalizations.of\(context\)\.\w*');
  List<String> englishEquivalent = List<String>();
  Iterable<RegExpMatch> matches =
  galleryLocalizationRegExp.allMatches(fileContent);
  matches.toList().forEach((element) {
    englishEquivalent.add(element
        .group(0)
        .replaceAll('GalleryLocalizations.of\(context\)\.', '')
        .replaceAll(',', ''));
  });

//  String variableInGalleryLocalization;
  String translationFile = File('lib/l10n/intl_en_US.xml').readAsStringSync();
  englishEquivalent.forEach((element) {
    RegExp englishLocalizationsRegExp =
    RegExp(element + r'\"s*\s*.*\s*>[\w\s]*');
    String match = englishLocalizationsRegExp
        .firstMatch(translationFile)
        .group(0)
        .replaceFirst(RegExp(element + r'\"s*\s*.*\s*>'), '');

    fileContent = fileContent.replaceFirst(
        'GalleryLocalizations.of\(context\)\.' + element, '\'$match\'');
  });

  return fileContent;
}

/// Update main file for each directory with necessary updates to make the dart
/// file an actual executable.
void updateMainFile(
    String fileContent,
    File file,
    List<String> executablesForClass,
    String fileName,
    String subDirectory,
    String from) {
  if (mergeFilesIntoKey.containsKey('$subDirectory/$fileName')) {
    mergeFiles(file, '$subDirectory/$fileName', from);
    fileContent = file.readAsStringSync();
  }

  final materialImport =
  fileContent.contains(RegExp('import \'package:flutter/material.dart\';'))
      ? ''
      : 'import \'package:flutter/material.dart\';\n';

  fileContent = replaceGalleryLocalizations(fileContent);

  if (executablesForClass.length == 1) {
    file.writeAsString(
      materialImport +
          fileContent +
          'void main() {\n'
              '\trunApp(\n'
              '\t\tMaterialApp(\n'
              '\t\t\tdebugShowCheckedModeBanner: false,\n'
              '\t\t\thome: ${executablesForClass.first}\n'
              '\t\t),\n'
              '\t);\n'
              '}\n',
    );
  } else {
    String appBarActions = '';
    for (int counter = 0; counter < executablesForClass.length; counter++) {
      appBarActions += '\t\t\t\t\t\tIconButton(\n'
          '\t\t\t\t\t\t\ticon: const Icon(Icons.looks_${iconNumbering[counter]}),\n'
          '\t\t\t\t\t\t\tonPressed: () {\n'
          '\t\t\t\t\t\t\t\tsetState(() {\n'
          '\t\t\t\t\t\t\t\t\t_body = ${executablesForClass[counter].replaceAll('),', ');')}\n'
          '\t\t\t\t\t\t\t\t});\n'
          '\t\t\t\t\t\t\t},\n'
          '\t\t\t\t\t\t),\n';
    }

    file.writeAsString('$materialImport$fileContent'
        'void main() => runApp(Example());\n\n'
        'class Example extends StatefulWidget {\n'
        '\t _ExampleState createState() => _ExampleState();\n'
        '}\n\n'
        'class _ExampleState extends State<Example> {\n'
        '\tWidget _body;\n\n'
        '\tstatic const String _title = \'${toTitleCase(fileName.replaceAll('_', ' ')).replaceAll('Demo.dart', '')}Demonstration\';\n\n'
        '\t@override\n'
        '\tvoid initState() {\n'
        '\t\tsuper.initState();\n'
        '\t\t_body = ${executablesForClass.first.replaceAll('),', ');')}\n'
        '\t}\n\n'
        '\t@override\n'
        '\tWidget build(BuildContext context) {\n'
        '\t\treturn MaterialApp(\n'
        '\t\t\ttitle: _title,\n'
        '\t\t\thome: Scaffold(\n'
        '\t\t\t\tappBar: AppBar(\n'
        '\t\t\t\t\ttitle: const Text(_title),\n'
        '\t\t\t\t\tactions: <Widget>[\n'
        '$appBarActions'
        '\t\t\t\t\t],\n'
        '\t\t\t\t),\n'
        '\t\t\t\tbody: _body,\n'
        '\t\t\t),\n'
        '\t\t);\n'
        '\t}\n'
        '}\n');
  }
}

Future<Null> createDartpadFolder(String from, String to) async {
  List<String> executables = generateExecutables();

  await for (final file in Directory(from).list(recursive: true)) {
    String subDirectory = file.path
        .replaceAll('lib/demos/', '')
        .replaceAll(RegExp(r'/\w*.dart'), '');
    final copyTo = (to + file.path.toString()).replaceAll(from, '');

    if (file is Directory) {
      await Directory(copyTo).create(recursive: true);
    } else {
      final fileName = file.path.split('/').last;
      final fileDirectory = copyTo.replaceAll('.dart', '');

      /// Edge case for reference.transformations_demo
      if (file.path.contains(RegExp(r'transformations_demo_.*'))) {
        await Directory(to + 'reference/transformations_demo').create();
        File(file.path)
            .copySync(to + 'reference/transformations_demo/' + fileName);
      } else {
        await Directory(fileDirectory).create(recursive: true);
        await File(file.path).copy(fileDirectory + '/main.dart').then((file) {
          var fileContent = file.readAsStringSync();
          final executablesForClass =
          generateExecutablesForClass(executables, fileContent);
          updateMainFile(fileContent, file, executablesForClass, fileName,
              subDirectory, from);
        });

        // Generate dartpad_metadata for each file
        generateDartpadMetadata(fileDirectory, fileName);

      }
    }
  }

  removeMergeFileValues(to);
}

void removeMergeFileValues(String to) {
//  bool shouldRemove = false;
  List<String> fileNames = [];
  mergeFilesIntoKey.values.forEach((elements) => elements.forEach((element) => fileNames.add(element.replaceAll(RegExp(r'\w*\/'), ''))));

  Directory(to).listSync(recursive: true).forEach((files) {
    fileNames.forEach((element) {
      if (files.path.contains(element)) {
        files.deleteSync();
      }
    });
  });
}


/// Combines a bunch of different files into one. This uses [mergeFilesIntoKey]
/// to see what files should be merged together.
void mergeFiles(File file, String key, String from) {
  String fileContent = file.readAsStringSync();
  fileContent = file.readAsStringSync();
  List<String> fileNames = [];

  // Check if value exist if it does add to main file.
  mergeFilesIntoKey[key].forEach((element) {
    String completePath = from + element;
    if (!File(completePath).existsSync()) {
      print('$element does not exist');
    } else {
      fileNames.add(element.replaceAll(RegExp(r'\w*\/'), ''));
      fileContent += '\n\n${File(completePath).readAsStringSync()}';
    }
  });

  List<String> allImports = [];
  RegExp(r'import .*').allMatches(fileContent).forEach((element) {
    allImports.add(element[0]);
  });
  fileContent = fileContent.replaceAll(RegExp(r'import .*'), '');

  fileNames.forEach((value) => allImports.removeWhere((element) => element.contains(value)));

  file.writeAsStringSync(removeDuplicates(allImports).join('\n')+ fileContent);
}

List<String> removeDuplicates(List<String> list) {
  return list.toSet().toList();
}

void main(List<String> arguments) {
  Directory('dartpad').create();
  createDartpadFolder('lib/demos/', 'dartpad/');
}