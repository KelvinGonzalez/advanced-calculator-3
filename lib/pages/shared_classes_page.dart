import 'package:advanced_calculator_3/models/app_state.dart';
import 'package:advanced_calculator_3/models/shared_class.dart';
import 'package:advanced_calculator_3/pages/widgets_lib.dart';
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
  int page = 0;
  late Future<List<SharedClass>> sharedClasses;
  late Future<int> classesCount;
  SearchSort searchSort = SearchSort.recent;
  final searchController = TextEditingController(text: "");

  static const classesPerPage = 20;

  void search() {
    setState(() {
      final supabase = widget.cubit.state.supabase;
      sharedClasses = SharedClass.search(
          searchController.text, page, searchSort, supabase, classesPerPage);
      classesCount = SharedClass.getSharedClassesCount(supabase)
        ..then((value) {
          final maxPage = (value / classesPerPage).ceil() - 1;
          if (page > maxPage) {
            page = maxPage;
            search();
          }
        });
    });
  }

  void navigate(int direction, int maxPage) {
    if (direction.abs() != 1) return;
    if (direction < 0 && page <= 0) return;
    if (direction > 0 && page >= maxPage - 1) return;
    page += direction;
    search();
  }

  void delete(SharedClass sharedClass) async {
    await sharedClass.delete(widget.cubit.state.supabase);
    search();
  }

  @override
  void initState() {
    super.initState();
    search();
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
                        onChanged: (_) => search(),
                        decoration: const InputDecoration(labelText: "Search"),
                      ),
                    ),
                    PopupMenuButton<SearchSort>(
                      initialValue: searchSort,
                      onSelected: (value) {
                        searchSort = value;
                        search();
                      },
                      itemBuilder: (context) => SearchSort.values
                          .map((e) => PopupMenuItem<SearchSort>(
                              value: e, child: Text(e.key)))
                          .toList(),
                      child: const Icon(Icons.sort),
                    ),
                  ],
                ),
              ),
              const HeightlessDivider(),
              Expanded(
                child: FutureBuilder(
                    future: sharedClasses,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData) return Container();
                      final sharedClasses = snapshot.data!;
                      return SingleChildScrollView(
                        child: Column(
                          children: separateWidgets(
                              sharedClasses
                                  .map((e) => SharedClassItem(e,
                                      state: state,
                                      deleteClass: () => delete(e)))
                                  .toList(),
                              const HeightlessDivider()),
                        ),
                      );
                    }),
              ),
              const HeightlessDivider(),
              FutureBuilder(
                  future: classesCount,
                  builder: (context, snapshot) {
                    final pagesCount = snapshot.hasData
                        ? (snapshot.data! / classesPerPage).ceil()
                        : null;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                            onPressed: snapshot.hasData
                                ? () => navigate(-1, pagesCount!)
                                : null,
                            icon: const Icon(Icons.arrow_left)),
                        Text(
                          "${page + 1}/${pagesCount ?? "?"}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        IconButton(
                            onPressed: snapshot.hasData
                                ? () => navigate(1, pagesCount!)
                                : null,
                            icon: const Icon(Icons.arrow_right)),
                      ],
                    );
                  }),
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
  final void Function() deleteClass;

  const SharedClassItem(this.sharedClass,
      {super.key, required this.state, required this.deleteClass});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                    "${sharedClass.name}(${sharedClass.customClass.fields.join(",")})",
                    style: const TextStyle(fontSize: 24)),
                Text(
                    "Created on ${DateFormat("dd/MM/yyyy hh:mm a").format(sharedClass.createdAt)} UTC"),
                Text("Imported ${sharedClass.importCount} times"),
              ],
            ),
            Row(
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
                      sharedClass.markImported(state.supabase);
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(
                            content: Text(
                                "Class ${parent.name} imported to device")));
                    },
                    icon: const Icon(Icons.download)),
                if (state.uuid == sharedClass.creatorId)
                  IconButton(
                      onPressed: () async {
                        final answer = await getConfirmation(
                            "Delete ${sharedClass.name}?", context);
                        if (!answer) return;
                        deleteClass();
                      },
                      icon: const Icon(Icons.delete)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
