import 'dart:async';
import 'dart:developer';
import 'package:barcode_scan2/gen/protos/protos.pb.dart';
import 'package:barcode_scan2/platform_wrapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:punctuality_drive/Modals/create_entry.dart';
import 'package:punctuality_drive/Screens/barcode_scanner.dart';
import 'package:punctuality_drive/Screens/login_screen.dart';
import 'package:punctuality_drive/services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../Constants/constants.dart';
import '../Constants/widgets.dart';
import '../Modals/student_data.dart';
import '../APIs/api.dart';
import '../main.dart';

class ScannedEntry extends StatefulWidget {
  const ScannedEntry({super.key});

  @override
  State<ScannedEntry> createState() => _ScannedEntryState();
}

class _ScannedEntryState extends State<ScannedEntry> {
  // void _dropDownCallback(String? selectedValue) {
  //   if (selectedValue is String) {
  //     setState(() {
  //       location = selectedValue;
  //     });
  //     if (kDebugMode) {
  //       print(location);
  //     }
  //   }
  // }

  bool? badRequest;

  Future<EntryModel?> lateEntry() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var headers = {
      'Authorization': 'Bearer ${prefs.getString('authTokenPrefs')}',
      'Content-Type': 'application/x-www-form-urlencoded'
    };
    var request = http.Request(
      'POST',
      Uri.parse(postApiURL),
    );
    request.bodyFields = {
      'stdNo': studentNumber.toString(),
      'location': location.toString()
    };
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      setState(
        () {
          badRequest = false;
        },
      );
      log(await response.stream.bytesToString());
      log(badRequest.toString());
    } else {
      setState(
        () {
          badRequest = true;
        },
      );

      log(response.reasonPhrase!);
      log("entry already exists");
      log(badRequest.toString());
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations(
      [
        DeviceOrientation.portraitUp,
      ],
    );
    var size = MediaQuery.of(context).size;

    var height = size.height;
    var width = size.width;
    if (kDebugMode) {
      print(height);
      print(width);
    }

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top],
    );

    Timer? _timer;

    Future<bool> shouldPop() async {
      Navigator.push(
          context, MaterialPageRoute(builder: ((context) => Scanner())));
      return true;
    }

    return WillPopScope(
      onWillPop: () async {
        return await shouldPop();
      },
      child: Scaffold(
        bottomSheet: resultFooter(),
        body: Container(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Center(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              width: double.maxFinite,
              child: Center(
                child: Material(
                  borderRadius: BorderRadius.circular(15.0),
                  elevation: 20,
                  child: Container(
                    padding:
                        const EdgeInsets.only(left: 10, right: 10, top: 10),
                    width: width,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset:
                              const Offset(0, 3), // changes position of shadow
                        ),
                      ],
                      borderRadius: BorderRadius.circular(15),
                      // border: Border.all(color: Colors.grey),
                    ),
                    child: emptyBarcode == true
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'images/Disclaimer.png',
                                      height: 200,
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(
                                          bottom: 10.0, top: 20),
                                      child: Text(
                                        "No ID card found.",
                                        style: TextStyle(fontSize: 18),
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const Scanner(),
                                    ),
                                  ),
                                  child: const Text(
                                    'SCAN AGAIN',
                                    style: TextStyle(
                                      color: Colors.blueAccent,
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          )
                        : FutureBuilder<StudentData?>(
                            future: show(studentNumber ?? "0000"),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox(
                                  height: 100,
                                  width: 100,
                                  child: Center(
                                    child: LinearProgressIndicator(
                                      backgroundColor: Colors.white,
                                    ),
                                  ),
                                );
                              } else if (snapshot.hasData) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Center(
                                      child: CircleAvatar(
                                        backgroundColor: Colors.grey,
                                        radius: 80,
                                        backgroundImage: NetworkImage(
                                          snapshot.data!.result!.img.toString(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    RichText(
                                      text: TextSpan(
                                        text: 'Student Name:  ',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                            fontSize: 20),
                                        children: [
                                          sData(snapshot.data!.result!.name
                                              .toString()),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    RichText(
                                      text: TextSpan(
                                        text: 'Student Number:  ',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                            fontSize: 20),
                                        children: [
                                          sData(
                                              "${snapshot.data!.result!.stdNo}"),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 70,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Buttons(
                                            const IconData(0xe156,
                                                fontFamily: 'MaterialIcons'),
                                            () {
                                          lateEntry().then(
                                            (error) {
                                              badRequest == false
                                                  ? showDialog(
                                                      context: context,
                                                      builder: (BuildContext
                                                          builderContext) {
                                                        _timer = Timer(
                                                          const Duration(
                                                              seconds: 1),
                                                          () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                        );
                                                        return AlertDialog(
                                                          shape:
                                                              const RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .all(
                                                              Radius.circular(
                                                                  16.0),
                                                            ),
                                                          ),
                                                          icon: Image.asset(
                                                              'images/tick.png',
                                                              height: 50.0),
                                                          title: const Text(
                                                            "Entry Status",
                                                            style: TextStyle(
                                                                fontSize: 25.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400),
                                                          ),
                                                          content: Text(
                                                              "Entry marked \nCount : ${snapshot.data!.result!.lateCount! + 1}"),
                                                        );
                                                      },
                                                    ).then(
                                                      (val) {
                                                        if (_timer!.isActive) {
                                                          _timer!.cancel();
                                                        }
                                                      },
                                                    ).then((value) =>
                                                      Navigator.pop(context))
                                                  : showDialog(
                                                      context: context,
                                                      builder: (BuildContext
                                                          builderContext) {
                                                        _timer = Timer(
                                                          const Duration(
                                                              seconds: 1),
                                                          () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                        );
                                                        return AlertDialog(
                                                          icon: Image.asset(
                                                            'images/Disclaimer.png',
                                                            height: 50.0,
                                                          ),
                                                          shape:
                                                              const RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .all(
                                                              Radius.circular(
                                                                  16.0),
                                                            ),
                                                          ),
                                                          title: const Text(
                                                              "Entry Status"),
                                                          content: const Text(
                                                              "Entry already marked"),
                                                        );
                                                      }).then((val) {
                                                      if (_timer!.isActive) {
                                                        _timer!.cancel();
                                                      }
                                                    }).then(
                                                      (value) => Navigator.pop(
                                                            context,
                                                          ));
                                            },
                                          );
                                        }, "Mark Entry", Colors.green),
                                        const SizedBox(
                                          width: 30,
                                        ),
                                        Buttons(
                                            const IconData(0xe139,
                                                fontFamily: 'MaterialIcons'),
                                            () => showDialog(
                                                    context: context,
                                                    builder: (BuildContext
                                                        builderContext) {
                                                      _timer = Timer(
                                                        const Duration(
                                                            seconds: 1),
                                                        () {
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                      );
                                                      return AlertDialog(
                                                        shape:
                                                            const RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.all(
                                                            Radius.circular(
                                                              16.0,
                                                            ),
                                                          ),
                                                        ),
                                                        icon: Image.asset(
                                                          'images/cancel.png',
                                                          height: 50.0,
                                                        ),
                                                        title: const Text(
                                                            "Entry Status"),
                                                        content: const Text(
                                                          "Entry cancelled.",
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.red),
                                                        ),
                                                      );
                                                    }).then((val) {
                                                  if (_timer!.isActive) {
                                                    _timer!.cancel();
                                                  }
                                                }).then((value) =>
                                                    Navigator.pop(context)),
                                            "Cancel",
                                            Colors.red)
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 30,
                                    ),
                                  ],
                                );
                              } else {
                                return const ScaffoldMessenger(
                                  child: Padding(
                                    padding: EdgeInsets.only(bottom: 8.0),
                                    child: Text(
                                      "Scan card again.",
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> scanBarcodeNormal() async {
    try {
      ScanResult barcodeScanRes = (await BarcodeScanner.scan()) as ScanResult;
      log(barcodeScanRes.rawContent);
      setState(
        () {
          if (barcodeScanRes.rawContent.isEmpty) {
            log(barcodeScanRes.rawContent);
            emptyBarcode = true;
          } else {
            log(barcodeScanRes.rawContent);
            emptyBarcode = false;
            studentNumber = barcodeScanRes.rawContent;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: ((context) => const ScannedEntry()),
            ),
          );
        },
      );

      if (kDebugMode) {
        log(barcodeScanRes.rawContent);
      }
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.cameraAccessDenied) {
        setState(
          () {
            error = 'The user did not grant the camera permission!';
          },
        );
      } else {
        setState(() => error = 'Unknown error: $e');
        if (kDebugMode) {
          print(studentNumber);
        }
      }
    }
  }
}