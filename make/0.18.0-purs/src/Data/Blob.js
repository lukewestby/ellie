exports._createObjectUrl = function _createObjectUrl(blob) {
  return function runEff() {
    return URL.createObjectURL(blob)
  }
}

exports._revokeObjectUrl = function _revokeObjectUrl(unit, url) {
  return function runEff() {
    URL.revokeObjectURL(url)
    return unit
  }
}