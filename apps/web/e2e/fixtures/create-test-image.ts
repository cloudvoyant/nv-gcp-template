// Creates a minimal 10x10 white PNG
import * as fs from "fs";
import * as path from "path";

// Minimal valid 10x10 white PNG (base64)
const TINY_PNG_B64 =
  "iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFElEQVR42mNk+A9QTwMJAAD6AgHtmUj3AAAAAElFTkSuQmCC";

const outputPath = path.join(__dirname, "test-image.png");
fs.writeFileSync(outputPath, Buffer.from(TINY_PNG_B64, "base64"));
console.log("Created test-image.png");
