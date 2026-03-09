const fs = require("fs");
const path = require("path");

const INPUT_PATH = "./FoodData_Central_foundation_food_json_2025-12-18.json";
const OUTPUT_PATH = "./foods_nutrients_us_foundation.json";

// USDA FDC (Legacy-style nutrient numbers in FoundationFoods export)
const NUTRIENT_NUMBERS = {
  kcal: "208",
  water: "255",
  protein: "203",
  fat: "204",
  carbohydrate: "205",
  fiber: "291",
  ash: "207",
  sodium: "307",
};

function cleanText(value) {
  if (value === undefined || value === null) return null;
  const text = String(value).trim();
  return text || null;
}

function cleanNumber(value) {
  if (value === undefined || value === null || value === "") return null;
  const n = Number(value);
  if (!Number.isFinite(n)) return null;
  return n;
}

function makeIndexCode(counter) {
  return String(counter).padStart(4, "0");
}

function getParentName(description) {
  const text = cleanText(description);
  if (!text) return null;

  const tokens = text.split(",").map((v) => v.trim()).filter(Boolean);
  if (tokens.length > 0) return tokens[0];

  return text;
}

function getChildName(description, parentName) {
  const text = cleanText(description);
  if (!text || !parentName) return null;
  if (text === parentName) return null;

  if (text.startsWith(`${parentName},`)) {
    const rest = text.slice(parentName.length + 1).trim();
    return rest || null;
  }

  return text;
}

function extractNutrients(foodNutrients) {
  const nutrients = {
    kcal: null,
    water: null,
    protein: null,
    fat: null,
    carbohydrate: null,
    fiber: null,
    ash: null,
    sodium: null,
  };

  if (!Array.isArray(foodNutrients)) return nutrients;

  const byNumber = {};
  for (const item of foodNutrients) {
    const number = cleanText(item?.nutrient?.number);
    if (!number) continue;
    if (item?.amount === undefined || item?.amount === null) continue;
    byNumber[number] = cleanNumber(item.amount);
  }

  for (const [key, number] of Object.entries(NUTRIENT_NUMBERS)) {
    nutrients[key] = byNumber[number] ?? null;
  }

  return nutrients;
}

function main() {
  const raw = JSON.parse(fs.readFileSync(INPUT_PATH, "utf8"));
  const foods = Array.isArray(raw?.FoundationFoods) ? raw.FoundationFoods : [];

  if (foods.length === 0) {
    throw new Error("FoundationFoods 배열을 찾지 못했습니다.");
  }

  const categoryNameSet = new Set();
  const normalizedFoods = [];

  for (const food of foods) {
    const categoryName = cleanText(food?.foodCategory?.description) || "Uncategorized";
    const foodCode = cleanText(food?.fdcId);
    const description = cleanText(food?.description);

    if (!foodCode || !description) continue;

    const parentName = getParentName(description);
    if (!parentName) continue;

    categoryNameSet.add(categoryName);
    normalizedFoods.push({
      categoryName,
      foodCode,
      parentName,
      childName: getChildName(description, parentName),
      nutrients: extractNutrients(food?.foodNutrients),
    });
  }

  const sortedCategoryNames = [...categoryNameSet].sort((a, b) => a.localeCompare(b, "en"));
  const categoryCodeMap = {};
  sortedCategoryNames.forEach((name, index) => {
    categoryCodeMap[name] = String(index + 1).padStart(2, "0");
  });

  const categoryMap = {};
  let runningIndex = 1;

  for (const row of normalizedFoods) {
    const categoryCode = categoryCodeMap[row.categoryName];

    if (!categoryMap[categoryCode]) {
      categoryMap[categoryCode] = {
        categoryCode,
        categoryName: row.categoryName,
        itemsMap: {},
      };
    }

    const category = categoryMap[categoryCode];
    if (!category.itemsMap[row.parentName]) {
      category.itemsMap[row.parentName] = {
        name: row.parentName,
        foods: [],
      };
    }

    category.itemsMap[row.parentName].foods.push({
      foodCode: row.foodCode,
      indexCode: makeIndexCode(runningIndex++),
      name: row.childName,
      kcal: row.nutrients.kcal,
      water: row.nutrients.water,
      protein: row.nutrients.protein,
      fat: row.nutrients.fat,
      carbohydrate: row.nutrients.carbohydrate,
      fiber: row.nutrients.fiber,
      ash: row.nutrients.ash,
      sodium: row.nutrients.sodium,
    });
  }

  const result = Object.values(categoryMap)
    .sort((a, b) => a.categoryCode.localeCompare(b.categoryCode))
    .map((category) => {
      const items = Object.values(category.itemsMap)
        .sort((a, b) => a.name.localeCompare(b.name, "en"))
        .map((item) => {
          item.foods.sort((a, b) => String(a.foodCode).localeCompare(String(b.foodCode)));
          return item;
        });

      return {
        categoryCode: category.categoryCode,
        categoryName: category.categoryName,
        items,
      };
    });

  fs.writeFileSync(OUTPUT_PATH, JSON.stringify(result, null, 2), "utf8");

  console.log(`입력 파일: ${path.basename(INPUT_PATH)}`);
  console.log(`출력 파일: ${OUTPUT_PATH}`);
  console.log(`식품 수: ${normalizedFoods.length}`);
  console.log(`카테고리 수: ${result.length}`);
}

main();
