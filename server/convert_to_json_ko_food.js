const XLSX = require("xlsx");
const fs = require("fs");
const path = require("path");

const FILE_PATH = "./식품성분표(10개정판)2.xlsx";
const OUTPUT_PATH = "./foods_nutrients_ko.json";

// 필요하면 직접 시트명 지정 가능
// 예: const TARGET_SHEET_NAME = "Sheet1";
const TARGET_SHEET_NAME = "국가표준식품성분 Database 10.3";

/**
 * 여러 엑셀 배포본을 대응하기 위해
 * 컬럼명 후보를 여러 개 둔다.
 */
const COLUMN_CANDIDATES = {
  foodCode: ["식품코드", "식품 코드", "식품번호", "식품번호코드", "DB10.3색인", "DB10.2색인", "DB10.1색인", "DB10.0색인"],
  foodName: ["식품명", "식품명칭", "식품명(국문)", "식품명_국문"],
  categoryCode: ["식품대분류코드", "식품대분류 코드", "대분류코드", "식품대분류 코드값", "식품군코드"],
  categoryName: ["식품대분류명", "식품대분류 명", "대분류명", "식품군명", "식품군"],
  representativeFoodCode: ["대표식품코드", "대표식품 코드", "대표식품코드값"],
  representativeFoodName: ["대표식품명", "대표식품 명", "대표식품"],
  kcal: ["에너지(kcal)", "에너지 (kcal)", "열량(kcal)", "열량 (kcal)", "칼로리(kcal)", "에너지", "열량", "칼로리"],
  water: ["수분(g)", "수분 (g)", "수분"],
  protein: ["단백질(g)", "단백질 (g)", "단백질"],
  fat: ["지방(g)", "지방 (g)", "지방"],
  carbohydrate: ["탄수화물(g)", "탄수화물 (g)", "탄수화물"],
  fiber: ["식이섬유(g)", "식이섬유 (g)", "총식이섬유", "식이섬유"],
  ash: ["회분(g)", "회분 (g)", "회분"],
  sodium: ["나트륨(mg)", "나트륨 (mg)", "나트륨"],
  servingBase: ["영양성분함량 기준량", "영양성분 함량 기준량", "기준량"],
};

/**
 * 문자열 정리
 */
function cleanText(value) {
  if (value === undefined || value === null) return null;
  const text = String(value).trim();
  if (!text) return null;
  return text;
}

/**
 * 숫자 정리
 * -, Tr, 공란, N/A 등은 null 처리
 */
function cleanNumber(value) {
  if (value === undefined || value === null || value === "") return null;

  const text = String(value).trim();
  if (!text) return null;

  const invalids = ["-", "Tr", "trace", "TRACE", "N/A", "NA", "null"];
  if (invalids.includes(text)) return null;

  // 콤마 제거
  const normalized = text.replace(/,/g, "");

  // 괄호 표기값 "(0.3)"는 수치 0.3으로 파싱
  const paren = normalized.match(/^\(([-+]?\d*\.?\d+)\)$/);
  const numericText = paren ? paren[1] : normalized;

  const n = Number(numericText);
  if (!Number.isNaN(n)) return n;

  return null;
}

/**
 * 코드값은 문자열로 유지
 */
function padCode(value, length) {
  if (value === undefined || value === null || value === "") return null;

  const text = String(value).trim();

  // 이미 숫자형이 아니라면 그대로 두되, 숫자만이면 pad
  if (/^\d+$/.test(text)) {
    return text.padStart(length, "0");
  }

  return text;
}

/**
 * 헤더 정규화
 */
function normalizeHeader(text) {
  return String(text)
    .trim()
    .replace(/\s+/g, "")
    .replace(/[‐-‒–—―]/g, "-");
}

/**
 * 여러 헤더 후보 중 실제 컬럼 찾기
 */
function findColumnIndex(headerRow, candidates) {
  const normalizedHeaderMap = headerRow.map((h) => (h === undefined || h === null ? "" : normalizeHeader(h)));

  for (const candidate of candidates) {
    const normalizedCandidate = normalizeHeader(candidate);
    const idx = normalizedHeaderMap.findIndex((h) => h === normalizedCandidate);
    if (idx !== -1) return idx;
  }

  return -1;
}

/**
 * 첫 번째로 실제 데이터가 많은 시트 선택
 */
