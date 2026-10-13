import 'package:flutter/material.dart';

void main() {
  runApp(const ShoppingApp());
}

class Item {
  Item(this.name);

  String name; // not final: the details screen renames it
  bool bought = false;
  int quantity = 1;
  String note = '';
  String category = 'Food';
}

class ShoppingApp extends StatelessWidget {
  const ShoppingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.green),
      home: const HomeScreen(title: 'Shopping List'),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final items = [Item('Milk'), Item('Bread'), Item('Rice')];
  final controller = TextEditingController();
  String filter = 'All';

  // What the screen shows, depending on the filter
  List<Item> get visibleItems {
    final toBuy = items.where((i) => !i.bought).toList();
    final bought = items.where((i) => i.bought).toList();
    if (filter == 'To buy') return toBuy;
    if (filter == 'Bought') return bought;
    return [...toBuy, ...bought]; // All: bought at the bottom
  }

  void showMessage(String text, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), action: action),
    );
  }

  void addItem() {
    final text = controller.text.trim();
    if (text.isEmpty) {
      showMessage('Type an item first');
      return;
    }
    final found = items.indexWhere(
          (i) => i.name.trim().toLowerCase() == text.toLowerCase(),
    );
    if (found != -1) {
      setState(() {
        items[found].quantity++;
      });
      showMessage(
        '${items[found].name} is already on the list: now ×${items[found].quantity}',
      );
    } else {
      setState(() {
        items.add(Item(text));
      });
    }
    controller.clear();
  }

  void deleteItem(Item item) {
    final index = items.indexOf(item); // real position in the full list
    setState(() {
      items.remove(item);
    });
    showMessage(
      '${item.name} removed',
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          setState(() {
            items.insert(index, item);
          });
        },
      ),
    );
  }

  void clearBought() {
    setState(() {
      items.removeWhere((i) => i.bought);
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = items.where((i) => !i.bought).length;
    final shown = visibleItems;

    Widget listArea;
    if (items.isEmpty) {
      listArea = const Center(child: Text('Your list is empty'));
    } else if (shown.isEmpty) {
      listArea = const Center(child: Text('Nothing here'));
    } else {
      listArea = ListView.builder(
        itemCount: shown.length,
        itemBuilder: (context, index) {
          final item = shown[index]; // the real Item, not an index
          final subtitle = item.note.isEmpty
              ? item.category
              : '${item.category} · ${item.note}';
          return ListTile(
            leading: Icon(
              item.bought ? Icons.check_circle : Icons.shopping_basket,
            ),
            title: Text(
              item.name,
              style: TextStyle(
                decoration:
                item.bought ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(subtitle),
            onTap: () {
              setState(() {
                item.bought = !item.bought;
              });
            },
            onLongPress: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailsScreen(item: item),
                ),
              ).then((_) {
                setState(() {});
              });
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    if (item.quantity > 1) {
                      setState(() {
                        item.quantity--;
                      });
                    }
                  },
                ),
                Text('${item.quantity}'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      item.quantity++;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => deleteItem(item),
                ),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} ($left left)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: clearBought,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Add an item',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => addItem(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: addItem, child: const Text('Add')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final f in ['All', 'To buy', 'Bought'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: filter == f,
                      onSelected: (_) {
                        setState(() {
                          filter = f;
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: listArea),
        ],
      ),
    );
  }
}

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key, required this.item});

  final Item item;

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final nameController = TextEditingController();
  final noteController = TextEditingController();
  String category = 'Food';

  @override
  void initState() {
    super.initState();
    nameController.text = widget.item.name;
    noteController.text = widget.item.note;
    category = widget.item.category;
  }

  @override
  void dispose() {
    nameController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void save() {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return; // stay on this screen
    }
    widget.item.name = name;
    widget.item.note = noteController.text.trim();
    widget.item.category = category;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: noteController,
            decoration: const InputDecoration(
              labelText: 'Note',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final c in ['Food', 'Drinks', 'Home'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c),
                    selected: category == c,
                    onSelected: (_) {
                      setState(() {
                        category = c;
                      });
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: save, child: const Text('Save')),
        ],
      ),
    );
  }
}