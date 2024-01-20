import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ProductListScreen(),
    );
  }
}

class ProductListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Productos'),
      ),
      body: ProductList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddProductScreen()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class ProductList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }
        var products = snapshot.data!.docs;
        List<Widget> productWidgets = [];
        for (var product in products) {
          var productData = product.data(); // Eliminar el cast innecesario
          productWidgets.add(
            ListTile(
              title: Text(productData['name']),
              subtitle: Text(productData['description']),
              leading: Image.network(productData['imageURL']),
            ),
          );
        }
        return ListView(
          children: productWidgets,
        );
      },
    );
  }
}


class AddProductScreen extends StatefulWidget {
  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  File? _image;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_image != null) {
      try {
        var storageRef = FirebaseStorage.instance.ref().child('product_images/${DateTime.now()}.png');
        await storageRef.putFile(_image!);
        var downloadURL = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance.collection('products').add({
          'name': _nameController.text,
          'description': _descriptionController.text,
          'imageURL': downloadURL,
        });

        Navigator.pop(context); // Regresar a la pantalla anterior
      } catch (e) {
        print('Error al subir la imagen: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Añadir Producto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Nombre del Producto'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Descripción del Producto'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Seleccionar Imagen'),
            ),
            SizedBox(height: 16.0),
            _image != null ? Image.file(_image!) : Container(),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _uploadImage,
              child: Text('Añadir Producto'),
            ),
          ],
        ),
      ),
    );
  }
}