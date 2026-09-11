// lib/features/games/different_object/categories_data.dart
//
// 6 Category pools and question generator for Find the Different Object.
// Ported from DifferentObject.jsx.

import 'dart:math';

class CategoryItem {
  final String name;
  final String emoji;

  const CategoryItem({required this.name, required this.emoji});
}

class CategoryPool {
  final String key;
  final String name;
  final String singular;
  final List<CategoryItem> items;

  const CategoryPool({
    required this.key,
    required this.name,
    required this.singular,
    required this.items,
  });
}

const Map<String, CategoryPool> kCategories = {
  'fruits': CategoryPool(
    key: 'fruits',
    name: 'Fruits',
    singular: 'fruit',
    items: [
      CategoryItem(name: 'Apple', emoji: '🍎'),
      CategoryItem(name: 'Banana', emoji: '🍌'),
      CategoryItem(name: 'Orange', emoji: '🍊'),
      CategoryItem(name: 'Grapes', emoji: '🍇'),
      CategoryItem(name: 'Mango', emoji: '🥭'),
      CategoryItem(name: 'Strawberry', emoji: '🍓'),
      CategoryItem(name: 'Watermelon', emoji: '🍉'),
      CategoryItem(name: 'Pineapple', emoji: '🍍'),
      CategoryItem(name: 'Pear', emoji: '🍐'),
      CategoryItem(name: 'Peach', emoji: '🍑'),
      CategoryItem(name: 'Cherry', emoji: '🍒'),
    ],
  ),
  'animals': CategoryPool(
    key: 'animals',
    name: 'Animals',
    singular: 'animal',
    items: [
      CategoryItem(name: 'Dog', emoji: '🐶'),
      CategoryItem(name: 'Cat', emoji: '🐱'),
      CategoryItem(name: 'Elephant', emoji: '🐘'),
      CategoryItem(name: 'Lion', emoji: '🦁'),
      CategoryItem(name: 'Rabbit', emoji: '🐰'),
      CategoryItem(name: 'Panda', emoji: '🐼'),
      CategoryItem(name: 'Monkey', emoji: '🐵'),
      CategoryItem(name: 'Cow', emoji: '🐮'),
      CategoryItem(name: 'Horse', emoji: '🐴'),
      CategoryItem(name: 'Bear', emoji: '🐻'),
      CategoryItem(name: 'Sheep', emoji: '🐑'),
    ],
  ),
  'vehicles': CategoryPool(
    key: 'vehicles',
    name: 'Vehicles',
    singular: 'vehicle',
    items: [
      CategoryItem(name: 'Car', emoji: '🚗'),
      CategoryItem(name: 'Bus', emoji: '🚌'),
      CategoryItem(name: 'Train', emoji: '🚂'),
      CategoryItem(name: 'Airplane', emoji: '✈️'),
      CategoryItem(name: 'Ship', emoji: '🚢'),
      CategoryItem(name: 'Bicycle', emoji: '🚲'),
      CategoryItem(name: 'Helicopter', emoji: '🚁'),
      CategoryItem(name: 'Ambulance', emoji: '🚑'),
      CategoryItem(name: 'Tractor', emoji: '🚜'),
      CategoryItem(name: 'Scooter', emoji: '🛵'),
    ],
  ),
  'clothes': CategoryPool(
    key: 'clothes',
    name: 'Clothes',
    singular: 'clothing item',
    items: [
      CategoryItem(name: 'Shirt', emoji: '👕'),
      CategoryItem(name: 'Pants', emoji: '👖'),
      CategoryItem(name: 'Dress', emoji: '👗'),
      CategoryItem(name: 'Shoe', emoji: '👟'),
      CategoryItem(name: 'Cap', emoji: '🧢'),
      CategoryItem(name: 'Coat', emoji: '🧥'),
      CategoryItem(name: 'Scarf', emoji: '🧣'),
      CategoryItem(name: 'Gloves', emoji: '🧤'),
      CategoryItem(name: 'Socks', emoji: '🧦'),
      CategoryItem(name: 'Hat', emoji: '👒'),
    ],
  ),
  'food': CategoryPool(
    key: 'food',
    name: 'Prepared Food',
    singular: 'food item',
    items: [
      CategoryItem(name: 'Pizza', emoji: '🍕'),
      CategoryItem(name: 'Burger', emoji: '🍔'),
      CategoryItem(name: 'Bread', emoji: '🍞'),
      CategoryItem(name: 'Noodles', emoji: '🍜'),
      CategoryItem(name: 'Rice Bowl', emoji: '🍚'),
      CategoryItem(name: 'Sandwich', emoji: '🥪'),
      CategoryItem(name: 'Pancake', emoji: '🥞'),
      CategoryItem(name: 'Warm Soup', emoji: '🍲'),
      CategoryItem(name: 'Cheese', emoji: '🧀'),
      CategoryItem(name: 'Boiled Egg', emoji: '🍳'),
    ],
  ),
  'vegetables': CategoryPool(
    key: 'vegetables',
    name: 'Vegetables',
    singular: 'vegetable',
    items: [
      CategoryItem(name: 'Carrot', emoji: '🥕'),
      CategoryItem(name: 'Broccoli', emoji: '🥦'),
      CategoryItem(name: 'Corn', emoji: '🌽'),
      CategoryItem(name: 'Potato', emoji: '🥔'),
      CategoryItem(name: 'Tomato', emoji: '🍅'),
      CategoryItem(name: 'Cucumber', emoji: '🥒'),
      CategoryItem(name: 'Eggplant', emoji: '🍆'),
      CategoryItem(name: 'Onion', emoji: '🧅'),
      CategoryItem(name: 'Garlic', emoji: '🧄'),
      CategoryItem(name: 'Peas', emoji: '🥬'),
    ],
  ),
};

