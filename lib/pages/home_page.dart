// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {

  static const String routeName = "/home";
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  // Text fields setup variables
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  String? selectedType;
  final List<String> typeOptions = ['Entrada', 'Saída'];
  final TextEditingController _valueController = TextEditingController();

  // Hive related setup 
  late Map<int, String> eventsMap = {};
  List<Map<String, dynamic>> _events = [];
  var eventsList = [];
  final _eventsBox = Hive.box("events_box");

  // Date setup variables
  late DateTime currentDate;  
  late int year;
  late int month;
  late int day;
  late String formattedDate;

  // Layout setup variables
  final defaultIconTheme = const IconThemeData(color: Colors.white);
  final positiveBalanceBackground = Colors.blue.shade100;
  final negativeBalanceBackground = Colors.red.shade100;
  final primaryButton = Colors.black;
  final primaryBackground = Colors.white;
  final cardGreen = Colors.green.shade100;
  final cardRed = Colors.yellow.shade100;

  int _deletedItemCount = 0;
  Timer? _messageTimer;

  // App programming logic STARTS here
  @override
  void initState() {
    super.initState();
    // Date setup
    currentDate = DateTime.now(); // Gets the current date
    year = currentDate.year; // Gets the current date's year
    month = currentDate.month; // Gets the current date's month
    day = currentDate.day; // Gets the current date's day
    formattedDate = DateFormat('dd/MM/yyyy').format(currentDate); // formats the date 

    print("Today's date is $formattedDate.");
    _refreshItems();
  }

  // Updates the screen when a new event is added
  void _refreshItems() {
    final data = _eventsBox.keys.map((key) {
      final item = _eventsBox.get(key);
      return {
        "key": key, // unique key of the event
        "name": item["name"], // name of the event
        "type": item["type"], // type of the event: money entry or exit
        "value": item["value"], // value moved
        "date": item["date"], // date the event was registered
      };
    }).toList();

    // Sort the list based on the "name" field
    //data.sort((a, b) => (a["name"] as String).compareTo(b["name"] as String));

    setState(() {
      _events = data.toList();
    });
    
  }

  // Creates a new item
  Future<void> _createItem(Map<String, dynamic> newEvent) async {
    await _eventsBox.add(newEvent);
    _refreshItems(); // Updates the UI
  }

  // Update an existing item
  Future<void> _updateItem(int itemKey, Map<String, dynamic> item) async {
    await _eventsBox.put(itemKey, item);
    _refreshItems(); // Updates the UI
  }

  // Delete an existing item
  Future<void> _deleteItem(int itemKey) async {
    eventsMap.remove(itemKey);
    print("$itemKey removed from the eventsMap");
    print("Current eventsMap: $eventsList"); 

    // Get the name associated with the itemKey being deleted
    final item = _events.firstWhere((element) => element["key"] == itemKey);
    final nameToDelete = item["name"];

    await _eventsBox.delete(itemKey);
    print("$itemKey removed from the nameBox");  
    print("Current nameBox: $eventsList");   

    // Remove the name from eventsList
    eventsList.remove(nameToDelete);
    print("$itemKey removed from the eventsList");
    print("Current eventsList: $eventsList");    

    setState(() {
      _deletedItemCount++;
    });

    // Reset the timer if it's already running
    _messageTimer?.cancel();
    _messageTimer = Timer(const Duration(seconds: 1), _deletedItemMessage);

    _refreshItems(); // Updates the UI
  }

  // Message to inform an item was deleted
  Future<void> _deletedItemMessage() async {
    if (_deletedItemCount > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$_deletedItemCount itens deletados."),
        ),
      );

      // Reset the count
      setState(() {
        _deletedItemCount = 0;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Item deletado."),
        ),
      );
      // Reset the count
      setState(() {
        _deletedItemCount = 0;
      });
    }
  }   
    
  // Creates the dialog to add new names to the name list
  void _showForm(BuildContext ctx, int? itemKey) async {
    
    if (itemKey != null) {
      final existingItem = _events.firstWhere((element) => element["key"] == itemKey);
      _nameController.text = existingItem["name"];
      selectedType = existingItem["type"];
      _valueController.text = existingItem["value"];
    } else {
      // Clear the text fields
      _nameController.text = "";
      selectedType = null;
      _valueController.text = "0.00";
    }
    
    showModalBottomSheet(
      context: ctx, 
      builder: (_) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          top: 15,
          left: 15,
          right: 15
        ),
        child: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                children: <Widget>[
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: "Nome do registro"
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  // Creates the dropdown menu
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      hintText: "Tipo de registro",
                      border: OutlineInputBorder(),
                    ),
                    value: selectedType,
                    items: typeOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedType = newValue;
                        if (_valueController.text.isNotEmpty) {
                          double currentValue = double.tryParse(_valueController.text) ?? 0.0;
                          if (selectedType == 'Entrada' && currentValue < 0) {
                            _valueController.text = (-currentValue).toString();
                          } else if (selectedType == 'Saída' && currentValue > 0) {
                            _valueController.text = (-currentValue).toString();
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  TextField(
                    controller: _valueController,
                    decoration: const InputDecoration(
                      hintText: "Valor",
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly, // Allow only digits
                    ],
                    onChanged: (text) {
                      if (text.isEmpty) {
                        // Set default value '0.00' if text is empty
                        _valueController.text = '0.00';
                        return;
                      }

                      // Parse the input text as a decimal number
                      double currentValue = double.tryParse(text) ?? 0.0;

                      // Shift the decimal point for each digit entered
                      currentValue = currentValue / 100.0;

                      // Handle the logic for 'Entrada' and 'Saída'
                      if (selectedType == 'Entrada' && currentValue < 0) {
                        currentValue = -currentValue;
                      } else if (selectedType == 'Saída' && currentValue > 0) {
                        currentValue = -currentValue;
                      }

                      // Format the value to 2 decimal places
                      String formattedText = currentValue.toStringAsFixed(2);

                      // Update the text field with the formatted value
                      _valueController.text = formattedText;

                      // Move cursor to end of text after modifying the value
                      _valueController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _valueController.text.length),
                      );
                    },
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryButton,
                                    foregroundColor: primaryBackground,
                                  ),
                    onPressed: () async {
                      if (itemKey == null) {
                        _createItem({
                          "name": _nameController.text,
                          "type": selectedType,
                          "value": _valueController.text,
                          "date": formattedDate,
                        });
                      }
                      if (itemKey != null) {
                        _updateItem(itemKey, {
                          "name": _nameController.text.trim(),
                          "type": selectedType?.trim(),
                          "value": _valueController.text.trim(),
                          "date": formattedDate.trim(),
                        });
                      }
                      //Clear the text fields
                      _nameController.text = "";
                      _typeController.text = "";
                      _valueController.text = "";
                      // Closes the modal window
                      Navigator.of(context).pop(); 
                    }, 
                    child: const Text("Salvar"),
                  ),
                ],
                );
            }
          ),
        ),
        ),
        );
  }
  // App programming logic ENDS here

  // Build setup starts here
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Cart Ray",
          style: TextStyle(
            fontSize: 20,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: defaultIconTheme
      ),
      
      // Page body
      body: Column(
        children: [
          Card(
            color: sumOfEvents() >= 0 ? positiveBalanceBackground : negativeBalanceBackground,
            margin: const EdgeInsets.all(10),
            elevation: 3,
            child: ListTile(
              title: Text(
                "Balanço: R\$ ${sumOfEvents().toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const Divider(),
          Expanded(
          child: ListView.builder(
            itemCount: _events.length,
            itemBuilder: (_, index) {
              final currentItem = _events[index];
              String valueString = currentItem["value"] ?? "0.0";
              Color cardColor = valueString.contains('-') ? cardRed : cardGreen;
            return Card(
                color: cardColor,
                margin: const EdgeInsets.all(10),
                elevation: 3,
                child: ListTile(
                  title: Text(
                    currentItem["name"] ?? "Erro ao retornar o nome",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    children: <Widget>[
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text("Data: ${currentItem["date"].toString()}"),
                      ),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text("Tipo de evento: ${currentItem["type"].toString()}"),
                      ),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text("Valor: R\$ ${currentItem["value"].toString()}"),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showForm(
                          context,
                          currentItem["key"],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteItem(
                          currentItem["key"],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, null),
        backgroundColor: primaryButton,
        foregroundColor: primaryBackground,
        child: const Icon(Icons.add),
      ),
    );
  }

  double sumOfEvents() {
    double total = 0.0;
    for (final item in _events) {
      // Retrieve the event value
      final eventValue = item["value"] ?? "0,00";
      // Convert the value to a double, replacing commas with dots if necessary
      final eventsSum = double.tryParse(eventValue.replaceAll(',', '.')) ?? 0.00;
      // Add the value to the total sum
      total += eventsSum;
    }
    return total;
  }
}
