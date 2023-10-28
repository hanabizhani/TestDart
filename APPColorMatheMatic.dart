import 'package:yuv_mobile/app/messages/printers.dart';
import 'package:yuv_mobile/data/data_models/color/selection/response/find_recipe_response/find_recipe_response.dart';
import 'package:yuv_mobile/data/data_models/dispensing/calculatorColor/calculator_color.dart';
import 'package:get/get.dart';

const int numberOfColorSlut = 8;
const int totalSlut = 11;

class APPColorMatheMatic {
  // In step of now we don't calculator aa011
  FindRecipeResponse calculatorColor(
      {required CalculatorColor calculatorColor}) {
    List<double> recipe;

    // now I return false or true in future I gonna add error description
    if (!_validateCalculatorColor(calculatorColor)) {
      realDebugPrint('error validateCalculatorColor');
      throw 'error';
    }

    recipe = _getRecipeColorNormalized(calculatorColor.listRecipeRaw);
    recipe = _calculatorDeveloperVolume(recipe, calculatorColor.peroxide);

    recipe = _calculatorRatio(calculatorColor.totalMass,
        calculatorColor.colorRatio, calculatorColor.developerRatio, recipe);

    recipe = _delete2decimal(recipe);

    FindRecipeResponse finalRecipe =
        _convertListToRecipe(recipe, calculatorColor);
    return finalRecipe;
  }

  bool _validateCalculatorColor(CalculatorColor calculatorColor) {
    if (calculatorColor.totalMass == 0 ||
        calculatorColor.peroxide == 0 ||
        calculatorColor.developerRatio == 0 ||
        calculatorColor.colorRatio == 0) {
      return false;
    }

    if (calculatorColor.listRecipeRaw.length == 1 &&
        calculatorColor.listRecipeRaw.first.percentage != 1) {
      return false;
    }

    for (FindRecipeResponse listRecipe in calculatorColor.listRecipeRaw) {
      if (listRecipe.percentage == 0) {
        return false;
      }
    }
    return true;
  }

  List<double> _delete2decimal(List<double> finalRecipe) {
    for (int i = 0; i < finalRecipe.length; i++) {
      finalRecipe[i] = finalRecipe[i].toPrecision(2);
    }
    return finalRecipe;
  }

  FindRecipeResponse _convertListToRecipe(
          List<double> recipe, CalculatorColor calculatorColor) =>
      FindRecipeResponse(
          profile_id: calculatorColor.listRecipeRaw.first.profile_id,
          aa01: recipe[0].toString(),
          aa02: recipe[1].toString(),
          aa03: recipe[2].toString(),
          aa04: recipe[3].toString(),
          aa05: recipe[4].toString(),
          aa06: recipe[5].toString(),
          aa07: recipe[6].toString(),
          aa08: recipe[7].toString(),
          aa09: recipe[8].toString(),
          aa10: recipe[9].toString(),
          aa11: recipe[10].toString());

  List<double> _calculatorRatio(
      num totalMass, num colorRatio, num developerRatio, List<double> recipe) {
    double realMassColor = _getRealMass(
        totalMass: totalMass, mainRatio: colorRatio, secRatio: developerRatio);
    double realMassDeveloper = _getRealMass(
        totalMass: totalMass, mainRatio: developerRatio, secRatio: colorRatio);

    // I put ( i < 8 ) because we have 8 slut for color
    for (int i = 0; i < 10; i++) {
      double realMass = (i < 8) ? realMassColor : realMassDeveloper;
      recipe[i] = recipe[i] * realMass;
    }

    return recipe;
  }

  double _getRealMass(
          {required num totalMass,
          required num mainRatio,
          required num secRatio}) =>
      totalMass * (mainRatio / (mainRatio + secRatio));

  List<double> _calculatorDeveloperVolume(
      List<double> finalRecipe, double peroxide) {
    int volume40 = 8;
    int volume5 = 9;
    finalRecipe[volume5] = _calculatorVolume5(peroxide: peroxide);
    finalRecipe[volume40] = _calculatorVolume40(volume5: finalRecipe[volume5]);
    return finalRecipe;
  }

  List<double> _getRecipeColorNormalized(
      List<FindRecipeResponse> listRecipeRaw) {
    // I put 11 because we have 11 slut
    List<double> recipeNormalized = List<double>.filled(totalSlut, 0.0);

    for (FindRecipeResponse listRecipe in listRecipeRaw) {
      List<double> tempListRecipe = _calculateRecipeColor(listRecipe);
      for (int i = 0; i < tempListRecipe.length; i++) {
        recipeNormalized[i] += tempListRecipe[i];
      }
    }
    return recipeNormalized;
  }

  List<double> _calculateRecipeColor(FindRecipeResponse listRecipe) {
    List<double> recipeDoubleList = _convertToDoubleList(listRecipe);
    double totalSlut = _sumValueRecipes(recipeDoubleList);
    double? percentage = listRecipe.percentage;

    List<double> tempListRecipe = _calculatorRecipe(
        recipeDoubleList: recipeDoubleList,
        totalSlut: totalSlut,
        percentage: percentage);
    return tempListRecipe;
  }

  List<double> _convertToDoubleList(FindRecipeResponse listRecipe) {
    List<double> recipe = List<double>.filled(numberOfColorSlut, 0.0);
    // I put ! for now in percentage because the model of server maybe do not put percentage

    recipe[0] += double.parse(listRecipe.aa01);
    recipe[1] += double.parse(listRecipe.aa02);
    recipe[2] += double.parse(listRecipe.aa03);
    recipe[3] += double.parse(listRecipe.aa04);
    recipe[4] += double.parse(listRecipe.aa05);
    recipe[5] += double.parse(listRecipe.aa06);
    recipe[6] += double.parse(listRecipe.aa07);
    recipe[7] += double.parse(listRecipe.aa08);

    return recipe;
  }

  double _calculatorRatioMenu(
          {required double slutOfColor,
          required double totalSlut,
          required double percentage}) =>
      (slutOfColor / totalSlut) * percentage;

  double _calculatorVolume5({
    required double peroxide,
  }) =>
      //We got these numbers from Francisco in Excel
      (0.12 - peroxide) / 0.105;

  double _calculatorVolume40({
    required double volume5,
  }) =>
      // formol of volume
      // volume40 + volume5 = 1
      1 - volume5;

  List<double> _calculatorRecipe(
      {required List<double> recipeDoubleList,
      required double totalSlut,
      required double? percentage}) {
    List<double> recipeNormalized = List<double>.filled(numberOfColorSlut, 0.0);
    // I put ! for now in percentage because the model of server maybe do not put percentage

    for (int i = 0; i < numberOfColorSlut; i++) {
      recipeNormalized[i] += _calculatorRatioMenu(
          slutOfColor: recipeDoubleList[i],
          totalSlut: totalSlut,
          percentage: percentage!);
    }
    return recipeNormalized;
  }

  double _sumValueRecipes(List<double> recipe) =>
      recipe.reduce((a, b) => a + b);
}
