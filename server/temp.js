const XLSX = require("xlsx");
const fs = require("fs");

const FILE_PATH = "./mext_basic.xlsx";
const SHEET_NAME = "表全体";

// Excel 기준
// 12행: 성분 식별자
// 13행부터 데이터
const HEADER_ROW_INDEX = 11; // 0-based
const DATA_START_ROW_INDEX = 12; // 0-based

const GROUP_MAP = {
  "01": "穀類",
  "02": "いも及びでん粉類",
  "03": "砂糖及び甘味類",
  "04": "豆類",
  "05": "種実類",
  "06": "野菜類",
  "07": "果実類",
  "08": "きのこ類",
  "09": "藻類",
  10: "魚介類",
  11: "肉類",
  12: "卵類",
  13: "乳類",
  14: "油脂類",
  15: "菓子類",
  16: "し好飲料類",
  17: "調味料及び香辛料類",
  18: "調理済み流通食品類",
};

// 문부과학성 성분 식별자
const TARGET_IDENTIFIERS = {
  kcal: "ENERC_KCAL",
  water: "WATER",
  protein: "PROT-",
  fat: "FAT-",
  carbohydrate: "CHOAVLDF-",
  fiber: "FIB-",
  ash: "ASH",
  sodium: "NA",
};

function cleanText(value) {
  if (value === undefined || value === null) return null;

  const text = String(value).trim();
  if (!text) return null;

  return text;
}

function cleanNutrientValue(value) {
  if (value === undefined || value === null || value === "") return null;

  const text = String(value).trim();

  // 결측/특수값 처리
  if (!text || text === "-" || text === "*" || text === "Tr") {
    return null;
  }

  // 괄호값 "(12.3)" -> "12.3"
  const unwrapped = text.replace(/^\((.*)\)$/, "$1").trim();

  const num = Number(unwrapped);
  if (!Number.isNaN(num)) {
    return num;
  }

  return null;
}

function padCode(value, length) {
  if (value === undefined || value === null || value === "") return null;
  return String(value).trim().padStart(length, "0");
}

// 대표명
// 예)
// おおむぎ　押麦　乾 -> おおむぎ
function getParentName(foodName) {
  if (!foodName) return null;

  const parts = String(foodName)
    .split(/[　 ]+/)
    .filter(Boolean);
  if (parts.length === 0) return null;

  return parts[0];
}

// 하위 세부명
// 예)
// おおむぎ　押麦　乾 -> 押麦　乾
// アマランサス　玄穀 -> 玄穀
// アマランサス -> null
function getChildName(foodName) {
  if (!foodName) return null;

  const parts = String(foodName)
    .split(/[　 ]+/)
    .filter(Boolean);
  if (parts.length <= 1) return null;

  return parts.slice(1).join("　");
}

function buildIdentifierMap(headerRow) {
  const identifierMap = {};

  headerRow.forEach((cell, colIndex) => {
    const value = cleanText(cell);
    if (value) {
      identifierMap[value] = colIndex;
    }
  });

  return identifierMap;
}

function getCell(row, index) {
  if (index === undefined || index === null) return null;
  return row[index];
}

