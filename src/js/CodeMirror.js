module.exports = () => {
  return new Promise((resolve, reject) => {
    require.ensure([
      'codemirror/lib/codemirror',
      'codemirror/lib/codemirror.css',
      'codemirror/mode/elm/elm',
      'codemirror/addon/lint/lint',
      'codemirror/addon/lint/lint.css',
      'codemirror/theme/yeti.css',
    ], function () {
      const CodeMirror = require('codemirror/lib/codemirror')
      require('codemirror/lib/codemirror.css')
      require('codemirror/mode/elm/elm')
      require('codemirror/addon/lint/lint')
      require('codemirror/addon/lint/lint.css')
      require('codemirror/theme/yeti.css')
      window.CodeMirror = CodeMirror
      resolve()
    })
  })
}
