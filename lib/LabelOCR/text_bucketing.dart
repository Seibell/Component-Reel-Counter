import 'package:fuzzywuzzy/fuzzywuzzy.dart' as fuzzy;
import 'package:fuzzywuzzy/model/extracted_result.dart';

class TextBucketing {
  String processExtractedText(String recognizedText) {
    // Split the recognized text by line
    List<String> tokens = recognizedText.split('\n');

    print("******** Tokens in TextBucketing are $tokens");

    // Mapping of targets to their variations
    Map<String, List<String>> targets = {
      "Vendor Product Number": [
        "VENDOR P/N",
        "Vendor PN",
        "P/N",
        "PN",
        "PIN",
        "Product Number",
        "Vendor P/N",
        "SAP PN",
        "Mfr. P/N",
        "OUR P/N",
        "Our P/N",
        "Part Number",
        "Mfg P/N",
        "Manufacturer Product Number",
        "Manufacturer P/N"
      ],
      "Customer Product Number": [
        "Customer Product Number",
        "Prod Num",
        "PNum",
        "CUSTOMER P/N",
        "Cust PN",
        "Cust P/N",
        "Customer PN",
        "PIN",
        "Customer P/N",
      ],
      "Quantity": [
        "Quantity",
        "Qty",
        "QTY",
        "qty",
        "QUANTITY",
        "quantity",
        "QTY: PCS",
        "Qty: pcs"
      ],
      "Description": [
        "Desc",
        "Description",
        "DESC",
        "Part Description",
        "Part Desc",
        "Part Desc.",
        "Part Description.",
        "PART DESCRIPTION",
        "DESCRIPTION"
      ]
    };

    Map<String, List<String>> results = {"Uncategorized": []};
    bool categorized;

    // Iterate over the tokens
    for (int i = 0; i < tokens.length; i++) {
      String token = tokens[i];
      categorized = false;

      // If this token is a potential label, check the next token as well
      if (i + 1 < tokens.length && !token.contains(':')) {
        String nextToken = tokens[i + 1];

        // Iterate over the targets
        for (String target in targets.keys) {
          // Find the closest match for each variation of the current target
          for (String variation in targets[target]!) {
            ExtractedResult<String> closestMatch =
                fuzzy.extractOne(query: variation, choices: [token]);

            if (closestMatch.score >= 70) {
              if (!results.containsKey(target)) {
                results[target] = [];
              }
              results[target]!.add(nextToken);
              categorized = true;
              i++; // Skip the next token, as we've already categorized it
              break;
            }
          }

          if (categorized) {
            break;
          }
        }
      }

      if (!categorized) {
        // The original code: categorize the token itself, not the next token
        for (String target in targets.keys) {
          // Find the closest match for each variation of the current target
          for (String variation in targets[target]!) {
            ExtractedResult<String> closestMatch =
                fuzzy.extractOne(query: variation, choices: [token]);

            if (closestMatch.score >= 70) {
              if (!results.containsKey(target)) {
                results[target] = [];
              }
              results[target]!.add(token.replaceFirst(variation, '').trim());
              categorized = true;
              break;
            }
          }

          if (categorized) {
            break;
          }
        }

        if (!categorized) {
          results["Uncategorized"]!.add(token);
        }
      }
    }

    // Get the "Uncategorized" entry and remove it from the map
    var uncategorized = results["Uncategorized"];
    results.remove("Uncategorized");

    // Format the categorized results into a single string
    String formattedResults = results.entries.map((entry) {
      String category = entry.key;
      List<String> tokens = entry.value;
      return '$category: ${tokens.join(", ")}';
    }).join("\n");

    // Add the "Uncategorized" entry so it appears at the end
    formattedResults += "\nUncategorized: ${uncategorized?.join(", ")}";

    return formattedResults;
  }
}
