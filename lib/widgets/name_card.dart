import 'package:flutter/material.dart';

class NameCard extends StatelessWidget {
  const NameCard({
    super.key,
    required this.myText,
    required TextEditingController nameController,
  }) : _nameController = nameController;

  final String myText;
  final TextEditingController _nameController;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: <Widget>[
          Image.asset(
            "assets/bg.jpeg",
            width: 500,
          ),
          const SizedBox(
            height: 20,
          ),
          Text(
            myText,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Digite um texto",
                labelText: "Nome",
              ),
            ),
          )
        ],
      ),
    );
  }
}
