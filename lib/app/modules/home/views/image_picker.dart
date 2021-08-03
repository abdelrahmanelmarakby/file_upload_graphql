import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http_parser/http_parser.dart';
import 'package:multi_image_picker2/multi_image_picker2.dart';

class EditImage extends StatefulWidget {
  EditImage({Key? key}) : super(key: key);

  @override
  _EditImageState createState() => _EditImageState();
}

List<http.MultipartFile> imagestoEdit = <http.MultipartFile>[];

class _EditImageState extends State<EditImage> {
  List<Asset> images = [];

  Widget buildGridView() {
    return GridViewBuilder(images: images);
  }

  List<Asset> resultList = <Asset>[];
  String error = 'No Image Is Selected';
  Future<void> loadAssets() async {
    try {
      resultList = await MultiImagePicker.pickImages(
        maxImages: 12,
        enableCamera: true,
        selectedAssets: images,
        cupertinoOptions: CupertinoOptions(
          takePhotoIcon: "chat",
          doneButtonTitle: "Fatto",
          autoCloseOnSelectionLimit: true,
        ),
        materialOptions: MaterialOptions(
            actionBarColor: "#000000",
            statusBarColor: "#000000",
            autoCloseOnSelectionLimit: true,
            actionBarTitle: "عقارتكم",
            allViewTitle: "All Photos",
            useDetailsView: true,
            selectCircleStrokeColor: "#000000",
            textOnNothingSelected: "0 Selected"),
      );
    } on Exception catch (e) {
      error = e.toString();
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      images = resultList;
      error = error;
    });
  }

//ADD IMAGEs AND UPLOAD IT

  @override
  Widget build(BuildContext context) {
    return Mutation(
      options: MutationOptions(

//ADD GRAPHQL MUTATION
          document: gql(r"""
mutation UpdateImage($image:Upload,$id:Int!) {
  updateProperty(data: {id: $id,image:$image}) {
    image
  }
}
""")),
      builder: (RunMutation runMutation, result) => Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(),
              Center(child: Text('State: $error')),
              ElevatedButton(
                child: Text("Pick images"),
                onPressed: loadAssets,
              ),
              Expanded(
                flex: 5,
                child: buildGridView(),
              ),
              ElevatedButton(
                child: Text("Upload images"),
                onPressed: () async {
                  //ADD IMAGEs
                  if (images.isEmpty || images[0] != null) {
                    for (int i = 0; i < images.length; i++) {
                      ByteData byteData = await images[i].getByteData();
                      List<int> imageData = byteData.buffer.asUint8List();
/////
                      http.MultipartFile multipartFile =
                          http.MultipartFile.fromBytes('image', imageData,
                              filename: images[i].name,
                              contentType: MediaType('image', 'jpg'));
                      imagestoEdit.add(multipartFile);
                      print(imagestoEdit.length);
                    }
                  }
                  //UPLOAD IMAGEs
                  try {
                    runMutation({"id": 95, "image": imagestoEdit[0]});
                  } catch (e) {
                    print(e.toString());
                  }
                  print(result!.toString());
                },
              ),
              const Spacer()
            ],
          ),
        ),
      ),
    );
  }
}

class GridViewBuilder extends StatelessWidget {
  const GridViewBuilder({
    Key? key,
    required this.images,
  }) : super(key: key);

  final List<Asset> images;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: List.generate(images.length, (index) {
        Asset asset = images[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AssetThumb(
            asset: asset,
            width: 600,
            height: 600,
          ),
        );
      }),
    );
  }
}
