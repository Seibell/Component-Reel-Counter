import 'package:fuzzywuzzy/fuzzywuzzy.dart' as fuzzy;
import 'package:fuzzywuzzy/model/extracted_result.dart';

class TextBucketing {
  String processExtractedText(String recognizedText) {
    bool isValidProductNumber(String token) {
      int count = token.runes.where((rune) {
        var character = String.fromCharCode(rune);
        return character.toUpperCase() == character ||
            character.contains(RegExp(r'\d'));
      }).length;

      return count / token.length >= 0.7;
    }

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

    // Initialize results with empty lists for each target category
    Map<String, List<String>> results = {for (var key in targets.keys) key: []};

    List<String> uncategorized = [];

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
              if (target == 'Vendor Product Number' ||
                  target == 'Customer Product Number') {
                if (!isValidProductNumber(nextToken)) {
                  break;
                }
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
              if (target == 'Vendor Product Number' ||
                  target == 'Customer Product Number') {
                if (!isValidProductNumber(
                    token.replaceFirst(variation, '').trim())) {
                  break;
                }
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
          uncategorized.add(token);
        }
      }
    }

    // Format the categorized results into a single string
    String formattedResults = results.entries.map((entry) {
      String category = entry.key;
      List<String> tokens = entry.value;
      return '$category: ${tokens.join(", ")}';
    }).join("\n");

    // Add the "Uncategorized" entries so they appear at the end
    formattedResults += "\nUncategorized: ${uncategorized.join(", ")}";

    return formattedResults;
  }
}
