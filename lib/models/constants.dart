final numberRegex = RegExp(r"^[0-9.]+$");
final nameRegex = RegExp(r"^[a-zA-Z_]+[a-zA-Z_0-9]*$");

bool isNameOrNumber(String key) =>
    nameRegex.hasMatch(key) || numberRegex.hasMatch(key);

bool isName(String key) => nameRegex.hasMatch(key);

const emptyJson = "{}";
