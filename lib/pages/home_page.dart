// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:cart_ray/widgets/drawer.dart';
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
  final pageBackground = Colors.blue.shade100;
  final primaryButton = Colors.black;
  final primaryBackground = Colors.white;

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

    _refreshItems(); // Updates the UI
    _deletedItemMessage();
  }

  // Message to inform an item was deleted
  Future<void> _deletedItemMessage() async {
    // Show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Item deletado da lista."),
        )
    );
  }   
    
  // Creates the dialog to add new names to the name list
  void _showForm(BuildContext ctx, int? itemKey) async {
    
    if (itemKey != null) {
      final existingItem = 
      _events.firstWhere((element) => element["key"] == itemKey);
      _nameController.text = existingItem["name"];
      _typeController.text = existingItem["type"];
      _valueController.text = existingItem["type"];
    } else {
      //Clear the text fields
      _nameController.text = "";
      _typeController.text = "";
      _valueController.text = "";
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
          child: Column(
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
              TextField(
                controller: _typeController,
                decoration: const InputDecoration(
                  hintText: "Tipo de registro"
                ),
              ),
              TextField(
                controller: _valueController,
                decoration: const InputDecoration(
                  hintText: "Valor"
                ),
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
                      "type": _typeController.text,
                      "value": _valueController.text,
                    });
                  }
                  if (itemKey != null) {
                    _updateItem(itemKey, {
                      "name": _nameController.text.trim(),
                      "type": _typeController.text,
                      "value": _valueController.text.trim()
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
      drawer: const MyDrawer(),
      body: Column(
        children: [
          Card(
            color: pageBackground,
            margin: const EdgeInsets.all(10),
            elevation: 3,
            child: ListTile(
              title: const Text(
                "Rendimentos recebidos este mês:",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "Total: R\$ ${calculateTotalReceivedDividends().toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          Expanded(
          child: ListView.builder(
            itemCount: _events.length,
            itemBuilder: (_, index) {
              final currentItem = _events[index];
              if (currentItem["value"] == null && eventsMap[currentItem["key"]] == null) {
              }
              final dividendValue = currentItem["value"] ?? eventsMap[currentItem["key"]] ?? "Carregando";
              var sumDividend = double.tryParse(dividendValue.replaceAll(',', '.')) ?? 0.00;
              var currentQuantity = double.tryParse(currentItem["type"]?.replaceAll(',', '.') ?? "0") ?? 0;
              final dividendYield = currentItem["total"] ?? currentQuantity * sumDividend;

              try {
                if (sumDividend > 0) {
                  Map<String, dynamic>? existingItem = _eventsBox.get(currentItem["key"]);
                  if (existingItem != null) {
                    existingItem.addAll({
                      "value": dividendValue,
                      "total": dividendYield,
                    });
                    _eventsBox.put(currentItem["key"], existingItem);
                    print("$dividendValue e $dividendYield adicionados ao box com sucesso!");
                  } else {
                    print("Item não encontrado no banco de dados Hive.");
                  }
                } else {
                  // Do nothing
                }
              } catch (e) {
                print("Erro ao salvar os valores do dividendo na Hive: $e");
              }
        return Card(
                color: Colors.green.shade100,
                margin: const EdgeInsets.all(10),
                elevation: 3,
                child: ListTile(
                  title: Text(
                    currentItem["name"] ?? "Erro ao retornar o name",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    children: <Widget>[
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text("Tipo de evento: ${currentItem["type"].toString()}"),
                      ),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text("Valor: R\$ ${sumDividend.toStringAsFixed(2)}"),
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

  double calculateTotalReceivedDividends() {
    double total = 0.0;
    for (final item in _events) {
      final dividendValue = item["value"] ?? eventsMap[item["key"]] ?? "0.00";
      final sumDividend = double.tryParse(dividendValue.replaceAll(',', '.')) ?? 0.00;
      var currentQuantity = double.tryParse(item["type"]?.replaceAll(',', '.') ?? "0") ?? 0;
      final dividendYield = currentQuantity * sumDividend;
      total += dividendYield;
    }
    return total;
  }}