function pickSheetName(workbook) {
  if (TARGET_SHEET_NAME && workbook.SheetNames.includes(TARGET_SHEET_NAME)) {
    return TARGET_SHEET_NAME;
  }

  let bestSheet = workbook.SheetNames[0];
  let bestCount = -1;

  for (const sheetName of workbook.SheetNames) {
    const sheet = workbook.Sheets[sheetName];
    const rows = XLSX.utils.sheet_to_json(sheet, {
      header: 1,
      raw: false,
      defval: null,
    });

    if (rows.length > bestCount) {
      bestCount = rows.length;
      bestSheet = sheetName;
    }
  }

  return bestSheet;
}

/**
 * 헤더 행 자동 탐색
 * foodCode / foodName / categoryName 중 2개 이상 잡히는 행을 헤더로 판단
 */
function detectHeaderRow(rows) {
  for (let i = 0; i < Math.min(rows.length, 30); i++) {
    const row = rows[i] || [];

    const score = [
      findColumnIndex(row, COLUMN_CANDIDATES.foodCode) !== -1,
      findColumnIndex(row, COLUMN_CANDIDATES.foodName) !== -1,
      findColumnIndex(row, COLUMN_CANDIDATES.categoryName) !== -1,
      findColumnIndex(row, COLUMN_CANDIDATES.categoryCode) !== -1,
    ].filter(Boolean).length;

    if (score >= 2) return i;
  }

  return 0;
}

/**
 * 대표식품명 추출
 * 1) 대표식품명 컬럼이 있으면 그 값을 우선 사용
 * 2) 없으면 식품명에서 첫 토큰을 대표명으로 사용
 */
function getParentName(foodName, representativeFoodName) {
  if (representativeFoodName) return representativeFoodName;

  if (!foodName) return null;
  const text = String(foodName).trim();
  const byComma = text.split(",").map((s) => s.trim()).filter(Boolean);
  if (byComma.length > 0) return byComma[0];
  const bySpace = text.split(/\s+/).filter(Boolean);
  return bySpace[0] ?? null;
}

/**
 * 세부명 추출
 * 대표식품명이 앞에 붙어 있으면 제거
 * 예:
 * 대표식품명: 보리
 * 식품명: 보리 압맥, 건조
 * => 압맥, 건조
 */
function getChildName(foodName, parentName) {
  if (!foodName) return null;
  if (!parentName) return foodName;

  const rawFoodName = String(foodName).trim();
  const rawParentName = String(parentName).trim();

  if (rawFoodName === rawParentName) {
    return null;
  }

  if (rawFoodName.startsWith(rawParentName)) {
    let rest = rawFoodName.slice(rawParentName.length).trim();

    // 앞 구분자 제거
    rest = rest.replace(/^[,\-–—·•ㆍ/()\[\]{}]+/, "").trim();
    rest = rest.replace(/^\s+/, "").trim();

    return rest || null;
  }

  return rawFoodName;
}

function deriveCategoryCode(categoryMap, categoryName) {
  if (!categoryMap[categoryName]) {
    const next = Object.keys(categoryMap).length + 1;
    categoryMap[categoryName] = String(next).padStart(2, "0");
  }
  return categoryMap[categoryName];
}

/**
 * indexCode 생성
 * category별 parent별 순번이 아니라,
 * 전체 food 순서 기준 4자리 문자열 생성
 */
function makeIndexCode(counter) {
  return String(counter).padStart(4, "0");
}

