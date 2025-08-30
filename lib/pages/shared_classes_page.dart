import 'package:advanced_calculator_3/models/app_state.dart';
import 'package:advanced_calculator_3/models/shared_class.dart';
import 'package:advanced_calculator_3/pages/widgets_lib.dart';
import 'package:aggregated_collection/aggregated_collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class SharedClassesPage extends StatefulWidget {
  final AppCubit cubit;

  const SharedClassesPage({super.key, required this.cubit});

  @override
  State<SharedClassesPage> createState() => _SharedClassesPageState();
}

class _SharedClassesPageState extends State<SharedClassesPage> {
  SearchSort searchSort = SearchSort.recent;
  final searchController = TextEditingController(text: "");
  late Stream<List<AggregatedDocumentData>> documentStream;

  @override
  void initState() {
    super.initState();
    documentStream = widget.cubit.state.sharedClassCollection.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.cubit,
      child: BlocBuilder<AppCubit, AppState>(builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Exported Classes"),
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            backgroundColor: Colors.transparent,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(labelText: "Search"),
                      ),
                    ),
                    PopupMenuButton<SearchSort>(
                      initialValue: searchSort,
                      onSelected: (value) {
                        searchSort = value;
                        setState(() {});
                      },
                      itemBuilder: (context) => SearchSort.values
                          .map((e) => PopupMenuItem<SearchSort>(
                              value: e, child: Text(e.name)))
                          .toList(),
                      child: const Icon(Icons.sort),
                    ),
                  ],
                ),
              ),
              const HeightlessDivider(),
              Expanded(
                child: StreamBuilder(
                    stream: documentStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData) return Container();
                      final sharedClasses = SharedClass.search(snapshot.data!,
                          searchController.text.trim(), searchSort);
                      return ListView.builder(
                          itemCount: sharedClasses.length,
                          itemBuilder: (context, i) {
                            final e = sharedClasses[i];
                            return SharedClassItem(SharedClass.fromDocument(e),
                                state: state, reference: e.reference);
                          });
                    }),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class SharedClassItem extends StatelessWidget {
  final SharedClass sharedClass;
  final AppState state;
  final AggregatedDocumentReference reference;

  const SharedClassItem(this.sharedClass,
      {super.key, required this.state, required this.reference});

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    );
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      shape: shape,
      child: ListTile(
        shape: shape,
        onTap: () {
          final parent = sharedClass.customClass;
          final hasFunctions = parent.functions.isNotEmpty;
          final hasStaticVariables = parent.staticVariables.isNotEmpty;
          final hasStaticFunctions = parent.staticFunctions.isNotEmpty;
          showDialog(
              context: context,
              useRootNavigator: false,
              builder: (context) => AlertDialog(
                    title: Text(
                        "${sharedClass.name}(${sharedClass.customClass.fields.join(",")})"),
                    content: SingleChildScrollView(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: separateWidgets([
                        if (hasFunctions)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                                  const Text("Functions",
                                      style: TextStyle(fontSize: 16)),
                                ] +
                                parent.functions.entries
                                    .map((e) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0),
                                          child: Text(
                                              "- ${e.key}(${e.value.parameters.join(",")}) = ${e.value.function}",
                                              style: TextStyle(
                                                  color: Colors.grey[800])),
                                        ))
                                    .toList(),
                          ),
                        if (hasStaticVariables)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                                  const Text("Static Variables",
                                      style: TextStyle(fontSize: 16)),
                                ] +
                                parent.staticVariables.entries
                                    .map((e) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0),
                                          child: Text("- ${e.key} = ${e.value}",
                                              style: TextStyle(
                                                  color: Colors.grey[800])),
                                        ))
                                    .toList(),
                          ),
                        if (hasStaticFunctions)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                                  const Text("Static Functions",
                                      style: TextStyle(fontSize: 16)),
                                ] +
                                parent.staticFunctions.entries
                                    .map((e) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0),
                                          child: Text(
                                              "- ${e.key}(${e.value.parameters.join(",")}) = ${e.value.function}",
                                              style: TextStyle(
                                                  color: Colors.grey[800])),
                                        ))
                                    .toList(),
                          ),
                      ], const Divider()),
                    )),
                  ));
        },
        title: Text(
            "${sharedClass.name}(${sharedClass.customClass.fields.join(",")})",
            style: const TextStyle(fontSize: 24)),
        subtitle: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "Created on ${DateFormat("dd/MM/yyyy hh:mm a").format(sharedClass.createdAt.toDate())}"),
            Text("Imported ${sharedClass.importCount} times"),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                onPressed: () async {
                  final parent = sharedClass.customClass;
                  if (state.myClasses.containsKey(parent.name)) {
                    final answer = await getConfirmation(
                        "Replace ${parent.name}?", context,
                        content:
                            "You already have a class named ${parent.name} saved");
                    if (!answer) return;
                  }
                  if (!context.mounted) return;
                  context.read<AppCubit>().addClass(
                      parent.name,
                      parent.fields,
                      parent.functions,
                      parent.staticVariables,
                      parent.staticFunctions);
                  SharedClass.markImported(reference);
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                        content:
                            Text("Class ${parent.name} imported to device")));
                },
                icon: const Icon(Icons.download)),
            if (state.uuid == sharedClass.creatorId)
              IconButton(
                  onPressed: () async {
                    final answer = await getConfirmation(
                        "Delete ${sharedClass.name}?", context);
                    if (!answer) return;
                    SharedClass.delete(reference);
                  },
                  icon: const Icon(Icons.delete)),
          ],
        ),
      ),
    );
  }
}