class GameObjectChoice {
  final String id;
  final String name;
  final String emoji;
  final String categoryKey;
  final String categoryName;
  final bool isOdd;

  const GameObjectChoice({
    required this.id,
    required this.name,
    required this.emoji,
    required this.categoryKey,
    required this.categoryName,
    required this.isOdd,
  });
}

class DifferentObjectQuestion {
  final String commonCategory;
  final String commonSingular;
  final String oddCategory;
  final String oddSingular;
  final GameObjectChoice oddItem;
  final List<GameObjectChoice> objects;

  const DifferentObjectQuestion({
    required this.commonCategory,
    required this.commonSingular,
    required this.oddCategory,
    required this.oddSingular,
    required this.oddItem,
    required this.objects,
  });
}

class DifferentObjectLevelConfig {
  final int id;
  final String label;
  final String subtitle;
  final int totalItems;
  final int questionsCount;

  const DifferentObjectLevelConfig({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.totalItems,
    this.questionsCount = 5,
  });
}

const Map<int, DifferentObjectLevelConfig> kDifferentObjectLevels = {
  1: DifferentObjectLevelConfig(
    id: 1,
    label: 'Level 1 — Easy',
    subtitle: '6 objects to choose from',
    totalItems: 6,
  ),
  2: DifferentObjectLevelConfig(
    id: 2,
    label: 'Level 2 — Medium',
    subtitle: '8 objects to choose from',
    totalItems: 8,
  ),
  3: DifferentObjectLevelConfig(
    id: 3,
    label: 'Level 3 — Hard',
    subtitle: '10 objects to choose from',
    totalItems: 10,
  ),
};

DifferentObjectQuestion generateDifferentObjectQuestion(
  int totalItems, [
  String? previousCategoryKey,
]) {
  final random = Random();
  final allKeys = kCategories.keys.toList();
  final availableKeys = allKeys.where((k) => k != previousCategoryKey).toList();
  final commonKey = availableKeys[random.nextInt(availableKeys.length)];
  final commonCat = kCategories[commonKey]!;

  final oddKeys = allKeys.where((k) => k != commonKey).toList();
  final oddKey = oddKeys[random.nextInt(oddKeys.length)];
  final oddCat = kCategories[oddKey]!;

  // Pick (totalItems - 1) unique items from common pool
  final shuffledCommon = List<CategoryItem>.from(commonCat.items)
    ..shuffle(random);
  final selectedCommon = shuffledCommon.take(totalItems - 1).map((item) {
    return GameObjectChoice(
      id: '${item.name}-${random.nextInt(99999)}',
      name: item.name,
      emoji: item.emoji,
      categoryKey: commonKey,
      categoryName: commonCat.name,
      isOdd: false,
    );
  }).toList();

  // Pick 1 odd item
  final shuffledOdd = List<CategoryItem>.from(oddCat.items)..shuffle(random);
  final oddChoice = GameObjectChoice(
    id: '${shuffledOdd[0].name}-${random.nextInt(99999)}',
    name: shuffledOdd[0].name,
    emoji: shuffledOdd[0].emoji,
    categoryKey: oddKey,
    categoryName: oddCat.name,
    isOdd: true,
  );

  // Combine and shuffle
  final objects = [...selectedCommon, oddChoice]..shuffle(random);

  return DifferentObjectQuestion(
    commonCategory: commonCat.name,
    commonSingular: commonCat.singular,
    oddCategory: oddCat.name,
    oddSingular: oddCat.singular,
    oddItem: oddChoice,
    objects: objects,
  );
}
