const XLSX = require("xlsx");

const FILE_PATH = "./식품성분표(10개정판)2.xlsx";
const workbook = XLSX.readFile(FILE_PATH);
const TARGET_SHEET_NAME = "국가표준식품성분 Database 10.3";
const sheet = workbook.Sheets[TARGET_SHEET_NAME];

const rows = XLSX.utils.sheet_to_json(sheet, {
  header: 1,
  raw: false,
  defval: null,
});

for (let i = 0; i < 25; i++) {
  console.log(`\n===== row ${i} =====`);
  console.log(rows[i]);
}