function main() {
  const workbook = XLSX.readFile(FILE_PATH);
  const sheetName = pickSheetName(workbook);
  const sheet = workbook.Sheets[sheetName];

  const rows = XLSX.utils.sheet_to_json(sheet, {
    header: 1,
    raw: false,
    defval: null,
  });

  const headerRowIndex = detectHeaderRow(rows);
  const headerRow = rows[headerRowIndex];

  const col = {
    foodCode: findColumnIndex(headerRow, COLUMN_CANDIDATES.foodCode),
    foodName: findColumnIndex(headerRow, COLUMN_CANDIDATES.foodName),
    categoryCode: findColumnIndex(headerRow, COLUMN_CANDIDATES.categoryCode),
    categoryName: findColumnIndex(headerRow, COLUMN_CANDIDATES.categoryName),
    representativeFoodCode: findColumnIndex(headerRow, COLUMN_CANDIDATES.representativeFoodCode),
    representativeFoodName: findColumnIndex(headerRow, COLUMN_CANDIDATES.representativeFoodName),
    kcal: findColumnIndex(headerRow, COLUMN_CANDIDATES.kcal),
    water: findColumnIndex(headerRow, COLUMN_CANDIDATES.water),
    protein: findColumnIndex(headerRow, COLUMN_CANDIDATES.protein),
    fat: findColumnIndex(headerRow, COLUMN_CANDIDATES.fat),
    carbohydrate: findColumnIndex(headerRow, COLUMN_CANDIDATES.carbohydrate),
    fiber: findColumnIndex(headerRow, COLUMN_CANDIDATES.fiber),
    ash: findColumnIndex(headerRow, COLUMN_CANDIDATES.ash),
    sodium: findColumnIndex(headerRow, COLUMN_CANDIDATES.sodium),
    servingBase: findColumnIndex(headerRow, COLUMN_CANDIDATES.servingBase),
  };

  const required = ["foodCode", "foodName", "categoryName"];
  const missingRequired = required.filter((key) => col[key] === -1);

  if (missingRequired.length > 0) {
    console.error("헤더 행:", headerRow);
    throw new Error(`필수 컬럼을 찾지 못했습니다: ${missingRequired.join(", ")}`);
  }

  // 참고: 국가표준식품성분표는 원칙적으로 100g 기준
  // 기준량 컬럼이 있으면 100g이 아닌 행을 제외 가능
  // 공개 안내에서도 식품 100g 단위 제시가 원칙이라고 설명한다. :contentReference[oaicite:1]{index=1}
  const categoryMap = {};
  const derivedCategoryCodes = {};
  let runningIndex = 1;

  for (let r = headerRowIndex + 1; r < rows.length; r++) {
    const row = rows[r];
    if (!row) continue;

    const foodCode = padCode(cleanText(row[col.foodCode]), 5);
    const foodName = cleanText(row[col.foodName]);
    const categoryCodeFromSheet = col.categoryCode !== -1 ? padCode(cleanText(row[col.categoryCode]), 2) : null;
    const categoryName = cleanText(row[col.categoryName]);
    const categoryCode = categoryCodeFromSheet || (categoryName ? deriveCategoryCode(derivedCategoryCodes, categoryName) : null);

    if (!foodCode || !foodName || !categoryCode || !categoryName) {
      continue;
    }

    const servingBase = col.servingBase !== -1 ? cleanText(row[col.servingBase]) : null;

    // 기준량 컬럼이 있으면, 100g 계열만 통과
    // 예: "100g", "100 G", "100ml" 등은 그대로 둘 수 있는데
    // 원재료성식품 DB는 대체로 100g 기준이 원칙이라 참고용 필터만 둔다.
    if (servingBase) {
      const normalizedBase = servingBase.toLowerCase().replace(/\s+/g, "");
      const is100Based =
        normalizedBase.includes("100g") ||
        normalizedBase.includes("100ml") ||
        normalizedBase.includes("100㎖") ||
        normalizedBase.includes("100ml당");

      // 기준량이 있는데 100기준이 아닌 경우 제외하고 싶으면 true 유지
      // 현재는 데이터 손실 방지를 위해 제외하지 않음.
      // if (!is100Based) continue;
    }

    const representativeFoodName =
      col.representativeFoodName !== -1 ? cleanText(row[col.representativeFoodName]) : null;

    const parentName = getParentName(foodName, representativeFoodName);
    const childName = getChildName(foodName, parentName);

    if (!parentName) continue;

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
      indexCode: makeIndexCode(runningIndex++),
      name: childName,
      kcal: col.kcal !== -1 ? cleanNumber(row[col.kcal]) : null,
      water: col.water !== -1 ? cleanNumber(row[col.water]) : null,
      protein: col.protein !== -1 ? cleanNumber(row[col.protein]) : null,
      fat: col.fat !== -1 ? cleanNumber(row[col.fat]) : null,
      carbohydrate: col.carbohydrate !== -1 ? cleanNumber(row[col.carbohydrate]) : null,
      fiber: col.fiber !== -1 ? cleanNumber(row[col.fiber]) : null,
      ash: col.ash !== -1 ? cleanNumber(row[col.ash]) : null,
      sodium: col.sodium !== -1 ? cleanNumber(row[col.sodium]) : null,
    });
  }

  const result = Object.values(categoryMap)
    .sort((a, b) => a.categoryCode.localeCompare(b.categoryCode))
    .map((category) => {
      const items = Object.values(category.itemsMap)
        .sort((a, b) => a.name.localeCompare(b.name, "ko"))
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

  fs.writeFileSync(OUTPUT_PATH, JSON.stringify(result, null, 2), "utf-8");

  console.log(`입력 파일: ${path.basename(FILE_PATH)}`);
  console.log(`사용 시트: ${sheetName}`);
  console.log(`헤더 행 index: ${headerRowIndex}`);
  console.log(`출력 파일: ${OUTPUT_PATH}`);
  console.log(`카테고리 수: ${result.length}`);
}
main();
