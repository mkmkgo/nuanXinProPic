const test = require('node:test')
const assert = require('node:assert/strict')
const fs = require('fs')
const os = require('os')
const path = require('path')

const {
  reconcileMetadataImagePath,
} = require('../scripts/process-metadata.js')

test('reconcileMetadataImagePath rewrites stale metadata path to actual file location', () => {
  const tempRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'process-metadata-test-'))
  const actualDir = path.join(tempRoot, 'wallpaper', 'desktop', '通用')
  fs.mkdirSync(actualDir, { recursive: true })
  fs.writeFileSync(path.join(actualDir, '20260406200013.jpeg'), 'fake')

  const originalCwd = process.cwd()
  process.chdir(tempRoot)

  try {
    const result = reconcileMetadataImagePath(
      'wallpaper/desktop/萌宠/猫咪/20260406200013.jpeg',
      {
        category: '萌宠',
        subcategory: '猫咪',
        filename: '20260406200013.jpeg',
      }
    )

    assert.equal(result.changed, true)
    assert.equal(result.relativePath, 'wallpaper/desktop/通用/20260406200013.jpeg')
    assert.equal(result.imageData.category, '通用')
    assert.equal(result.imageData.subcategory, '')
    assert.equal(result.imageData.filename, '20260406200013.jpeg')
  } finally {
    process.chdir(originalCwd)
    fs.rmSync(tempRoot, { recursive: true, force: true })
  }
})