function main() {
  const workbook = XLSX.readFile(FILE_PATH);
  const sheet = workbook.Sheets[SHEET_NAME];

  if (!sheet) {
    throw new Error(`시트를 찾을 수 없습니다: ${SHEET_NAME}`);
  }

  const rows = XLSX.utils.sheet_to_json(sheet, {
    header: 1,
    raw: false,
    defval: null,
  });

  const headerRow = rows[HEADER_ROW_INDEX];
  if (!headerRow) {
    throw new Error("성분 식별자 헤더 행을 찾을 수 없습니다.");
  }

  const identifierMap = buildIdentifierMap(headerRow);

  const kcalCol = identifierMap[TARGET_IDENTIFIERS.kcal];
  const waterCol = identifierMap[TARGET_IDENTIFIERS.water];
  const proteinCol = identifierMap[TARGET_IDENTIFIERS.protein];
  const fatCol = identifierMap[TARGET_IDENTIFIERS.fat];
  const carbohydrateCol = identifierMap[TARGET_IDENTIFIERS.carbohydrate];
  const fiberCol = identifierMap[TARGET_IDENTIFIERS.fiber];
  const ashCol = identifierMap[TARGET_IDENTIFIERS.ash];
  const sodiumCol = identifierMap[TARGET_IDENTIFIERS.sodium];

  const requiredColumns = [
    ["kcal", kcalCol],
    ["water", waterCol],
    ["protein", proteinCol],
    ["fat", fatCol],
    ["carbohydrate", carbohydrateCol],
    ["fiber", fiberCol],
    ["ash", ashCol],
    ["sodium", sodiumCol],
  ];

  const missingColumns = requiredColumns.filter(([, col]) => col === undefined);
  if (missingColumns.length > 0) {
    throw new Error(`성분 식별자를 찾지 못했습니다: ${missingColumns.map(([name]) => name).join(", ")}`);
  }

  const categoryMap = {};

  for (let r = DATA_START_ROW_INDEX; r < rows.length; r++) {
    const row = rows[r];
    if (!row) continue;

    // 앞 4개는 기본 고정 열
    const foodGroupRaw = cleanText(row[0]);
    const foodCodeRaw = cleanText(row[1]);
    const indexCodeRaw = cleanText(row[2]);
    const fullFoodName = cleanText(row[3]);

    if (!foodGroupRaw || !foodCodeRaw || !fullFoodName) {
      continue;
    }

    const categoryCode = padCode(foodGroupRaw, 2);
    const foodCode = padCode(foodCodeRaw, 5);
    const indexCode = padCode(indexCodeRaw, 4);
    const categoryName = GROUP_MAP[categoryCode] ?? null;

    const parentName = getParentName(fullFoodName);
    const childName = getChildName(fullFoodName);

    if (!categoryCode || !foodCode || !parentName) {
      continue;
    }

    if (!categoryMap[categoryCode]) {
      categoryMap[categoryCode] = {
        categoryCode,
        categoryName,
        itemsMap: {},
      };
    }

    const category = categoryMap[categoryCode];

    if (!category.itemsMap[parentName]) {
      category.itemsMap[parentName] = {
        name: parentName,
        foods: [],
      };
    }

    category.itemsMap[parentName].foods.push({
      foodCode,
      indexCode,
      name: childName,
      kcal: cleanNutrientValue(getCell(row, kcalCol)),
      water: cleanNutrientValue(getCell(row, waterCol)),
      protein: cleanNutrientValue(getCell(row, proteinCol)),
      fat: cleanNutrientValue(getCell(row, fatCol)),
      carbohydrate: cleanNutrientValue(getCell(row, carbohydrateCol)),
      fiber: cleanNutrientValue(getCell(row, fiberCol)),
      ash: cleanNutrientValue(getCell(row, ashCol)),
      sodium: cleanNutrientValue(getCell(row, sodiumCol)),
    });
  }

  const result = Object.values(categoryMap)
    .sort((a, b) => a.categoryCode.localeCompare(b.categoryCode))
    .map((category) => {
      const items = Object.values(category.itemsMap)
        .sort((a, b) => a.name.localeCompare(b.name, "ja"))
        .map((item) => {
          item.foods.sort((a, b) => a.foodCode.localeCompare(b.foodCode));
          return item;
        });

      return {
        categoryCode: category.categoryCode,
        categoryName: category.categoryName,
        items,
      };
    });

  fs.writeFileSync("./foods_grouped_with_nutrients.json", JSON.stringify(result, null, 2), "utf-8");

  console.log("완료: foods_grouped_with_nutrients.json 저장");
  console.log(`카테고리 수: ${result.length}`);
}

main();
