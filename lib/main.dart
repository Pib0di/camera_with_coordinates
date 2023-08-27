import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

late List<CameraDescription> _cameras;

Future<void> main() async {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
  WidgetsFlutterBinding.ensureInitialized();

  _cameras = await availableCameras();
  runApp(const CameraApp());
}


Future<void> sendImageAndData(String comment, LocationData locationData, String filePath) async {
  print('comment => $comment');
  print('latitude => ${locationData.latitude}');
  print('longitude => ${locationData.longitude}');
  print('filePath => $filePath');

  const url = 'https://flutter-sandbox.free.beeceptor.com/upload_photo/';

  var request = http.MultipartRequest('POST', Uri.parse(url));

  request.fields['comment'] = comment;
  request.fields['latitude'] = locationData.latitude.toString();
  request.fields['longitude'] = locationData.longitude.toString();

  final file = await http.MultipartFile.fromPath('photo', filePath);
  request.files.add(file);

  var response = await request.send();

  if (response.statusCode == 200) {
    print('Запрос выполнен успешно');
  } else {
    print('Ошибка выполнения запроса: ${response.statusCode}');
  }
}

class CameraApp extends StatefulWidget {
  const CameraApp({super.key});

  @override
  State<CameraApp> createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  late CameraController cameraController;
  late Location location;
  late TextEditingController textController;

  @override
  void initState() {
    super.initState();
    location = Location();
    textController = TextEditingController();
    cameraController = CameraController(_cameras[0], ResolutionPreset.max);
    cameraController.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors here.
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    LocationData locationData;
    if (!cameraController.value.isInitialized) {
      return Container();
    }
    return MaterialApp(
      home: Column(
        children: [
          const SizedBox(height: 50,),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            child: Material(
              color: Colors.white,
              child: TextFormField(
                controller: textController,
                decoration: const InputDecoration(
                  labelText: 'Enter your phrase to send',
                ),
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
              bool horizontal = true;
              if (constraints.maxWidth < constraints.maxHeight) {
                horizontal = false;
              }
              return Stack(
                children: [
                  Container(
                    color: Colors.black,
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: EdgeInsets.only(
                          top: 16,
                          bottom: 16,
                          right: horizontal == true ? 88 : 0,
                          left: horizontal == true ? 88 : 0),
                      child: CameraPreview(cameraController),
                    ),
                  ),

                  Align(
                    alignment: horizontal == true
                        ? Alignment.centerRight
                        : Alignment.bottomCenter,
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical:  16),
                      child: ElevatedButton(
                        onPressed: () async {
                          XFile picture = await cameraController.takePicture();
                          locationData = await location.getLocation();
                          String comment = textController.text;
                          sendImageAndData(comment, locationData, picture.path);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          fixedSize: const Size(70, 70),
                          shape: const CircleBorder(),
                          side: const BorderSide(color: Colors.grey, width: 6),
                        ),
                        child: const Text(''),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}


