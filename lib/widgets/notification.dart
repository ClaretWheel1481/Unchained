import 'package:fluent_ui/fluent_ui.dart';

void showContentDialog(BuildContext context, String title, content) async {
  await showDialog<String>(
    context: context,
    builder: (context) => ContentDialog(
      title: Text(title),
      content: Text(
        content,
      ),
      actions: [
        FilledButton(
          child: const Text('好的'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    ),
  );
}
